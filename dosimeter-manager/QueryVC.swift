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
    
    func query(withKVPs kvps: [(String, String)]? = nil, fetchRetired: Bool = false) throws -> [NSManagedObject] {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            throw QueryError.noAppDelegate
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: EntityNames.areaMonitor)
        let notRetiredPredicate = NSPredicate(format: "NOT (%K like %@)", DataProperty.status, Status.retired)
        guard let kvps = kvps else {
            if (!fetchRetired) {
                fetchRequest.predicate = notRetiredPredicate
            }
            return try managedContext.fetch(fetchRequest)
        }
        if (kvps.count > 0) {
            var predicates: [NSPredicate] = []
            for (key, value) in kvps {
                predicates.append(NSPredicate(format: "%K like %@", key, value))
            }
            if (!fetchRetired) {
                predicates.append(notRetiredPredicate)
            }
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        } else if (!fetchRetired) {
            fetchRequest.predicate = notRetiredPredicate
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

}
