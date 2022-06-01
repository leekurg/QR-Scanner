//
//  ViewController.swift
//  QR-scanner
//
//  Created by Ильяяя on 31.05.2022.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    var video: AVCaptureVideoPreviewLayer?
    var session: AVCaptureSession!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(red: 223/255, green: 245/255, blue:  229/255, alpha: 1)
        
        setupCapture()
        startCapture()
    }

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
        video.frame = view.layer.bounds
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

}

extension ViewController: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard metadataObjects.count > 0 else { return }
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject else { return }
        guard object.type == AVMetadataObject.ObjectType.qr else { return }
        
        let alert = UIAlertController(title: "QR-code recognized", message: object.stringValue, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
}
