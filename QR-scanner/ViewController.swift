//
//  ViewController.swift
//  QR-scanner
//
//  Created by Ильяяя on 31.05.2022.
//

import UIKit
import AVFoundation

let innerDateFormat = "dd.MM.yyyy"

class ViewController: UIViewController {

    var video: AVCaptureVideoPreviewLayer?
    var session: AVCaptureSession!
    var network = NetworkService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(red: 223/255, green: 245/255, blue:  229/255, alpha: 1)
        
        setupCapture()
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
//        video.frame = view.layer.bounds
        video.frame = view.bounds
        video.videoGravity = .resizeAspectFill
    }
    
    private func startCapture() {
        guard let video = video else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                let alert = UIAlertController(title: "", message: "❗️Video device not found", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true)
            }
            
            return
        }
        view.layer.addSublayer(video)
        session.startRunning()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {    get {       return .portrait    } }
    
    //MARK: - Actions
    
    private func alertInfo(title: String, message: String?) {
        let msg = message ?? "No data"
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true)
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
    }
    
    private func handleSuccess(date: Date, isHoliday: Int ) {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = innerDateFormat
        
        let msg = dateFormatter.string(from: date) + " - is " + (isHoliday == 1 ? " holiday" : " work day")
        
        alertInfo(title: "Date", message: msg)
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
        guard metadataObjects.count > 0 else { return }
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject else { return }
        guard object.type == AVMetadataObject.ObjectType.qr else { return }
        
        var date = parseForDate(content: object.stringValue)
        if let date = date {
            queryDate(date: date)
        }
        else {
            alertInfo(title: "Message", message: object.stringValue)
        }
    }
}
