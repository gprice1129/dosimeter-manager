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
    @IBOutlet weak var flashlightButton: UIButton!
    var session: Session?
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var captureSessionPaused: Bool = false
    var currentMode: ReaderMode = .verify
    var scannedBarcode: String?
    var areaMonitor: NSManagedObject?
    var currentStatus: String = ""
    var flashlightIsOn: Bool = false
    
    enum ReaderMode {
        case verify
        case replace
    }
    
    struct Messages {
        static let verifyMessage: String = "Please scan old barcode"
        static let replaceMessage: String = "Please scan new barcode"
    }
    
    struct Segues {
        static let readerToList: String = "ReaderToList"
        static let readerToVerify: String = "ReaderToVerify"
        static let readerToExchange: String = "ReaderToExchange"
        static let readerToRecovery: String = "ReaderToRecovery"
    }
    
    struct Colors {
        static let on = UIColor(red: CGFloat(1.0), green: CGFloat(126.0/255), blue: CGFloat(121.0/255), alpha: CGFloat(1.0))
        static let off = UIColor(red: CGFloat(0.0), green: CGFloat(122.0/255), blue: CGFloat(1.0), alpha: CGFloat(1.0))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            if (captureSession == nil) {
                print("Setting up capture session")
                NotificationCenter.default.addObserver(self,
                                               selector: #selector(BarcodeReaderVC.formatNotification),
                                               name: NSNotification.Name.AVCaptureInputPortFormatDescriptionDidChange,
                                               object: nil)
                try setupCaptureSession()
                videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
                videoPreviewLayer?.frame = view.layer.bounds
                view.layer.addSublayer(videoPreviewLayer!)
                view.bringSubview(toFront: messageLabel)
                view.bringSubview(toFront: whatsLeftButton)
                view.bringSubview(toFront: flashlightButton)
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
        switch(self.currentMode) {
        case .verify:
            self.messageLabel.text = Messages.verifyMessage
        case .replace:
            self.messageLabel.text = Messages.replaceMessage
        }
        captureSession?.startRunning()
        self.toggleTorch(on: self.flashlightIsOn)
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
        case Segues.readerToList:
            guard let destinationController = segue.destination as? SessionDisplayVC else {
                return
            }
            destinationController.session = self.session
        case Segues.readerToVerify:
            guard let destinationController = segue.destination as? MonitorVerifyVC,
                 let areaMonitor = sender as? NSManagedObject else {
                return
            }
            if (self.session == nil) {
                guard let facility = areaMonitor.value(forKey: DataProperty.facility) as? String,
                     let facilityNumber = areaMonitor.value(forKey: DataProperty.facilityNumber) as? String else {
                        return
                }
                self.session = Session(forFacility: facility, withNumber: facilityNumber)
            }
            guard let status = areaMonitor.value(forKey: DataProperty.status) as? String else {
                return
            }
            self.currentStatus = status
            destinationController.areaMonitor = areaMonitor
        case Segues.readerToExchange:
            guard let destinationController = segue.destination as? MonitorExchangeVC else {
                return
            }
            destinationController.currentStatus = self.currentStatus
            destinationController.scannedBarcode = self.scannedBarcode!
            destinationController.areaMonitor = self.areaMonitor!
        case Segues.readerToRecovery:
            guard let destinationController = segue.destination as? SessionController else {
                return
            }
            destinationController.newEntity[DataProperty.oldCode] = self.scannedBarcode!
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
    
    func formatNotification() {
        guard let output = captureSession?.outputs[0] as? AVCaptureMetadataOutput else {
            print("Output capture session is incorrect")
            return
        }
        guard let videoPreviewLayer = self.videoPreviewLayer else {
            print("Video preview layer is not accessible")
            return
        }
        let scanRect = CGRect(x: self.view.frame.width / CGFloat(6),
                            y: self.view.frame.height / CGFloat(3),
                            width: self.view.frame.width / CGFloat(1.5),
                            height: 80)
        output.rectOfInterest = videoPreviewLayer.metadataOutputRectOfInterest(for: scanRect)
        let scanView = UIView()
        scanView.layer.borderColor = UIColor.green.cgColor
        scanView.layer.borderWidth = 2
        scanView.frame = scanRect
        view.addSubview(scanView)
        view.bringSubview(toFront: scanView)
    }
    
    func pauseCaptureSession() {
        self.captureSessionPaused = true
    }
    
    func unpauseCaptureSession() {
        self.captureSessionPaused = false
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!,
                      didOutputMetadataObjects metadataObjects: [Any]!,
                      from connection: AVCaptureConnection!) {
        // Handles what should be done when a barcode is read
        if (self.captureSessionPaused) {
            return
        }
        
        if (metadataObjects == nil || metadataObjects.count == 0) {
            messageLabel.text = "No barcode is detected"
            return
        }
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        if (metadataObj.type == AVMetadataObjectTypeDataMatrixCode ||
            metadataObj.type == AVMetadataObjectTypeCode128Code) {
            self.pauseCaptureSession()
            if (self.scannedBarcode == metadataObj.stringValue) {
                return
            }
            self.scannedBarcode = metadataObj.stringValue
            switch (self.currentMode) {
            case .verify:
                verifyBarcode()
            case .replace:
                replaceBarcode()
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
                // No area monitor found with this barcode
                generateWarning(message: "The scanned barcode: \(self.scannedBarcode!) was not found in the system, what do you want to do?",
                    continueMsg: "Pick Location", cancelMsg: "Rescan",
                    continueAction: {action in
                        self.performSegue(withIdentifier: Segues.readerToRecovery, sender: self)
                    },
                    cancelAction: {action in
                        self.scannedBarcode = ""
                        self.unpauseCaptureSession()
                    })
                return
            }
            let areaMonitor = areaMonitors[0]
            guard let status = areaMonitor.value(forKey: DataProperty.status) as? String else {
                return
            }
            if (status != Status.unrecovered) {
                generateWarning(message: "This area monitor has already been marked as complete, are you sure you want to continue?",
                             continueMsg: "Continue", cancelMsg: "Go Back",
                             continueAction: {action in
                                 self.performSegue(withIdentifier: Segues.readerToVerify, sender: areaMonitors[0])
                             },
                             cancelAction: {action in
                                 self.scannedBarcode = ""
                                 self.unpauseCaptureSession()
                             })
            return
            }
            performSegue(withIdentifier: Segues.readerToVerify, sender: areaMonitors[0])
        } catch {
            print("Error: Query to database was unsuccessful")
            return
        }
    }
    
    func generateWarning(message: String, continueMsg: String, cancelMsg: String,
                         continueAction: ((UIAlertAction) -> Void)?, cancelAction: ((UIAlertAction) -> Void)?) {
        let alertController = UIAlertController(title: "Warning", message: message, preferredStyle: .alert)
        let continueAction = UIAlertAction(title: continueMsg, style: .default, handler: continueAction)
        let cancelAction = UIAlertAction(title: cancelMsg, style: .cancel, handler: cancelAction)
        alertController.addAction(continueAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func replaceBarcode() {
        guard let areaMonitor = self.areaMonitor else {
            print("Error: No areamonitor to replace")
            return
        }
        guard let _ = areaMonitor.managedObjectContext else {
            print("Error: No managed context for areamonitor")
            return
        }
        performSegue(withIdentifier: Segues.readerToExchange, sender: self)
    }
    
    func setReplaceMode(sender: UIStoryboardSegue) {
        let sourceController = sender.source as! MonitorVerifyVC
        self.areaMonitor = sourceController.areaMonitor
        self.currentMode = .replace
        self.messageLabel.text = Messages.replaceMessage
    }
    
    func toggleTorch(on: Bool) {
        guard let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) else {
            return
        }
        do {
            try device.lockForConfiguration()
            if (on) {
                device.torchMode = .on
            } else {
                device.torchMode = .off
            }
            device.unlockForConfiguration()
        } catch {
            print("Torch is currently being used by another application")
            return
        }
    }
    
    @IBAction func didPressWhatsLeftButton(_ sender: Any) {
        performSegue(withIdentifier: Segues.readerToList, sender: self)
    }
    
    @IBAction func didPressFlashlightButton(_ sender: Any) {
        if (self.flashlightIsOn) {
            self.flashlightButton.backgroundColor = Colors.off
        } else {
            self.flashlightButton.backgroundColor = Colors.on
        }
        self.flashlightIsOn = !self.flashlightIsOn
        self.toggleTorch(on: self.flashlightIsOn)
    }
    
    @IBAction func didPressConfirmUnwind(sender: UIStoryboardSegue) {
        setReplaceMode(sender: sender)
        self.currentStatus = Status.recovered
        self.unpauseCaptureSession()
    }
    
    @IBAction func didPressFlagUnwind(sender: UIStoryboardSegue) {
        setReplaceMode(sender: sender)
        self.currentStatus = Status.flagged
        self.unpauseCaptureSession()
    }
    
    @IBAction func didPressCompleteUnwind(sender: UIStoryboardSegue) {
        guard let sourceController = sender.source as? MonitorExchangeVC else {
            print("Couldn't unwind from exchange")
            return
        }
        do {
            let areaMonitor = self.areaMonitor!
            let scannedBarcode = sourceController.scannedBarcode
            let currentDate = sourceController.currentDate!
            areaMonitor.setValue(scannedBarcode, forKey: DataProperty.newCode)
            areaMonitor.setValue(currentDate, forKey: DataProperty.pickupDate)
            areaMonitor.setValue(self.currentStatus, forKey: DataProperty.status)
            try areaMonitor.managedObjectContext?.save()
            self.currentMode = .verify
            self.messageLabel.text = Messages.verifyMessage
            self.unpauseCaptureSession()
        } catch {
            print("Couldn't save areamonitor exchange")
            return
        }
    }
    
    @IBAction func didPressCancelUnwind(sender: UIStoryboardSegue) {
        return
    }
}
