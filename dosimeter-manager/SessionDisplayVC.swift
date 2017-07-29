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
        static let listToInfo = "ListToInfo"
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
            areaMonitors = areaMonitors.sorted {
                guard let status0 = $0.value(forKey: DataProperty.status) as? String,
                    let status1 = $1.value(forKey: DataProperty.status) as? String else {
                        print("data is corrupted")
                        return false
                }
                switch (status0, status1) {
                case let (s0, _) where s0 == Status.unrecovered:
                    return true
                case let (_, s1) where s1 == Status.unrecovered:
                    return false
                case let (s0, _) where s0 == Status.flagged:
                    return true
                case let (_, s1) where s1 == Status.flagged:
                    return false
                default:
                    return true
                }
            }
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
        if (segue.identifier == Segues.listToInfo) {
            guard let destinationController = segue.destination as? MonitorInfoVC else {
                return
            }
            guard let areaMonitor = sender as? NSManagedObject else {
                print("Couldn't get sender from SessionDisplayVC")
                return
            }
            destinationController.areaMonitor = areaMonitor
        }
    }
    
    @IBAction func didPressGoBackUnwind(sender: UIStoryboardSegue) {
        return
    }
}

extension SessionDisplayVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.areaMonitors.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        return cell
    }
}

extension SessionDisplayVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let areaMonitor = self.areaMonitors[indexPath.row]
        performSegue(withIdentifier: Segues.listToInfo, sender: areaMonitor)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let areaMonitor = self.areaMonitors[indexPath.row]
        let description: String = areaMonitor.value(forKeyPath: DataProperty.location) as? String ?? "No description"
        let status: String = areaMonitor.value(forKey: DataProperty.status) as! String
        cell.textLabel?.text = "\(description)"
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.backgroundColor = UIColor.white.withAlphaComponent(0)
        cell.accessoryType = .disclosureIndicator
        switch (status) {
        case Status.flagged:
            cell.backgroundColor = UIColor.yellow.withAlphaComponent(0.5)
        case Status.recovered:
            cell.backgroundColor = UIColor.green.withAlphaComponent(0.5)
        default:
            break
        }
    }
}
