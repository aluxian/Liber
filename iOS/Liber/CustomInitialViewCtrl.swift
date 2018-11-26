import UIKit

class CustomInitialViewCtrl: UINavigationController {
  
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("""
UserDefaults.standard.bool(forKey: "is_logged_in")
""")
        print(UserDefaults.standard.bool(forKey: "is_logged_in"))
        
        if UserDefaults.standard.bool(forKey: "is_logged_in") {
            performSegue(withIdentifier: "skipLogin", sender: nil)
        }
    }

}
