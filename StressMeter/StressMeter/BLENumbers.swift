//
//  BLENumbers.swift
//  StressMeter
//
//  Created by Doug Wait on 9/14/15.
//  Copyright © 2015 Doug Wait. All rights reserved.
//

import CoreBluetooth

enum ServiceUUID : String {
    
    case HeartRate              = "0x180D"
    case DeviceInformation      = "0x180A"
    case RunningSpeedCadence    = "0x1814"
    
    // Would be nice to genericise this so that it isn't repeated.
    // Ideally the generic version would maintain the same level of
    // type safety as this version.
    static func uuid(enumName:ServiceUUID) -> CBUUID {
        return CBUUID(string: enumName.rawValue)
    }
    static func uuids(enumNames:[ServiceUUID]) -> [CBUUID] {
        return enumNames.map { uuid($0) }
    }
}

enum HeartRateCharacteristicUUID : String {
    
    // Heart Rate Characteristics
    case HeartRateMeasurement   = "0x2A37"
    case BodySensorLocation     = "0x2A38"
    
    static func uuid(enumName:HeartRateCharacteristicUUID) -> CBUUID {
        return CBUUID(string: enumName.rawValue)
    }
    static func uuids(enumNames:[HeartRateCharacteristicUUID]) -> [CBUUID] {
        return enumNames.map { uuid($0) }
    }
}

enum DeviceInformationCharacteristicUUID : String {
    
    // Device Information Characteristics
    case ManufacturerName       = "0x2A29"
    case ModelNumber            = "0x2A24"
    case HardwareRevision       = "0x2A27"
    
    static func uuid(enumName:DeviceInformationCharacteristicUUID) -> CBUUID {
        return CBUUID(string: enumName.rawValue)
    }
    static func uuids(enumNames:[DeviceInformationCharacteristicUUID]) -> [CBUUID] {
        return enumNames.map { uuid($0) }
    }
}
