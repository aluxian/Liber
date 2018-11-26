import UIKit
import AimBrainSDK

class FaceVerifController: UIViewController {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBAction func onStartClicked(_ sender: Any) {
        AMBNManager.sharedInstance().openFaceImagesCapture(
            withTopHint: "To authenticate please face the camera directly and press 'camera' button",
            bottomHint: "Position your face fully within the outline with eyes between the lines.",
            batchSize: 1,
            delay: 0,
            from: self) { (images, error) in
                if error == nil {
                    print("face verif success")
                    self.performSegue(withIdentifier: "finishFaceVerif", sender: self)
                } else {
                    UIAlertView(title: "Error", message: error!.localizedDescription, delegate: nil, cancelButtonTitle: "OK")
                }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        AMBNManager.sharedInstance().createSession(withUserId: appDelegate.phoneNumber) { (result, error) in
//            if result != nil {
//                print("successfully created session")
//                print(result)
//            } else {
//                UIAlertView(title: "Error", message: error!.localizedDescription, delegate: nil, cancelButtonTitle: "OK")
//            }
//        }
    }
    
}
