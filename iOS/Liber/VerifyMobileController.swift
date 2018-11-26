//
//  SecondViewController.swift
//  Liber
//
//  Created by Alexandru Rosianu on 24/11/2018.
//  Copyright © 2018 Liber. All rights reserved.
//

import UIKit
import Firebase

class VerifyMobileController: UIViewController {
    
    var isFinished: Bool = false

    @IBOutlet weak var mobileNumberTextField: UITextField!
    
    @IBAction func onGetCodeClicked(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.phoneNumber = self.mobileNumberTextField.text!.replacingOccurrences(of: " ", with: "")
        appDelegate.functions.httpsCallable("sendMobileCode").call([
            "countryCode": "44",
            "phoneNumber": appDelegate.phoneNumber
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
                // ...
            } else {
                print("got result")
                print(result!.data)
                self.isFinished = true
                self.performSegue(withIdentifier: "showCodeVerif", sender: self)
            }
            //            if let error = error as NSError? {
            //                fatalError(error.localizedDescription)
            //            }
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return isFinished
    }


}

