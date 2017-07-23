//
//  MonitorDisplayVC.swift
//  dosimeter-manager
//
//  Created by Admin on 7/21/17.
//  Copyright © 2017 Guthrie Price. All rights reserved.
//

import UIKit
import CoreData

class MonitorDisplayVC: QueryVC {
    @IBOutlet weak var facility: UILabel!
    @IBOutlet weak var location: UILabel!
    @IBOutlet weak var barcode: UILabel!
    
    var areaMonitor: NSManagedObject?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let areaMonitor = self.areaMonitor else {
            return
        }
        guard var facility = areaMonitor.value(forKey: DataProperty.facility) as? String,
             let facilityNumber = areaMonitor.value(forKey: DataProperty.facilityNumber) as? String,
             let description = areaMonitor.value(forKey: DataProperty.location) as? String,
             let barcode = areaMonitor.value(forKey: DataProperty.oldCode) as? String else {
                print("Malformed query result")
                return
        }
        if (facilityNumber != "NONE") {
            facility = "\(facility) \(facilityNumber)"
        }
        self.facility.text = facility
        self.location.text = description
        self.location.numberOfLines = 0
        self.barcode.text = barcode
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

