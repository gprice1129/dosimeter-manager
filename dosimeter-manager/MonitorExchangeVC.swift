//
//  MonitorExchangeVC.swift
//  dosimeter-manager
//
//  Created by Admin on 7/26/17.
//  Copyright © 2017 Guthrie Price. All rights reserved.
//

import UIKit

class MonitorExchangeVC: MonitorDisplayVC {
    @IBOutlet weak var facility: UILabel!
    @IBOutlet weak var location: UILabel!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var newCode: UILabel!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var tag: UILabel!
    var scannedBarcode: String = ""
    var currentDate: Date? = nil
    var currentStatus: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLabels(labelProperties: [DataProperty.facility: facility, DataProperty.location: location, DataProperty.tag: tag])
        self.currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.dateFormat = "dd-MMM-yy"
        date.text = dateFormatter.string(from: self.currentDate!)
        newCode.text = self.scannedBarcode
        self.status.text = self.currentStatus
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
