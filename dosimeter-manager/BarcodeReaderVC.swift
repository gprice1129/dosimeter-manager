//
//  ReaderVC.swift
//  dosimeter-manager
//
//  Created by Admin on 7/10/17.
//  Copyright © 2017 Guthrie Price. All rights reserved.
//

import UIKit
import AVFoundation

class BarcodeReaderVC: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    @IBOutlet weak var messageLabel: UILabel!
    var captureSession:AVCaptureSession?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Hello from viewDidLoad")
        do {
            if (captureSession == nil) {
                print("Setting up capture session")
                try setupCaptureSession()
                videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
                videoPreviewLayer?.frame = view.layer.bounds
                view.layer.addSublayer(videoPreviewLayer!)
                view.bringSubview(toFront: messageLabel)
            }
        }

        // For now just handle the error simply for debugging purposes
        // TODO: Alert user how to fix the problem (needs research)
        catch {
            print(error)
            return
        }
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("Hello from viewWillAppear")
        captureSession?.startRunning()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("Hello from viewWillDisappear")
        captureSession?.stopRunning()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func setupCaptureSession() throws {
        // Attempts to setup the capture session and settings
        
        let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        // TODO: The settings configuration should be more robust and work for
        //       multiple devices. Right now it has only been tested on the
        //       iPhone 6s Plus (needs research)
        try captureDevice?.lockForConfiguration()
        captureDevice?.focusMode = .continuousAutoFocus
        captureDevice?.videoZoomFactor = (captureDevice?.activeFormat.videoMaxZoomFactor)!
        captureDevice?.unlockForConfiguration()
        
        captureSession = AVCaptureSession()
        let input = try AVCaptureDeviceInput(device: captureDevice)
        captureSession?.addInput(input)
        let output = AVCaptureMetadataOutput()
        captureSession?.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        output.metadataObjectTypes = [AVMetadataObjectTypeCode128Code, AVMetadataObjectTypeDataMatrixCode]
        
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        // Handles what should be done when a barcode is read
        
        if (metadataObjects == nil || metadataObjects.count == 0) {
            messageLabel.text = "No barcode is detected"
            return
        }
        
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        if (metadataObj.type == AVMetadataObjectTypeDataMatrixCode ||
            metadataObj.type == AVMetadataObjectTypeCode128Code) {
            messageLabel.text = metadataObj.stringValue
        }
        
    }
}
