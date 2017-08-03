//
//  QueryModeVC.swift
//  dosimeter-manager
//
//  Created by Admin on 8/3/17.
//  Copyright © 2017 Guthrie Price. All rights reserved.
//

import UIKit

class QueryModeVC: QueryVC {
    
    var currentMode: Mode = .normal
    var newEntity: [String: String] = [:]
    
    enum Mode {
        case normal
        case recovery
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
