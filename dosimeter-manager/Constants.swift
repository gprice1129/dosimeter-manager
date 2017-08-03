//
//  Constants.swift
//  dosimeter-manager
//
//  Created by Admin on 7/20/17.
//  Copyright © 2017 Guthrie Price. All rights reserved.
//

struct DataProperty {
    static let facility = "facility"
    static let facilityNumber = "facilityNumber"
    static let location = "location"
    static let newCode = "newCode"
    static let oldCode = "oldCode"
    static let pickupDate = "pickupDate"
    static let placementDate = "placementDate"
    static let status = "status"
    static let tag = "tag"
}

struct Status {
    static let unrecovered: String = "Needs replacing"
    static let recovered: String = "Replaced"
    static let flagged: String = "Needs investigation"
    static let retired: String = "Retired"
}
