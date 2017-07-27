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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLabels(labelProperties: [DataProperty.facility: facility, DataProperty.location: location,
                                    DataProperty.status: status])
        guard let areaMonitor = self.areaMonitor else {
            return
        }
        var barcode = areaMonitor.value(forKey: DataProperty.newCode) as! String
        if (barcode == "") {
            barcode = areaMonitor.value(forKey: DataProperty.oldCode) as! String
        }
        self.barcode.text = barcode
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func didPressGoBack(_ sender: Any) {
    }

}
