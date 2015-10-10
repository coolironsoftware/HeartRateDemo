//
//  HeartRateMeasurement.swift
//  StressMeter
//
//  Created by Doug Wait on 10/2/15.
//  Copyright © 2015 Doug Wait. All rights reserved.
//

import Foundation

// Decode the value (flags and heart rate)
//
// Example with 16 bit heart rate, energy expended, and zero or more RR-Interval values
//   +--------+--------+--------+--------+--------+--------+--------+--------+--------
//   | flags  | HR 16           | Energy Expended | RR-Interval 0   | RR-Interval 1 ...
//   +--------+--------+--------+--------+--------+--------+--------+--------+--------
//
// Example with 8 bit heart rate and zero or more RR-Interval values
//   +--------+--------+--------+--------+--------+--------
//   | flags  | HR 8   | RR-Interval 0   | RR-Interval 1 ...
//   +--------+--------+--------+--------+--------+--------
//

// OptionSetType is perfect for decoding the flags from the first
// byte of the measurement value.
//
struct HRFlags : OptionSetType {
    
    let rawValue: UInt8
    init(rawValue: UInt8) { self.rawValue = rawValue }
    
    //
    // Flags for heart rate characteristic
    //
    //    Heart rate format (bit 0)
    //    0 == UINT8
    //    1 == UINT16
    //
    //    Sensor contact status (bits 1-2)
    //    0 == feature not supported
    //    1 == feature not supported
    //    2 == feature supported no contact
    //    3 == feature supported contact
    //
    //    Energy expended status (bit 3)
    //    0 == not present
    //    1 == present
    //
    //    RR-Interval values (bit 4)
    //    0 == not present
    //    1 == present
    //
    //    Reserved (bits 5-7)
    
    static let SixteenBitValue          = HRFlags(rawValue: 0b00000001)
    static let SensorContactSupported   = HRFlags(rawValue: 0b00000100)
    static let SensorInContact          = HRFlags(rawValue: 0b00000010)
    static let EnergyExpendedAvailable  = HRFlags(rawValue: 0b00001000)
    static let RRValuesPresent          = HRFlags(rawValue: 0b00010000)
}

struct HeartRateMeasurement {
    
    let flags : HRFlags
    let heartRate : UInt16
    let energyExpended : UInt16?
    let rrIntervals : [UInt16]?
    var contactSupported : Bool {
        get {
            return flags.contains(.SensorContactSupported)
        }
    }
    var inContact : Bool {
        get {
            return contactSupported && flags.contains(.SensorInContact)
        }
    }
    var sixteenBit : Bool {
        get {
            return flags.contains(.SixteenBitValue)
        }
    }
    var energyExpendedAvailable : Bool {
        get {
            return flags.contains(.EnergyExpendedAvailable)
        }
    }
    
    init(rawMeasurement: NSData) {
        
        // This UnsafePointer<Void> type will be passed as an
        // inout type to the decoding functions. They will move the
        // pointer forward by the amount of data they decode.
        var data : UnsafePointer<Void> = rawMeasurement.bytes
        let endOfData : UnsafePointer<Void> = rawMeasurement.bytes.advancedBy(rawMeasurement.length)
        
        flags =             getFlags(&data)
        heartRate =         getHeartRate(flags, data: &data)
        energyExpended =    getEnergyExpended(flags, data: &data)
        rrIntervals =       getRRIntervals(flags, data: data, endOfData: endOfData)
    }    
    
}

private func get8(inout data: UnsafePointer<Void>) -> UInt8 {
    let next8 = unsafeBitCast(data, UnsafePointer<UInt8>.self)[0]
    data = data.successor()
    return next8
}

private func get16(inout data: UnsafePointer<Void>) -> UInt16 {
    let next16 = CFSwapInt16LittleToHost(unsafeBitCast(data, UnsafePointer<UInt16>.self)[0])
    data = data.advancedBy(2)
    return next16
}

private func get16(inout data: UnsafePointer<UInt16>) -> UInt16 {
    let next16 = CFSwapInt16LittleToHost(data[0])
    data = data.successor()
    return next16
}

private func getFlags(inout data: UnsafePointer<Void>) -> HRFlags {
    return HRFlags(rawValue: get8(&data))
}

private func getHeartRate(flags: HRFlags, inout data: UnsafePointer<Void>) -> UInt16 {
    
    var heartRate : UInt16 = 0
    
    if flags.contains(.SixteenBitValue) {
        heartRate = get16(&data)
    } else {
        heartRate = UInt16(get8(&data))
    }
    
    return heartRate
}

private func getEnergyExpended(flags: HRFlags, inout data: UnsafePointer<Void>) -> UInt16? {
    
    if flags.contains(.EnergyExpendedAvailable) {
        return get16(&data)
    } else {
        return nil
    }
    
}

private func getRRIntervals(flags: HRFlags, data: UnsafePointer<Void>, endOfData: UnsafePointer<Void>) -> [UInt16]? {
    
    if !flags.contains(.RRValuesPresent) {
        // We won't find any RR interval values here so bail
        // out early and return nothing
        return nil
    }
    
    var rrIntervals = [UInt16]()
    
    // we need to work with UInt16 values so create some indicators
    let endOfData16 = unsafeBitCast(endOfData, UnsafePointer<UInt16>.self)
    var curData = unsafeBitCast(data, UnsafePointer<UInt16>.self)
    
    while curData < endOfData16 {
        rrIntervals.append(get16(&curData))
    }
    
    return rrIntervals
}
