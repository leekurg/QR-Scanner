//
//  ViewController.swift
//  QR-scanner
//
//  Created by Ильяяя on 31.05.2022.
//

import UIKit
import SnapKit
import AVFoundation

let innerDateFormat = "dd.MM.yyyy"

class ViewController: UIViewController {

    private var buttonCapture: UIButton!
    private var video: AVCaptureVideoPreviewLayer?
    private  var session: AVCaptureSession!
    private var network = NetworkService()
    
    private var isSessionSuspended = false  //disable metadata while awaiting HTTP result
    private var _isSessionActive = false
    private var isSessionActive:Bool {
        set {
            _isSessionActive = newValue
            if _isSessionActive {
                isSessionSuspended = false
                buttonCapture.setTitle("🟥", for: .normal)
                animateButtonPressed(button: buttonCapture, toColor: .white)
            }
            else {
                buttonCapture.setTitle("⚪️", for: .normal)
                animateButtonPressed(button: buttonCapture, toColor: UIColor(red: 237/255, green: 65/255, blue: 21/255, alpha: 1))
            }
        }
        get {
            return _isSessionActive
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(red: 223/255, green: 245/255, blue:  229/255, alpha: 1)
        
        setupCapture()
        setupControlPanel()
        startCapture()
    }

    
    //MARK: - Setup UI
    private func setupCapture() {
        session = AVCaptureSession()
        let device = AVCaptureDevice.default(for: .video)
        
        guard let device = device else { return }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            session.addInput(input)
        } catch {
            fatalError(error.localizedDescription)
        }
        
        let output = AVCaptureMetadataOutput()
        session.addOutput(output)
        
        //scan for qr
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        output.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
        
        video = AVCaptureVideoPreviewLayer(session: session)
        guard let video = video else { return }
        video.frame = view.bounds
        video.videoGravity = .resizeAspectFill
    }
    
    
    
    private func setupControlPanel() {
        let view = PanelView()
        view.applyBlurEffect()
        
        buttonCapture = {
            let button = UIButton()
            
            button.layer.cornerRadius = 50
            button.layer.shadowOffset = CGSize(width: 0, height: 0)
            button.layer.shadowOpacity = 0.3
            button.layer.shadowRadius = 7.0
            button.backgroundColor = UIColor(red: 237/255, green: 65/255, blue: 21/255, alpha: 1)
            button.setTitle("⚪️", for: .normal)
            
            return button
        }()


        self.view.addSubview(view)
        self.view.addSubview(buttonCapture)
        
        let screenH = UIScreen.main.bounds.size.height
        view.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo( screenH / 4)
        }
        
        buttonCapture.snp.makeConstraints { make in
            make.center.equalTo(view)
            make.width.height.equalTo(100)
        }
        
        buttonCapture.addTarget(self, action: #selector(buttonCaptureDidTouched), for: .touchUpInside)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {    get {       return .portrait    } }
    
    //MARK: - Actions
    
    private func startCapture() {
        guard let video = video else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                let alert = UIAlertController(title: "", message: "❗️Video device not found", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true)
            }
            
            return
        }
        view.layer.insertSublayer(video, below: view.layer.sublayers![0])
        session.startRunning()
    }
    
    private func stopCapture() {
        self.view.layer.sublayers?.removeFirst()
        self.session.stopRunning()
    }
    
    private func alertInfo(title: String, message: String?) {
        let msg = message ?? "No data"
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
    
    @objc func buttonCaptureDidTouched() {
        isSessionActive = !isSessionActive
    }
    
    //MARK: - Animation
    private func animateButtonPressed( button: UIButton, toColor color: UIColor? = nil) {

            button.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)

            UIView.animate(withDuration: 1.5,
                           delay: 0,
                           usingSpringWithDamping: CGFloat(10.0),
                           initialSpringVelocity: CGFloat(4.0),
                           options: UIView.AnimationOptions.allowUserInteraction,
                           animations: {
                                button.transform = CGAffineTransform.identity
                                button.backgroundColor = color
                            },
                           completion: { Void in()  }
            )
    }
    
    //MARK: - Network
    private func queryDate(date: Date)
    {
        network.fetchDate(date: date) {[weak self] (isHoliday, error) in
            if let error = error{
                self?.handleError(error: error)
            }
            else{
                self?.handleSuccess(date: date, isHoliday: isHoliday!)  //!!!
            }
        }
    }
    
    private func handleError( error: String ) {
        alertInfo(title: "Error", message: "❗️" + error)
        buttonCapture.backgroundColor = UIColor(red: 150/255, green: 0, blue: 0, alpha: 1)
        isSessionActive = false
    }
    
    private func handleSuccess(date: Date, isHoliday: Int ) {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = innerDateFormat
        
        let msg = dateFormatter.string(from: date) + " - is " + (isHoliday == 1 ? " holiday" : " work day")
        
        alertInfo(title: "Date", message: msg)
        buttonCapture.backgroundColor = .green
        isSessionActive = false
    }
    
    private func parseForDate( content: String? ) -> Date? {
        guard let content = content else { return nil }
        
        let dateFormatterGet = DateFormatter()

        dateFormatterGet.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        var date = dateFormatterGet.date(from: content)
        if date == nil {
            dateFormatterGet.dateFormat = "yyyy-MM-dd"
            date = dateFormatterGet.date(from: content)
        }
        if date == nil {
            dateFormatterGet.dateFormat = innerDateFormat
            date = dateFormatterGet.date(from: content)
        }

        return date
    }
    
}

//MARK: - QR decoding
extension ViewController: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard isSessionActive && !isSessionSuspended else  { return }
        
        guard metadataObjects.count > 0 else { return }
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject else { return }
        guard object.type == AVMetadataObject.ObjectType.qr else { return }
        
        let date = parseForDate(content: object.stringValue)
        if let date = date {
            isSessionSuspended = true
            queryDate(date: date)
        }
        else {
            alertInfo(title: "Message", message: object.stringValue)
            buttonCapture.backgroundColor = .green
            isSessionActive = false
        }
    }
}
