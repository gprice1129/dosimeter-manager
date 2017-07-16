//
//  ViewController.swift
//  dosimeter-manager
//
//  Created by Admin on 7/7/17.
//  Copyright © 2017 Guthrie Price. All rights reserved.
//

import UIKit

class StartUpVC: UIViewController, URLSessionDownloadDelegate, UIDocumentInteractionControllerDelegate {

    var downloadTask: URLSessionDownloadTask!
    var backgroundSession: URLSession!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func downloadFile(_ sender: Any) {
        let backgroundSessionConfiguration = URLSessionConfiguration.background(withIdentifier: "backgroundSession")
        backgroundSession = URLSession(configuration: backgroundSessionConfiguration, delegate: self, delegateQueue: OperationQueue.main)

        let downloadURL = URL(string: "http://slac.stanford.edu/~xiaosj/scanner/scan_test.csv")!
        downloadTask = backgroundSession.downloadTask(with: downloadURL)
        downloadTask.resume()
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        let path = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let documentDirectoryPath:String = path[0]
        let fileManager = FileManager()
        let destinationURLForFile = URL(fileURLWithPath: documentDirectoryPath.appending("/history.csv"))
        
        if fileManager.fileExists(atPath: destinationURLForFile.path) {
            showFileWithPath(path: destinationURLForFile.path)
        }
        else {
            do {
                try fileManager.moveItem(at: location, to: destinationURLForFile)
                showFileWithPath(path: destinationURLForFile.path)
            } catch {
                print("An error occurred while moving file to destination url")
            }
        }
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?){
        downloadTask = nil
        if (error != nil) {
            print(error!.localizedDescription)
        }else{
            print("The task finished transferring data successfully")
        }
    }
    
    func showFileWithPath(path: String){
        let isFileFound:Bool? = FileManager.default.fileExists(atPath: path)
        if isFileFound == true{
            let viewer = UIDocumentInteractionController(url: URL(fileURLWithPath: path))
            viewer.delegate = self
            viewer.presentPreview(animated: true)
        }
    }

    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController
    {
        return self
    }
}

