//
//  Utility.swift
//  dosimeter-manager
//
//  Created by Admin on 7/20/17.
//  Copyright © 2017 Guthrie Price. All rights reserved.
//

func format(line: String) -> [String]? {
    guard var splitLine: [String] = split(line: line) else {
        return nil
    }
    let unFormattedFacility = splitLine[0]
    var formattedFacility: String = ""
    for char in unFormattedFacility.characters {
        if (char == "[") {
            break
        }
        formattedFacility.append(char)
    }
    if let lastCharacter = formattedFacility.characters.last {
        if (lastCharacter == "-") {
            formattedFacility.remove(at: formattedFacility.index(before: formattedFacility.endIndex))
        }
    }
    formattedFacility = formattedFacility.trimmingCharacters(in: .whitespaces).uppercased()
    var facility: String = formattedFacility
    var facilityNumber: String = "NONE"
    if (formattedFacility.hasPrefix("BLDG")) {
        let splitFacility = formattedFacility.components(separatedBy: .whitespaces)
        facility = splitFacility[0]
        facilityNumber = splitFacility[1]
    }
    splitLine[0] = facility
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
