//
//  ProxiAdvertizer.swift
//  Proxi
//
//  Created by Michael Flowers on 7/31/19.
//  Copyright © 2019 Michael Flowers. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol ProxiAdvertizerDelegate: class {
    func didStartAdvertising()
    func didStopAdvertising()
    func didConnect()
}

class ProxiAdvertizer: NSObject {
    var peripheralManager: CBPeripheralManager?
    var proxiCharacteristic: CBMutableCharacteristic?
    var proxiService: CBMutableService?
    var didSendValue: Bool = false
    weak var delegate: ProxiAdvertizerDelegate?

    init(delegate: ProxiAdvertizerDelegate?){
        super.init()
        print("\(#line) #1: Initialize CBPeripheralManager. This Triggers a CBPeripheralManagerDelegate Method Callback ")
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil) //nil means the peripheral manager dispatches peripheral role events on the main queue
        self.delegate = delegate
    }
    
    //MARK: Setting up Your services and Characteristics
    private func setupServiceAndCharacteristic(){
        let charUUID = CBUUID(string: kProxiCharacteristicUUID)
        let serviceUUID = CBUUID(string: kProxiServiceUUID)
        
         proxiCharacteristic = CBMutableCharacteristic(type: charUUID, properties: [.read, .write, .notify], value: nil, permissions: [.readable, .writeable]) //set the value to nil because we expect that the value to change during the lifteime of the published service to which the characteristic belongs.
        
         proxiService = CBMutableService(type: serviceUUID, primary: true) //primary means its the top level one/first
        
        //link the characteristic to the service
        proxiService?.characteristics = [proxiCharacteristic] as? [CBCharacteristic]
        
        // After you have built your tree of services and characteristics, the next step in implementing the peripheral role on your local device is publishing them to the device's database of services and characteristics.
        //When you call this method to publish your services, the peripheral manager calls the didAddService delegate method
        print("\(#line) #3: peripheralManager?.add(proxiService). This Triggers a CBPeripheralManagerDelegate  didAdd service Method Callback ")
        if let proxiService = proxiService {
            peripheralManager?.add(proxiService)
            //After you publish a service and any of its associated characteristics to the peripheral's database, the service is cached and you can no longer make changes to it.
        }
    }
    
    /*
     When you  have published your services and characteristics to your device's database of services and characteristics, you are ready to start advertising some of them to any centrals that may be listening.
 */
    func startAdvertising(){
        //Users will advertise the same service UUID key, because I don't know how to grab the each person's different Device's local name and advertise that.
        //the cbuuid belongs to the service that you want to advertise, leave nil for advertising all of them
        let serviceUUID = CBUUID(string: kProxiServiceUUID)
        print("\(#line) #4: peripheralManager?.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [serviceCBUUID]]). This Triggers a CBPeripheralManagerDelegate  didStartAdvertising Method Callback ")
        peripheralManager?.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [serviceUUID]])
        delegate?.didStartAdvertising()
    }
    
    func stopAdvertising(){
        peripheralManager?.stopAdvertising()
        delegate?.didStopAdvertising()
    }
    
    func readValue(from characteristic: CBCharacteristic){
//        self.p
    }
}

extension ProxiAdvertizer: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print("\(#line) #2: peripheralManagerDidUpdateState -- Delegate Method.")
        switch peripheral.state {
        case .poweredOn:
            print("Bluetooth Radio PoweredOn")
            setupServiceAndCharacteristic()
            startAdvertising()
        case .poweredOff:
            print("Bluetooth Radio PoweredOff")
        default:
            print("Bluetooth radio doing something else")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        print("\(#line) #5: peripheralManager didAdd service -- Delegate Method.")
        if let error = error {
            print("Error in the didAdd service delegate method: \(error)")
            return
        }
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        //Once you begin advertising, remote centrals can discover and initiate a connection.
        print("\(#line) #6: peripheralManagerDidStartAdvertising -- Delegate Method.")
        if let error = error {
            print("Error in the peripheralManagerDidStartAdvertising delegate method: \(error)")
            return
        }

        //when a connected central requests to read the value of one of your characteristics, the peripheral manager calls didRecieveReadReqeust method of its delegate object.
        print("\(#line) #6b: peripheralManager?.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [serviceCBUUID]]). This Triggers a CBPeripheralManagerDelegate  didStartAdvertising Method Callback ")
    }
    
    //When a connected central requests to read the value of your characteristic.
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        print("\(#line) #7: peripheralManager didReceiveRead request -- Delegate Method.")
        //when you receive a simple request to read the value of a characteristic, the properties of the CBATTRequest object you receive from the delegate method can be used to make sure that the characteristic in your device's databases matches the one that the remote central specified in the original reqeust.
        print(request.debugDescription)
        print("resetoffset: \(request.offset), ALSO CHARACTERISTIC VALUE \(proxiCharacteristic?.value)")
//        peripheralManager?.respond(to: request, withResult: .success)
        //be sure to take into account the request's offset property when writting the value of your character
    }
    
    //when a connected central sends a reqeust to write the value of one or more of your characteristics, it triggers this delegate method.
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        print("\(#line) #8: peripheralManager didReceiveWrite request -- Delegate Method.")
        print(requests.debugDescription)
        //be sure to take into account the request's offset property when writting the value of your character
        
        for request in requests {
            if request.offset < (proxiCharacteristic?.value!.count)!{
                peripheralManager?.respond(to: request, withResult: .success)
                print("The Central who initiated request: \(request.central)")
            } else {
                print("Error in didReceiveWrite: \(#line)")
                peripheralManager?.respond(to: request, withResult: .invalidOffset)
            }
        }
    }
    
//    //When a connected central subscribes to the value of one of your characteristics, the peripheral manager calls didSubscribeToCharacteristic method
    //Catch when someone subscribes to our characteristic, then start sending data.
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("\(#line) #9: peripheralManager didSubscribeTo characteristic  -- Delegate Method.")
        print("Central: \(central), subscribed to characteristic: \(characteristic)")

        //this is a cue to start sending the central updated value
        //fetch characteristic's new value
        if let  newValue = proxiCharacteristic?.value {
            didSendValue = (peripheralManager?.updateValue(newValue, for: characteristic as! CBMutableCharacteristic, onSubscribedCentrals: nil))!
        } else {
            print("Error with proxiCharacteristic value: \(proxiCharacteristic?.value)")
        }
    }
    
}
