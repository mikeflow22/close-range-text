//
//  ProxiScanner.swift
//  Proxi
//
//  Created by Michael Flowers on 7/31/19.
//  Copyright © 2019 Michael Flowers. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol ProxiScannerDelegate: class {
    func didStartScanning()
    func didStopScanning()
    func wasAddedToArray()
}

class ProxiScanner: NSObject {
    var centralManager: CBCentralManager?
    var discoveredRemotePeripheral: CBPeripheral?
    var data: Data? = Data()
    var peripheralArray = [CBPeripheral]()
    weak var delegate: ProxiScannerDelegate?
    
    init(delegate: ProxiScannerDelegate?){
        super.init()
        print("\(#line) #1: Initialize CBCEntralManager. This Triggers a CBCentralManagerDelegate Method Callback ")
        centralManager = CBCentralManager(delegate: self, queue: nil)
        self.delegate = delegate
    }
    
    //start scan
    func startScan(){
        print("Start Scan")
        //we are not looking for specific services or uuid keys/names.
        //TODO: figure out a way to get an array of services uuid's from users who download this app
        print("\(#line) #3: centralManager?.scanForPeripherals(withServices: nil, options: nil). This Triggers a CBCentralManagerDelegate didDiscoverPeripheral Callback Method. ")
        //explicitly state what to scan for
        let serviceUUID = CBUUID(string: kProxiServiceUUID)
        let options = [CBAdvertisementDataServiceUUIDsKey : kProxiServiceUUID ]
        centralManager?.scanForPeripherals(withServices: [serviceUUID], options: options)
//        centralManager?.scanForPeripherals(withServices: nil, options: nil)
        delegate?.didStartScanning()
    }
    
    func stopScan(){
        print("Stop Scan")
        centralManager?.stopScan()
        delegate?.didStopScanning()
    }
}

extension ProxiScanner: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("\(#line) #2: centralManagerDidUpdateState -- Delegate Method.")
        switch central.state {
        case .poweredOn:
            print("Bluetooth Radio is PoweredOn")
        case .poweredOff:
            print("Bluetooth Radio is PoweredOFF")
        default:
            print("Bluetooth Radio is doing something else.")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("\(#line) #4: centralManager didDiscover peripheral -- Delegate Method.")
        print("centralManager Peripheral didDiscover to: \(String(describing: peripheral.name))")

        //The newly discovered peripheral is returned as a CBPeripheral object. If you plan to connect to the discovered peripheral, keep a strong reference to it so the system does not deallocate it.
        discoveredRemotePeripheral = peripheral
        
        print("connecting to remotePeripheral: \(peripheral)")
        //Once you initiate a connection, the central manager will notify the delegate as to whether or not the connection was successful. Which will trigger the didConnect/ didFailToConnect delegate method
        print("\(#line) #5: centralManager?.connect(peripheral, options: nil). This Triggers a CBCentralManagerDelegate didConnect/didFailToConnect Callback Method. ")
        centralManager?.connect(peripheral, options: nil)
        
        if peripheral.name != nil {
            if !peripheralArray.contains(peripheral){
                peripheralArray.append(peripheral)
                delegate?.wasAddedToArray()
            }
        }
        
        //Add the discovered peripherals to our array
        
        print("centralManager PeripheralArray.count: \(peripheralArray.count)")
        
        //MAYBE: - STOP SCANNING HERE
//        stopScan()
    }
    
    //This is thee function, really, once connected with a peripheral you can drill down and discover its services
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("\(#line) #6: centralManager didConnect peripheral -- Delegate Method.")
        print("centralManager Peripheral didConnect to: \(String(describing: peripheral.name))")
        data?.count = 0
        
        //set the newly discovered peripheral's delegate to this class
        peripheral.delegate = self //without doing this we wont recieve discovery notifications
        
        //when services are discovered the newly discovered peripheral will notitfy its delegate by calling didDiscoverServices method. Which means you have to adopt the CBPeripheralDelegate Protocol
        print("\(#line) #7: centralManager peripheral.discoverServices(nil). This Triggers a CBPeripheralDelegate didDiscoverServices Callback Method. ")
        let serviceUUID = CBUUID(string: kProxiServiceUUID)
        peripheral.discoverServices([serviceUUID])
        //didConnect so stop scanning
        stopScan()
        print("Stopped scanning cuz we connected")
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("#6b centralManager DIDFAILTOCONNECT. \(#line)")
        if let error = error {
            print("centralManager Connection error: \(error.localizedDescription), DETAILED: \(error)")
        }
        central.stopScan()
    }
}

