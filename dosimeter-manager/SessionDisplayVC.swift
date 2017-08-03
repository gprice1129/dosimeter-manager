//
//  SessionDisplayVC.swift
//  dosimeter-manager
//
//  Created by Admin on 7/20/17.
//  Copyright © 2017 Guthrie Price. All rights reserved.
//

import UIKit
import CoreData

class SessionDisplayVC: QueryModeVC {
    
    @IBOutlet weak var unknownLocationButton: UIButton!
    @IBOutlet weak var descriptionDisplay: UITableView!
    var session: Session?
    var areaMonitors: [NSManagedObject] = []
    
    struct Segues {
        static let listToInfo = "ListToInfo"
        static let listToVerify = "ListToVerify"
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
            switch (self.currentMode) {
            case .normal:
                self.unknownLocationButton.isHidden = true
                self.unknownLocationButton.isUserInteractionEnabled = false
                self.unknownLocationButton.frame.size.height = 0
                areaMonitors = try query(withKVPs: [(DataProperty.facility, facility),
                                                (DataProperty.facilityNumber, facilityNumber)])
            case .recovery:
                areaMonitors = try query(withKVPs: [(DataProperty.facility, facility),
                                                (DataProperty.facilityNumber, facilityNumber)], fetchRetired: true)
            }
            areaMonitors = areaMonitors.sorted(by: monitorComparator)
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
        guard let identifier = segue.identifier else {
            return
        }
        switch (identifier) {
        case Segues.listToInfo:
            guard let destinationController = segue.destination as? MonitorInfoVC else {
                return
            }
            guard let areaMonitor = sender as? NSManagedObject else {
                print("Couldn't get sender from SessionDisplayVC")
                return
            }
            destinationController.areaMonitor = areaMonitor
        case Segues.listToVerify:
            guard let destinationController = segue.destination as? MonitorVerifyVC else {
                return
            }
            guard let areaMonitor = sender as? NSManagedObject else {
                return
            }
            destinationController.areaMonitor = areaMonitor
            guard let barcode = newEntity[DataProperty.oldCode] else {
                return
            }
            destinationController.scannedBarcode = barcode
        default:
            return
        }
    }
    
    @IBAction func didPressUnknownLocation(_ sender: Any) {
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
        switch (self.currentMode) {
        case .normal:
            performSegue(withIdentifier: Segues.listToInfo, sender: areaMonitor)
        case .recovery:
            performSegue(withIdentifier: Segues.listToVerify, sender: areaMonitor)
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let areaMonitor = self.areaMonitors[indexPath.row]
        let description: String = areaMonitor.value(forKeyPath: DataProperty.location) as? String ?? "No description"
        let status: String = areaMonitor.value(forKey: DataProperty.status) as? String ?? Status.flagged
        let tag: String? = areaMonitor.value(forKey: DataProperty.tag) as? String
        if (tag == nil) {
            cell.textLabel?.text = "\(description)"
        }
        else {
            cell.textLabel?.text = "\(tag!) \(description)"
        }
        cell.textLabel?.numberOfLines = 0
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.backgroundColor = UIColor.white.withAlphaComponent(0)
        switch (status) {
        case Status.flagged:
            cell.backgroundColor = UIColor.yellow.withAlphaComponent(0.5)
        case Status.recovered:
            cell.backgroundColor = UIColor.green.withAlphaComponent(0.5)
        case Status.retired:
            cell.backgroundColor = UIColor.red.withAlphaComponent(0.5)
        default:
            break
        }
    }
}
