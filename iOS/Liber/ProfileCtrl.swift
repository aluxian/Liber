//
//  ProfileCtrl.swift
//  Liber
//
//  Created by Alexandru Rosianu on 24/11/2018.
//  Copyright © 2018 Liber. All rights reserved.
//

import UIKit
import Firebase

class ProfileCtrl: UITableViewController {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let ref = Database.database().reference()
    
    var fname: String?
    var lname: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref.child("users").child(appDelegate.phoneNumber!).child("first_name")
            .observe(.value, with: { (snapshot) in
                self.fname = snapshot.value as! String
                self.tableView.reloadData()
            })
        
        ref.child("users").child(appDelegate.phoneNumber!).child("last_name")
            .observe(.value, with: { (snapshot) in
                self.lname = snapshot.value as! String
                self.tableView.reloadData()
            })
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 1 && indexPath.row == 0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 && indexPath.row == 0 {
            UserDefaults.standard.set(false, forKey: "is_logged_in")
            UserDefaults.standard.setValue(nil, forKey: "logged_in_phone_number")
            performSegue(withIdentifier: "goToLoginScreen", sender: nil)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        if indexPath.section == 0 && indexPath.row == 0 {
            cell.detailTextLabel!.text = fname
        }
        if indexPath.section == 0 && indexPath.row == 1 {
            cell.detailTextLabel!.text = lname
        }
        return cell
    }
    
}
