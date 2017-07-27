//
//  SessionController.swift
//  dosimeter-manager
//
//  Created by Admin on 7/19/17.
//  Copyright © 2017 Guthrie Price. All rights reserved.
//

import UIKit
import CoreData

class SessionController: QueryVC, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var facilityPicker: UIPickerView!
    let pickerComponents = 2
    var session: Session?
    var facilities: [String] = []
    var facilityNumbers: [[String]] = []
    var selectedFacility: Int = 0
    var selectedFacilityNumber: Int = 0
    
    struct facilityComponents {
        static let facility: Int = 0
        static let facilityNumber: Int = 1
    }
    
    struct Segues {
        static let sessionToReader: String = "SessionToReader"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        if (self.facilities.count > 0) {
            return
        }
        do {
            let areaMonitors = try query()
            var tempFacilities: Set<String> = []
            var facilityDictionary: [String: Set<String>] = [:]
            for monitor in areaMonitors {
                guard let facility: String = monitor.value(forKey: DataProperty.facility) as? String,
                     let facilityNumber: String = monitor.value(forKey: DataProperty.facilityNumber) as? String else {
                    continue
                }
                if (tempFacilities.contains(facility)) {
                    facilityDictionary[facility]?.insert(facilityNumber)
                }
                else {
                    tempFacilities.insert(facility)
                    facilityDictionary[facility] = Set<String>([facilityNumber])
                }
            }
            self.facilities = Array(facilityDictionary.keys.sorted())
            for facility in self.facilities {
                self.facilityNumbers.append(facilityDictionary[facility]!.sorted())
            }
        } catch {
            return
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == Segues.sessionToReader) {
            guard let destinationController = segue.destination as? BarcodeReaderVC else {
                return
            }
            destinationController.session = self.session
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return self.pickerComponents
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch (component) {
        case facilityComponents.facility:
            return facilities.count
        case facilityComponents.facilityNumber:
            return self.facilityNumbers[self.selectedFacility].count
        default:
            return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch (component) {
        case facilityComponents.facility:
            return self.facilities[row]
        case facilityComponents.facilityNumber:
            return self.facilityNumbers[self.selectedFacility][row]
        default:
            return ""
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch (component) {
        case facilityComponents.facility:
            self.selectedFacility = row
            self.facilityPicker.reloadComponent(facilityComponents.facilityNumber)
        case facilityComponents.facilityNumber:
            self.selectedFacilityNumber  = row
        default:
            return
        }
    }
        
    @IBAction func didPressSubmit(_ sender: Any) {
        let facility: String? = self.facilities[self.selectedFacility]
        let facilityNumber: String? = self.facilityNumbers[self.selectedFacility][self.selectedFacilityNumber]
        self.session = Session(forFacility: facility, withNumber: facilityNumber)
        performSegue(withIdentifier: Segues.sessionToReader, sender: self)
    }
}
