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
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var captureSessionPaused: Bool = false
    var currentMode: ReaderMode = .verify
    
    enum ReaderMode {
        case verify
    }
    
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
    
    func pauseCaptureSession() {
        self.captureSessionPaused = true
    }
    
    func unpauseCaptureSession() {
        self.captureSessionPaused = false
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
            self.pauseCaptureSession()
            if (self.currentMode == .verify) {
                verifyBarcode(barcode: metadataObj.stringValue)
            }
        }
    }
    
    func verifyBarcode(barcode: String?) {
        // This should eventually do a database lookup that determines if the
        // barcode is already in the database.
        let alert = UIAlertController(title: "Barcode Found", message: "\(barcode!) was found in the database.",
            preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Confirm", style: UIAlertActionStyle.default, handler: confirmScan))
        alert.addAction(UIAlertAction(title: "Redo Scan", style: UIAlertActionStyle.default, handler: redoScan))
        self.present(alert, animated: true, completion: nil)
    }
    
    func confirmScan(_: UIAlertAction) -> Void {
        self.messageLabel.text = "Barcode scanned successfully"
        self.unpauseCaptureSession()
    }
    
    func redoScan(_: UIAlertAction) -> Void {
        self.messageLabel.text = "Please redo the barcode scan"
        self.unpauseCaptureSession()
    }
}
