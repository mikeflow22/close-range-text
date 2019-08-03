//
//  ProxiChatViewController.swift
//  Proxi
//
//  Created by Michael Flowers on 7/29/19.
//  Copyright © 2019 Michael Flowers. All rights reserved.
//

import UIKit
import CoreBluetooth
import MessageKit
import InputBarAccessoryView

class ProxiChatViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var textView: UITextView!
    //MARK: Properties
    private lazy var formatter: DateFormatter = {
        let result = DateFormatter()
        result.dateStyle = .medium
        result.timeStyle = .medium
        return result
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textField.delegate = self
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        //send message
    }
    @IBAction func sendText(_ sender: UIButton) {
    }
}

extension ProxiChatViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
    }
}

extension ProxiChatViewController: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        
    }
}
