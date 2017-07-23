//
//  ReaderVC.swift
//  dosimeter-manager
//
//  Created by Admin on 7/10/17.
//  Copyright © 2017 Guthrie Price. All rights reserved.
//

import UIKit
import AVFoundation
import CoreData

class BarcodeReaderVC: QueryVC, AVCaptureMetadataOutputObjectsDelegate {

    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var whatsLeftButton: UIButton!
    var session: Session?
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var captureSessionPaused: Bool = false
    var currentMode: ReaderMode = .verify
    var scannedBarcode: String?
    
    enum ReaderMode {
        case verify
    }
    
    struct Segues {
        static let readerToDisplay: String = "ReaderToDisplay"
        static let readerToMonitor: String = "ReaderToMonitor"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            if (captureSession == nil) {
                print("Setting up capture session")
                try setupCaptureSession()
                videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
                videoPreviewLayer?.frame = view.layer.bounds
                view.layer.addSublayer(videoPreviewLayer!)
                view.bringSubview(toFront: messageLabel)
                view.bringSubview(toFront: whatsLeftButton)
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
        self.captureSessionPaused = false
        captureSession?.startRunning()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession?.stopRunning()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifer = segue.identifier else {
            return
        }
        switch (identifer) {
        case Segues.readerToDisplay:
            guard let destinationController = segue.destination as? SessionDisplayVC else {
                return
            }
            destinationController.session = self.session
        case Segues.readerToMonitor:
            guard let destinationController = segue.destination as? MonitorDisplayVC,
                 let areaMonitor = sender as? NSManagedObject else {
                return
            }
            destinationController.areaMonitor = areaMonitor
        default:
            return
        }
    }
    
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
            self.scannedBarcode = metadataObj.stringValue
            if (self.currentMode == .verify) {
                verifyBarcode()
            }
        }
    }
    
    func verifyBarcode() {
        do {
            let areaMonitors: [NSManagedObject] = try query(withKey: DataProperty.oldCode, withValue: self.scannedBarcode)
            if(areaMonitors.count > 1) {
                print("Conflict: Two identical barcodes found in the system")
                return
            }
            if(areaMonitors.count < 1) {
                print("Error: No areamonitor found with the scanned barcode")
                return
            }
            performSegue(withIdentifier: Segues.readerToMonitor, sender: areaMonitors[0])
        } catch {
            print("Error: Query to database was unsuccessful")
            return
        }
    }
    
    @IBAction func didPressWhatsLeftButton(_ sender: Any) {
        performSegue(withIdentifier: Segues.readerToDisplay, sender: self)
    }
    

}