extension  ProxiScanner: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("\(#line) #8: CBPeripheralDelegate didDiscoverServices -- Delegate Method.")
        
        if let error = error {
            print("Error didDiscoverServices: \(error)")
            return
        }
        if let services = peripheral.services {
            for service in services {
                if service.uuid.uuidString == kProxiCharacteristicUUID {
                    peripheral.discoverCharacteristics(nil, for: service)
                }
            }
        }
        print("\(#line) #9: CBPeripheralDelegate peripheral.discoverCharacteristics(nil, for: aService). This Triggers a CBPeripheralDelegate didDiscoverCharacteristicsFor Callback Method. ")
    }
    
    //This is where we write back to the peripheral peripheral.writeValue()
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("\(#line) #10: CBPeripheralDelegate didDiscoverCharacteristicsFor -- Delegate Method.")
        
        if let error = error {
            print("Error didDiscoverCharacteristicsFor: \(error)")
            return
        }
        
        
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
             
                //after you have found a characteristic of a service that you are intersted in, you can read the characteristic's value
                if characteristic.properties.contains(.read) {
                    print("Read")
                }
                if characteristic.properties.contains(.write){
                    print("write")
                }
                peripheral.setNotifyValue(true, for: characteristic)
                let properties = characteristic.properties.rawValue
                print("Reading value of Characteristic: \(properties) of peripheral: \(peripheral)")
                
                //when you attempt to read the value of a characteristic of a servce that you are interested in, you can read the characteristic's value by calling the peripheral's readValueForCharacteristic method
                print("\(#line) #11: CBPeripheralDelegate peripheral.readValue(for: characteristic). This Triggers a CBPeripheralDelegate didUpdateValueFor characteristic Callback Method. ")
                peripheral.readValue(for: characteristic)
            }
        }
    }
//    //subscribing to a characteristic's value. You recieve notifications from the peripheral when a value changes.
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("\(#line) #12: CBPeripheralDelegate didUpdateNotificationStateFor characteristic -- Delegate Method.")
        if let error = error {
            print("Error didUpdateNotificationStateFor characteristic: \(error) of peripheral: \(peripheral)")
            return
        }
        
        //get the data from the -  if the value is successfully retrieved, you can access it through the characteristic's value property
        data = characteristic.value
        if let dataString = String(data: data!, encoding: .utf8) {
            //parse the data
            print("Data from characteristic's value: \(dataString)")
        }
        
        if characteristic.isNotifying {
            print("CBPeripheralDelegate Notification began on characteristic: \(characteristic)")
            print("CBPeripheralDelegate RAW VALUE OF CHARACTERISTIC: \(characteristic.properties.rawValue)")
        } else {
            print("Notification stopped on characteristic: \(characteristic), Disconnecting........")
            centralManager?.cancelPeripheralConnection(peripheral)
        }
    }
    
    //THIS IS WHERE YOU GET THE DATA FROM THE CHARACTERISTIC OFF OF THE PERIPHERAL
    //This lets us know that more data has arrived via notification on the  characteristic
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
         print("\(#line) #13: CBPeripheralDelegate didUpdateValueFor characteristic -- Delegate Method.")
        //Not all characteristics are readable. You can determine whether a characteristic is readable by clicking if its properties attribute includes the CBCharacteristicPropertyRead constant. If yuo try to read a value of a characteristic that is not readable, you will get an error.
        if let error = error {
            print("CBPeripheralDelegate Error didUpdateValueFor characteristic: \(error)")
            return
        }
        
        //SINCE WE GOT NEW DATA, this is where you can get the data from the characteristic and show it on the view
        peripheral.setNotifyValue(false, for: characteristic)
        centralManager?.cancelPeripheralConnection(peripheral)
        print("CBPeripheralDelegate canceled peripheral connection.")
    }
    
    //WRITING THE VALUE OF A CHARACTERISTIC
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("\(#line) #14: CBPeripheralDelegate didWriteValueFor characteristic -- Delegate Method.")
        if let error = error {
            print("Error didWriteValueFor characteristic: \(error)")
            return
        }
        let stringValue = "DID IT WORK?"
        guard let stringData = Data(base64Encoded: stringValue) else { print("Error on line: \(#line)"); return }
        peripheral.writeValue(stringData, for: characteristic, type: .withResponse)
    
    }
    
    //Once disconnecting happens, we need to clean up our local copy of the peripheral
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("\(#line) CentralManager didDisconnectPeripheral: \(peripheral)")
        if let error = error {
            print("CBPeripheralDelegate Error didUpdateValueFor characteristic: \(error)")
            return
        }
        discoveredRemotePeripheral = nil
        
        //since we are disconnected, we should scan again
        startScan()
    }
}
