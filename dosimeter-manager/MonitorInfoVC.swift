//
//  MonitorInfoVC.swift
//  dosimeter-manager
//
//  Created by Admin on 7/25/17.
//  Copyright © 2017 Guthrie Price. All rights reserved.
//

import UIKit

class MonitorInfoVC: MonitorDisplayVC {
    @IBOutlet weak var facility: UILabel!
    @IBOutlet weak var location: UILabel!
    @IBOutlet weak var barcode: UILabel!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var tag: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLabels(labelProperties: [DataProperty.facility: self.facility, DataProperty.self.location: location,
                                      DataProperty.status: self.status, DataProperty.tag: self.tag])
        guard let areaMonitor = self.areaMonitor else {
            return
        }
        var currentBarcode = areaMonitor.value(forKey: DataProperty.newCode) as? String
        if (currentBarcode == nil) {
            // TODO: Handle data corruptin error
        currentBarcode = areaMonitor.value(forKey: DataProperty.oldCode) as? String
        }
        if (currentBarcode != nil) {
            self.barcode.text = currentBarcode!
        }
        self.location.numberOfLines = 0
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func didPressGoBack(_ sender: Any) {
    }

}
