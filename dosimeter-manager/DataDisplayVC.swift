//
//  DataDisplayVC.swift
//  dosimeter-manager
//
//  Created by Admin on 7/13/17.
//  Copyright © 2017 Guthrie Price. All rights reserved.
//

import UIKit
import CoreData

class DataDisplayVC: UIViewController {

    @IBOutlet weak var userUpdateLabel: UILabel!
    @IBOutlet weak var dosimeterDisplay: UITableView!
    
    let address: String = "https://www.slac.stanford.edu/~xiaosj/scanner/scan_test.csv"
    let localDirectory: String = "dosimeter-manager/"
    let fileName: String = "test.csv"
    var dosimeters: [NSManagedObject] = []
    var propertyFilter: String?
    
    enum EntityNames: String {
        case areaMonitor = "AreaMonitor"
    }
    
    enum DataProperty: String {
        case facility = "facility"
        case location = "location"
        case newCode = "newCode"
        case oldCode = "oldCode"
        case pickupDate = "pickupDate"
        case placementDate = "placementDate"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dosimeterDisplay.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Attempt to load core data on startup
        super.viewWillAppear(animated)
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: EntityNames.areaMonitor.rawValue)
        
        do {
            if let filter = self.propertyFilter {
                fetchRequest.predicate = NSPredicate(format: "%K like %@", DataProperty.oldCode.rawValue, filter)
            }
            self.dosimeters = try managedContext.fetch(fetchRequest)
            
        } catch {
            self.updateUser(userUpdate: "Could not fetch from database")
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        // Right now this dumps coredata for testing purposes
        super.viewWillDisappear(animated)
        
/*        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }

        let managedContext = appDelegate.persistentContainer.viewContext

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: EntityNames.areaMonitor.rawValue)
        let request = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try managedContext.execute(request)
            try managedContext.save()
            self.dosimeters = []
        } catch {
            print("Error deleting core data")
        } */
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func downloadOldData() {
        // Fetch the file from a static URL to download.
        // Note that right now this is extremely unsafe because the app can access any HTML site (see Info.plist)
        
        // TODO: Setup a dedicated server to manage the data files
        
        let documentsUrl: URL = FileManager.default.urls(for: .documentDirectory,
                                                   in: .userDomainMask).first as URL!
        let destinationUrl = documentsUrl.appendingPathComponent(fileName)
        let fileUrl = URL(string: address)
        let session = URLSession(configuration: URLSessionConfiguration.default)
        let request = URLRequest(url: fileUrl!)
        self.updateUser(userUpdate: "Hold on, downloading the file now...")
        let task = session.downloadTask(with: request) {
            (tempLocalUrl, response, error) in
            guard let tempLocalUrl = tempLocalUrl,
                 error == nil,
                 let statusCode = (response as? HTTPURLResponse)?.statusCode else {
                    self.updateUser(userUpdate: "Error downloading the file")
                    return
            }
            
            self.updateUser(userUpdate: "Success! Status code: \(statusCode)")
            
            do {
                try FileManager.default.copyItem(at: tempLocalUrl, to: destinationUrl)
            } catch {
                self.updateUser(userUpdate: "Error copying file")
            }
        }
        task.resume()
        
    }
    
    func deleteOldData() {
        // Removes the current old data csv file thats stored locally
        let documentsUrl: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first as URL!
        let destinationFileUrl = documentsUrl.appendingPathComponent(fileName)
        do {
            try FileManager.default.removeItem(at: destinationFileUrl)
            self.updateUser(userUpdate: "Successfully deleted file")
        } catch {
            self.updateUser(userUpdate: "Error deleteing file")
        }
    }
    
    func generateCoreData() -> Bool {
        // Attemps to save an old data file to core data
        //
        // :no params:
        //
        // :returns: true if successful, false if there was an error
        
        guard let oldData = self.readOldData() else {
            // TODO: Alert the user to verify that the old data has been downloaded
            print("The old data was not found")
            return false
        }
        var entity: [String: String] = [:]
        let format: [Int: String] = getFormat(formatLine: oldData[0])
        for line in oldData.dropFirst() {
            guard let splitLine: [String] = self.split(line: line) else {
                print("Malformed CSV file, no closing \" found")
                return false
            }
            for key in format.keys {
                if (key >= splitLine.count) {
                    continue
                }
                entity[format[key]!] = splitLine[key]
            }
            self.saveData(entity: entity)
        }
        return true
    }
    
    func split(line: String) -> [String]? {
        var splitLine: [String]? = []
        var temp: String = ""
        var inQuotedSection: Bool = false
        for char in line.characters {
            switch(char) {
            case ",":
                if (inQuotedSection) {
                    temp.append(char)
                }
                else {
                    splitLine!.append(temp)
                    temp = ""
                }
            case "\"":
                inQuotedSection = !inQuotedSection
            default:
                temp.append(char)
            }
        }
        if (inQuotedSection) {
            return nil
        }
        splitLine!.append(temp)
        return splitLine
    }
    
    func saveData(entity: [String: String]) {
        // Attempts to write a single value and key to code data
        //
        // :propertyValue: The value of the property you want to save
        // :propertyKey: The key of the property you want to save
        //
        // :no return:
        
        // TODO: Alert the user of a fatal error
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            print("Couldn't get the app delegate")
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let coreDataEntity = NSEntityDescription.entity(forEntityName: EntityNames.areaMonitor.rawValue, in: managedContext)!
        let areaMonitor = NSManagedObject(entity: coreDataEntity, insertInto: managedContext)

        for (propertyKey, propertyValue) in entity {
            var value: Any? = propertyValue
            if (propertyKey == DataProperty.pickupDate.rawValue || propertyKey == DataProperty.placementDate.rawValue) {
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "en_US")
                dateFormatter.setLocalizedDateFormatFromTemplate("dd-MMM-yy")
                value = dateFormatter.date(from: propertyValue)
            }
            areaMonitor.setValue(value, forKeyPath: propertyKey)
        }
        do {
            try managedContext.save()
            self.dosimeters.append(areaMonitor)
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }

    
    func readOldData() -> [String]? {
        // Attemps to read the old csv file at the location specified in the member variables
        //
        // :no params:
        //
        // :returns: An array of strings representing the lines of the csv file or nil if there was an error
        
        let documentsUrl: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first as URL!
        let fileUrl: URL = documentsUrl.appendingPathComponent(fileName)
        do {
            let data = try String(contentsOf: fileUrl, encoding: String.Encoding.ascii)
            return data.components(separatedBy: "\n")
        } catch {
            return nil
        }
    }
    
    func getFormat(formatLine: String) -> [Int: String] {
        // Gets the format of a csv file by reading the format line metadata
        //
        // :formatLine: A line in the csv file that gives hints of what column corresponds to what property
        //
        // :returns: A dictionary of column positions to property names
        
        var format: [Int: String] = [:]
        let fields: [String: DataProperty] = ["name": DataProperty.facility,
                                        "description": DataProperty.location,
                                        "placement date": DataProperty.placementDate,
                                        "pick up date": DataProperty.pickupDate,
                                        "old inlight": DataProperty.oldCode,
                                        "new inlight": DataProperty.newCode]
        
        for (i, word) in formatLine.components(separatedBy: ",").enumerated() {
            let word = word.lowercased().trimmingCharacters(in: .whitespaces)
            guard let field = fields[word] else {
                continue
            }
            format[i] = field.rawValue
        }
        return format
    }
    
    func updateUser(userUpdate: String) {
        DispatchQueue.main.async {
            self.userUpdateLabel.text = userUpdate
        }
    }
    
    @IBAction func didPressDownload(_ sender: Any) {
        downloadOldData()
    }
    
    @IBAction func didPressDelete(_ sender: Any) {
        deleteOldData()
    }
    
    @IBAction func didPressLoad(_ sender: Any) {
        if (self.generateCoreData()) {
            // Load it to the tableView
            self.updateUser(userUpdate: "Data loaded successfully")
            self.dosimeterDisplay.reloadData()
        } else {
            self.updateUser(userUpdate: "There was an error while loading the data")
        }
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

extension DataDisplayVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dosimeters.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let dosimeter = self.dosimeters[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = dosimeter.value(forKeyPath: DataProperty.oldCode.rawValue) as? String
        return cell
    }
}
