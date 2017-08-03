//
//  Utility.swift
//  dosimeter-manager
//
//  Created by Admin on 7/20/17.
//  Copyright © 2017 Guthrie Price. All rights reserved.
//

import CoreData

func monitorComparator(areaMonitor0: NSManagedObject, areaMonitor1: NSManagedObject) -> Bool {
    guard let status0 = areaMonitor0.value(forKey: DataProperty.status) as? String,
         let status1 = areaMonitor1.value(forKey: DataProperty.status) as? String else {
            print("data is corrupted")
            return false
    }
    switch (status0, status1) {
    case let (s0, s1) where s0 == s1:
        let tag0 = areaMonitor0.value(forKey: DataProperty.tag) as? String
        let tag1 = areaMonitor1.value(forKey: DataProperty.tag) as? String
        if (tag0 == nil) {
            return false
        }
        if (tag1 == nil) {
            return true
        }
        return (tag0! < tag1!)
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

func getUniqueFacilities(from areaMonitors: [NSManagedObject]) -> ([String], [[String]]) {
    var tempFacilities: Set<String> = []
    var facilityDictionary: [String: Set<String>] = [:]
    var facilityNumbers: [[String]] = []
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
    let facilities = Array(facilityDictionary.keys.sorted())
    for facility in facilities {
        facilityNumbers.append(facilityDictionary[facility]!.sorted())
    }
    return (facilities, facilityNumbers)
}

func format(line: String) -> [String]? {
    guard var splitLine: [String] = split(line: line) else {
        return nil
    }
    let unFormattedFacility = splitLine[0]
    var populateTag: Bool = false
    var formattedFacility: String = ""
    var tag: String = ""
    for char in unFormattedFacility.characters {
        if (populateTag) {
            tag.append(char)
        } else if (char == "[") {
            populateTag = true
            tag.append(char)
        } else {
        formattedFacility.append(char)
        }
    }
    if let lastCharacter = formattedFacility.characters.last {
        if (lastCharacter == "-") {
            formattedFacility.remove(at: formattedFacility.index(before: formattedFacility.endIndex))
        }
    }
    formattedFacility = formattedFacility.trimmingCharacters(in: .whitespaces).uppercased()
    tag = tag.trimmingCharacters(in: .whitespaces)
    var facility: String = formattedFacility
    var facilityNumber: String = "NONE"
    if (formattedFacility.hasPrefix("BLDG")) {
        let splitFacility = formattedFacility.components(separatedBy: .whitespaces)
        facility = splitFacility[0]
        facilityNumber = splitFacility[1]
    }
    splitLine[0] = facility
    splitLine.append(tag)
    splitLine.append(facilityNumber)
    return splitLine
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
