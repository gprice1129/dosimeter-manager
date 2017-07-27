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
    
    var areaMonitor: NSManagedObject?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func setupLabels(labelProperties: [String: UILabel]) {
        guard let areaMonitor = self.areaMonitor else {
            return
        }
        for key in labelProperties.keys {
            guard let value = areaMonitor.value(forKey: key) as? String else {
                // TODO: Report error
                return
            }
            labelProperties[key]!.text = value
        }
    }
}

