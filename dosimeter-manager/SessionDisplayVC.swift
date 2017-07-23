//
//  SessionDisplayVC.swift
//  dosimeter-manager
//
//  Created by Admin on 7/20/17.
//  Copyright © 2017 Guthrie Price. All rights reserved.
//

import UIKit
import CoreData

class SessionDisplayVC: QueryVC {
    
    @IBOutlet weak var descriptionDisplay: UITableView!
    var session: Session?
    var areaMonitors: [NSManagedObject] = []
    
    struct Segues {
        static let sessionToMonitor = "SessionToMonitor"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        descriptionDisplay.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        guard let session = self.session else {
            self.title = "No session data found"
            return
        }
        guard let facility = session.facility, let facilityNumber = session.facilityNumber else {
            print("Malformed session detected")
            return
        }
        if (facilityNumber == "NONE") {
            self.title = "Area monitors for \(facility.capitalized)"
        }
        else {
            self.title = "Area monitors for \(facility.capitalized) \(facilityNumber)"
        }
        do {
            areaMonitors = try query(withKVPs: [(DataProperty.facility, facility),
                                            (DataProperty.facilityNumber, facilityNumber)])
        } catch {
            print("Error displaying session")
            return
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == Segues.sessionToMonitor) {
            guard let destinationController = segue.destination as? MonitorDisplayVC else {
                return
            }
            guard let areaMonitor = sender as? NSManagedObject else {
                print("Couldn't get sender from SessionDisplayVC")
                return
            }
            destinationController.areaMonitor = areaMonitor
        }
    }
}

extension SessionDisplayVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.areaMonitors.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let areaMonitor = self.areaMonitors[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let description: String = areaMonitor.value(forKeyPath: DataProperty.location) as? String ?? "No description"
        cell.textLabel?.text = "\(description)"
        cell.textLabel?.numberOfLines = 0
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}

extension SessionDisplayVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let areaMonitor = self.areaMonitors[indexPath.row]
        performSegue(withIdentifier: Segues.sessionToMonitor, sender: areaMonitor)
    }
}
