//
//  DataVC.swift
//  dosimeter-manager
//
//  Created by Admin on 7/19/17.
//  Copyright © 2017 Guthrie Price. All rights reserved.
//

import UIKit
import CoreData

class QueryVC: UIViewController {
    
    struct EntityNames {
        static let areaMonitor: String = "AreaMonitor"
    }
    
    struct DataProperty {
        static let facility = "facility"
        static let facilityNumber = "facilityNumber"
        static let location = "location"
        static let newCode = "newCode"
        static let oldCode = "oldCode"
        static let pickupDate = "pickupDate"
        static let placementDate = "placementDate"
    }
    
    enum QueryError: Error {
        case noAppDelegate
    }
    
    func query(withKey key: String?, withValue value: String?) throws -> [NSManagedObject] {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            throw QueryError.noAppDelegate
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: EntityNames.areaMonitor)
        
        if let key = key, let value = value {
            fetchRequest.predicate = NSPredicate(format: "%K like %@", key, value)
        }
        return try managedContext.fetch(fetchRequest)
    }
    
    func query(withKVPs kvps: [(String, String)]? = nil) throws -> [NSManagedObject] {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            throw QueryError.noAppDelegate
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: EntityNames.areaMonitor)

        if let kvps = kvps {
            if (kvps.count > 0) {
                var predicates: [NSPredicate] = []
                for (key, value) in kvps {
                    predicates.append(NSPredicate(format: "%K like %@", key, value))
                }
                if (predicates.count > 1) {
                    fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
                } else {
                    fetchRequest.predicate = predicates[0]
                }
            }
        }
        return try managedContext.fetch(fetchRequest)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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

}
