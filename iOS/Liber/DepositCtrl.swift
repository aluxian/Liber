import UIKit
import Firebase

class DepositCtrl: UIViewController {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let ref = Database.database().reference()
    
    @IBOutlet weak var sortcode: UILabel!
    @IBOutlet weak var accno: UILabel!
    @IBOutlet weak var benef: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref.child("users").child(appDelegate.phoneNumber!).child("ledger").child("uk_sort_code")
            .observe(.value, with: { (snapshot) in
                self.sortcode.text = snapshot.value as? String
                self.sortcode.alpha = 1
            })
        
        ref.child("users").child(appDelegate.phoneNumber!).child("ledger").child("uk_account_number")
            .observe(.value, with: { (snapshot) in
                self.accno.text = snapshot.value as? String
                self.accno.alpha = 1
            })
        
        ref.child("users").child(appDelegate.phoneNumber!).child("ledger/ledger_holder/person/name")
            .observe(.value, with: { (snapshot) in
                self.benef.text = snapshot.value as? String
                self.benef.alpha = 1
            })
    }
    
}
