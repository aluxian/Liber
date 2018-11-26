//
//  NameInputCtrl.swift
//  Liber
//
//  Created by Alexandru Rosianu on 24/11/2018.
//  Copyright © 2018 Liber. All rights reserved.
//

import UIKit
import Firebase

class NameInputCtrl: UIViewController {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let ref = Database.database().reference()
    
    @IBOutlet weak var fname: UITextField!
    @IBOutlet weak var lname: UITextField!
    
    @IBAction func onSubmitClicked(_ sender: Any) {
        let first_name = fname.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let last_name = lname.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        
        ref.child("users").child(appDelegate.phoneNumber!).child("first_name").setValue(first_name)
        ref.child("users").child(appDelegate.phoneNumber!).child("last_name").setValue(last_name)
        
        appDelegate.functions.httpsCallable("finishSignUp").call([
            "name": "\(first_name) \(last_name)",
            "phoneNumber": appDelegate.phoneNumber!
        ]) { (result, error) in
            if let error = error as NSError? {
                if error.domain == FunctionsErrorDomain {
                    let code = FunctionsErrorCode(rawValue: error.code)
                    let message = error.localizedDescription
                    let details = error.userInfo[FunctionsErrorDetailsKey]
                    let alert = UIAlertView()
                    alert.title = "Error"
                    alert.message = "code: \(code)\nmessage: \(message)\ndetails: \(details)"
                    alert.addButton(withTitle: "OK")
                    alert.show()
                }
            } else {
                print("got result")
                print(result!.data)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
}
