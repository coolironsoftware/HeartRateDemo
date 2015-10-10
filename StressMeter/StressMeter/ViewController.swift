//
//  ViewController.swift
//  StressMeter
//
//  Created by Doug Wait on 9/14/15.
//  Copyright © 2015 Doug Wait. All rights reserved.
//

//
// This is a simple example written to demonstrate the use of CoreBluetooth to
// read the values coming from any heart rate monitor that meets the Bluetooth SIG
// Heart Rate Profile.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var servicesLabel: UILabel!
    @IBOutlet weak var hrSensorNameLabel: UILabel!
    @IBOutlet weak var RSSILabel: UILabel!
    @IBOutlet weak var heartRateLabel: UILabel!
    @IBOutlet weak var rrIntervalsLabel: UILabel!
    
    enum AppState {
        case Startup
        case BLEUnknown
        case BLEResetting
        case BLEUnsupported
        case BLEUnauthroized
        case BLEPoweredOff
        case Scanning
        case Connecting
        case Connected
        case Updating
    }
    
    var state : AppState = .Startup {
        didSet {
            stateLabel.text = String(state)
            switch state {
            case .Startup:
                stateLabel.backgroundColor = UIColor.lightGrayColor()
            case .Scanning:
                stateLabel.backgroundColor = UIColor.yellowColor()
            case .Connecting:
                stateLabel.backgroundColor = UIColor(red: 0.4, green: 0.0, blue: 0.4, alpha: 0.1)
            case .Connected:
                stateLabel.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.4, alpha: 0.1)
            case .Updating:
                stateLabel.backgroundColor = UIColor.greenColor()
            default:
                stateLabel.backgroundColor = UIColor.redColor()
            }
        }
    }
    
    var hrCBManager : CBCentralManager?
    var hrSensor : CBPeripheral?
    var hrSensorName : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /******************/
        /*    STEP 1      */
        /******************/
        hrCBManager = CBCentralManager(delegate: self, queue: nil, options: [
            CBCentralManagerOptionShowPowerAlertKey: true
            ])
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: CBCentralManagerDelegate methods
    
    /******************/
    /*    STEP 2      */
    /******************/
    // the one required CBCentralManagerDelegate method
    func centralManagerDidUpdateState(central: CBCentralManager) {
        
        // In a production app you would probably save the UUIDs
        // (from peripheral.identifier) of previously connected heart rate monitors
        // and first try to retrieve those known peripherals using
        // CBCentralManager.retrievePeripheralsWithIdentifiers(_:).
        // If after a period of time you couldn't connect to any of these
        // then you would scan. See the CoreBluetooth programming guide
        // for a detailed explaination of the reconnect process.
        
        /******************/
        /*    STEP 3      */
        /******************/
        setupScanning(central)
    }
    
    /******************/
    /*    STEP 4      */
    /******************/
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        print("Central manager didDiscoverPeripheral: \(peripheral), \(advertisementData), \(RSSI)")
        
        // A little bit of logic here to bail out if we're reconnecting after
        // an unexpected disconnect and the peripheral we have found isn't the
        // one we were previously connected to.
        //
        // *** This would only happen if we started a scan rather than a reconnect
        // after a disconnect. The current example isn't setup to demonstrate this
        // but I'm leaving this code here just to make the point that we use
        // the name as our unique ID. ***
        
        if let name = peripheral.name {
            if hrSensorName != nil && name != self.hrSensorName {
                // return and keep scanning this isn't the sensor we're looking for
                return
            }
            
            // Capture the local name. We'll use this if we get disconnected accidentally and
            // need to reconnect to the same sensor.
            hrSensorName = name
            hrSensorNameLabel.text = name
        }
        
        if let advertisedServiceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
            servicesLabel.text = "Services \(advertisedServiceUUIDs)"
        }
        
        RSSILabel.text = "RSSI: \(RSSI)"
        
        hrSensor = peripheral
        
        hrCBManager?.stopScan()
        
        /******************/
        /*    STEP 5      */
        /******************/
        hrCBManager?.connectPeripheral(peripheral, options: nil)
        print("Requested a connection to \(peripheral)")
        state = .Connecting
    }
    
    /******************/
    /*    STEP 6      */
    /******************/
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        print("Connected peripheral: \(peripheral)")
        print("Peripheral name: \(peripheral.name)")
        state = .Connected
        
        peripheral.delegate = self
        
        /******************/
        /*    STEP 7      */
        /******************/
        peripheral.discoverServices(ServiceUUID.uuids([.HeartRate, .DeviceInformation]))
        
    }
    
    //MARK: CBPeripheralDelegate methods
    
    /******************/
    /*    STEP 8      */
    /******************/
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        print("Discovered services for peripheral: \(peripheral)")
        print("services are: \(peripheral.services)")
        
        for service in peripheral.services! {
            switch service.UUID {
            case ServiceUUID.uuid(.HeartRate):
                print("Discovered heart rate service")
                /******************/
                /*    STEP #9     */
                /******************/
                peripheral.discoverCharacteristics(HeartRateCharacteristicUUID.uuids([.HeartRateMeasurement, .BodySensorLocation]), forService: service)
            case ServiceUUID.uuid(.DeviceInformation):
                print("Discovered device information service")
            default:
                print("unrecognized service: \(service.UUID)")
            }
        }
    }
    
    /******************/
    /*    STEP 10     */
    /******************/
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        print("Discovered characteristics for service: \(service.characteristics)")
        
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.UUID == HeartRateCharacteristicUUID.uuid(.HeartRateMeasurement) {
                    if characteristic.properties.contains(.Notify) {
                        /******************/
                        /*    STEP 11     */
                        /******************/
                        peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                    } else {
                        print("HR sensor non-compliant with spec. HR measurement not NOTIFY capable")
                    }
                } else {
                    if characteristic.properties.contains(.Read) {
                        peripheral.readValueForCharacteristic(characteristic)
                    }
                }
            }
        }
    }
    
    /******************/
    /*    STEP 12     */
    /******************/
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        print("periperal: \(peripheral) did update value for characteristic: \(characteristic)")
        
        if let value = characteristic.value {
            self.state = .Updating
            // This is the moment it dawns on you that everything you need to
            // know to read a BLE heart rate monitor isn't included in the Apple
            // documentation.
            print("heart rate measurement value is: \(value)")
            /******************/
            /*    STEP 13     */
            /******************/
            renderHeartRateMeasurement(value)
        } else {
            print("no value")
        }
    }
    
    //MARK: private methods
    
    func setupScanning(central: CBCentralManager) {
        switch central.state {
        case .Unknown:
            print("CBCentralManager state Unknown")
            state = .BLEUnknown
        case .Resetting:
            print("CBCentralManager state Resetting")
            state = .BLEResetting
        case .Unsupported:
            print("CBCentralManager state Unsupported")
            state = .BLEUnsupported
        case .Unauthorized:
            print("CBCentralManager state Unauthorized")
            state = .BLEUnauthroized
        case .PoweredOff:
            print("CBCentralManager state PoweredOff")
            state = .BLEPoweredOff
        case .PoweredOn:
            print("CBCentralManager state PoweredOn")
            state = .Scanning
            central.scanForPeripheralsWithServices(ServiceUUID.uuids([.HeartRate]), options: nil)
        }
    }
    
    func renderHeartRateMeasurement(value: NSData) {
        
        let hrMeasurement = HeartRateMeasurement(rawMeasurement: value)
        
        heartRateLabel.alpha = 1.0
        heartRateLabel.text = String(hrMeasurement.heartRate)
        UIView.animateWithDuration(1) { () -> Void in
            self.heartRateLabel.alpha = 0.1
        }
        
        if let rrIntervals = hrMeasurement.rrIntervals {
            self.rrIntervalsLabel.text = String(rrIntervals)
        }
        
        print("heartRate: \(hrMeasurement.heartRate)")
        print("rr intervals: \(hrMeasurement.rrIntervals)")
        print("nsdata length: \(value.length)")
        
    }
}

