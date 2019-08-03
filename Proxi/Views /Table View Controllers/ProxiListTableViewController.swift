//
//  ProxiListTableViewController.swift
//  Proxi
//
//  Created by Michael Flowers on 7/29/19.
//  Copyright © 2019 Michael Flowers. All rights reserved.
//

import UIKit

class ProxiListTableViewController: UITableViewController {

    //MARK: - Properties
    var proxiScanner: ProxiScanner?
    var proxiAdvertizer: ProxiAdvertizer?
    var isScanning = false
    var isAdvertising = false
    
    //MARK: IBOutlets
    @IBOutlet weak var scanButtonProperties: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //this will initialize the ProxiScanner class which will in turn initialize the centralManger and turn on the bluetooth radio
        proxiScanner = ProxiScanner(delegate: self)
        //this will initiate the ProxiAdvertizer class which will in turn initialize the peripheralManager and start advertizing
        proxiAdvertizer = ProxiAdvertizer(delegate: self)
    }

    @IBAction func scanButtonPressed(_ sender: UIBarButtonItem) {
        if let scanner = proxiScanner {
            
            if isScanning {
                scanner.stopScan()
            } else {
                scanner.startScan()
            }
        }
    }
    
    @objc func advertise(){
    
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return proxiScanner?.peripheralArray.count ?? 0
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProxiCell", for: indexPath)

        // Configure the cell...
        let peripheral = proxiScanner?.peripheralArray[indexPath.row]
        cell.textLabel?.text = peripheral?.name
        return cell
    }
  
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
extension ProxiListTableViewController: ProxiScannerDelegate {
    func didStartScanning() {
        print("DidStartScanning Delegate Method triggered")
        self.view.backgroundColor = .red
        scanButtonProperties.title = "Stop"
        isScanning = true
        tableView.reloadData()
    }
    
    func didStopScanning() {
        print("didStopScanning Delegate Method triggered")
        self.view.backgroundColor = .clear
        scanButtonProperties.title = "Scan"
        isScanning = false
    }
    
    func wasAddedToArray() {
        tableView.reloadData()
    }
}

extension ProxiListTableViewController: ProxiAdvertizerDelegate {
    func didStartAdvertising() {
        tableView.tintColor = .green
    }
    
    func didStopAdvertising() {
        
    }
    
    func didConnect() {
        
    }
    
    
}
