//
//  SecondViewController.swift
//  Liber
//
//  Created by Alexandru Rosianu on 24/11/2018.
//  Copyright © 2018 Liber. All rights reserved.
//

import UIKit
import Firebase

class VerifyCodeCtrl: UIViewController {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let ref = Database.database().reference()
    
    @IBAction func onVerifyClicked(_ sender: Any) {
        UserDefaults.standard.set(true, forKey: "is_logged_in")
        UserDefaults.standard.set(appDelegate.phoneNumber!, forKey: "logged_in_phone_number")

        ref.child("users").child(appDelegate.phoneNumber!).child("ledger").child("uk_sort_code")
            .observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists() {
                    self.performSegue(withIdentifier: "skipToTabs", sender: nil)
                } else {
                    self.performSegue(withIdentifier: "continueRegistration", sender: nil)
                }
            })

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

}

