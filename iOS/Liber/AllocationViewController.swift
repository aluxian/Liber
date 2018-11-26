import UIKit
import Charts
import Firebase
class AllocationViewController: UITableViewController {

    @IBOutlet weak var pieChartView: PieChartView!
   
    @IBOutlet weak var diversif: UILabel!
    @IBOutlet weak var weightedRisk: UILabel!
    
    var allocation: [String:Int] = [:] // ticker -> pct
    var amounts: [String:Float] = [:] // ticker -> amount
    var instruments: [[String:AnyObject]] = [] // fields
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let ref = Database.database().reference()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let user = ref.child("users").child(appDelegate.phoneNumber!)
        
        user.child("allocation").observe(.value, with: { (snapshot) in
            if let v = snapshot.value as? [String:AnyObject] {
                self.allocation = v.mapValues({ $0 as! Int })
                self.reloadAllData()
            } else {
                print("!! no allocation data from firebase")
            }
        })
        
        user.child("amounts").observe(.value, with: { (snapshot) in
            if let v = snapshot.value as? [String:AnyObject] {
                self.amounts = v.mapValues({ $0 as! NSNumber }).mapValues({ $0.floatValue })
                self.reloadAllData()
            } else {
                print("!! no amounts data from firebase")
            }
        })
        
        ref.child("instruments").observe(.value, with: { (snapshot) in
            if let v = snapshot.value as? [[String:AnyObject]] {
                self.instruments = v
                self.reloadAllData()
            } else {
                print("!! no instruments data from firebase", snapshot.exists())
            }
        })
    }
    
    func reloadAllData() {
        self.tableView.reloadSections(IndexSet(arrayLiteral: 0), with: .automatic)
        self.updateChart()
        self.updateScores()
    }
    
    let COLORS: [String:UIColor] = [
        "Crypto": UIColor(hex: "#FFBF00"),
        "Commodity": UIColor(hex: "#4CAF50"),
        "Cash": UIColor(hex: "#69EBD0"),
        "Bond": UIColor(hex: "#C2E812")/*,
    UIColor(hex: "#ECBA82"),
    UIColor(hex: "#C49681"),
    UIColor(hex: "#C49BB5"),
    UIColor(hex: "#CFD186"),
    UIColor(hex: "#93ED8E"),
    UIColor(hex: "#BFC0C0")*/
    ]
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addAllocInstrument" {
            let vc = segue.destination as! AddAllocInstrumentController
            vc.pct_available = allocation["CASH_GBP"]!
            vc.instruments = instruments.filter({ (inst) -> Bool in !allocation.keys.contains(inst["ticker"] as! String) })
            vc.callback = { (new_ticker, new_pct) in
                let user = self.ref.child("users").child(self.appDelegate.phoneNumber!)
                
                user.child("allocation").child(new_ticker).setValue(new_pct)
                user.child("allocation").child("CASH_GBP").setValue(vc.pct_available - new_pct)
                
                // TODO: update amounts too
                
                // assuming we keep the amount in the ledger
                // get that value
//                var amount: Float = 0
                
                user.child("ledger").child("amount").observeSingleEvent(of: .value, with: { (snapshot) in
                    print("moving funds amounts")
                    
                    let amount = (snapshot.value as? NSNumber)?.floatValue ?? 0
                    print("amount=\(amount)")
                    
                    // get amount of the new ticker by taking the percentage from the avaliable money
                    let new_amount = Float(new_pct) * amount / 100
                    let cashgbp_amount = Float(vc.pct_available - new_pct) * amount / 100
                    
                    //set the new amounts
                    user.child("amounts").child(new_ticker).setValue(new_amount)
                    user.child("amounts").child("CASH_GBP").setValue(cashgbp_amount)
                })
                
                
                
//            let price = 1
//                let amount_CASH_GBP = self.amounts["CASH_GBP"] as! Float
//                user.child("amounts").child(new_ticker).setValue()
//                user.child("amounts").child("CASH_GBP").setValue()
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if instruments.count > 0 {
            return allocation.count
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "fancyInstrumentCard", for: indexPath) as! FancyInstrumentCell
        
        let (ticker, pct) = Array(allocation)[indexPath.row]
        let instrument = instruments.first { $0["ticker"] as! String == ticker }!
        
        cell.name.text = instrument["name"] as! String
        cell.cls.text = instrument["ticker"] as! String
        cell.risk.text = "Risk \(instrument["risk"] as! Int)/10     \(pct)%"
        cell.ticker.text = instrument["ticker"] as! String
        
        cell.card.layer.cornerRadius = 6.0
        cell.card.layer.shadowColor = UIColor(red:0.15, green:0.24, blue:0.35, alpha:1.00).cgColor
        cell.card.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        cell.card.layer.shadowRadius = 4.0
        cell.card.layer.shadowOpacity = 0.1
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return Array(allocation)[indexPath.row].key != "CASH_GBP"
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let user = self.ref.child("users").child(self.appDelegate.phoneNumber!)
        
            let (ticker, pct) = Array(allocation)[indexPath.row]
            
            user.child("allocation").child(ticker).removeValue()
            user.child("allocation").child("CASH_GBP").setValue(allocation["CASH_GBP"]! + pct)
            
            // TODO: update amounts
            
            // when we delete, it's easy - all the cash goes to GBP hihi
            
            // get previous GBP amount (everything that is left from the ledger and is not in any other allocation)
            
            // get the amount of the ticker
        
            
            //remove the ticker value and update the cash for GBP
            user.child("amounts").child(ticker).removeValue()
            user.child("amounts").child("CASH_GBP").setValue(amounts["CASH_GBP"]! + amounts[ticker]!)
            
        }
    }
    
    func updateChart() {
        if instruments.count == 0 {
            pieChartView.alpha = 0
            return
        } else {
            pieChartView.alpha = 1
        }
        
        var proportions: [String : Int] = [:]
        
        allocation.forEach { (key_ticker, value_pct) in
            let instrument = self.instruments.first { $0["ticker"] as! String == key_ticker }!
            let cls = instrument["cls"] as! String
            if proportions.keys.contains(cls) {
                proportions[cls] = proportions[cls]! + allocation[key_ticker]!
            } else {
                proportions[cls] = allocation[key_ticker]!
            }
        }
        
        var items: [PieChartDataEntry] = []
        
        proportions.keys.forEach { (key_class) in
            let v = Double(proportions[key_class]!)
            items.append(PieChartDataEntry(value: v, label: key_class))
        }
        
        let dataSet = PieChartDataSet(values: items, label: nil)
        dataSet.colors = Array(COLORS.values)
        
        pieChartView.legend.enabled = false
        pieChartView.chartDescription?.enabled = false
        pieChartView.rotationEnabled = false
        pieChartView.highlightPerTapEnabled = false
        pieChartView.data = PieChartData(dataSet: dataSet)
        
        let pFormatter = NumberFormatter()
        pFormatter.numberStyle = .percent
        pFormatter.maximumFractionDigits = 0
        pFormatter.multiplier = 1
        pFormatter.percentSymbol = "%"
        pieChartView.data!.setValueFormatter(DefaultValueFormatter(formatter: pFormatter))
        pieChartView.data!.setValueFont(.systemFont(ofSize: 10, weight: .regular))
        pieChartView.data!.setValueTextColor(.white)
        
        pieChartView.noDataText = ""
        pieChartView.noDataTextColor = UIColor.clear
        pieChartView.animate(xAxisDuration: 1, yAxisDuration: 1, easingOption: .easeInOutQuart)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateScores()
        self.updateChart()
    }
    
    func updateScores() {
        if instruments.count == 0 {
            weightedRisk.text = ""
            diversif.text = ""
            return
        }
        
        if (allocation.count > 0 && allocation.count <= 3) {
            diversif.text = "Poor"
            diversif.textColor = UIColor.red
        }
        
        if (allocation.count > 3 && allocation.count <= 6) {
            diversif.text = "Good"
            diversif.textColor = UIColor.orange
        }
        
        if (allocation.count > 6) {
            diversif.text = "Great"
            diversif.textColor = UIColor.green
        }
        
        var weighted_avg: Int = 0
        var total_risk: Int = 0
        
        allocation.forEach { (ticker, pct) in
            let instrument = instruments.first { $0["ticker"] as! String == ticker }!
            total_risk += (instrument["risk"] as! Int) * pct
        }
        
        weighted_avg = Int(round(Float(total_risk) / 100))
        if (weighted_avg <= 3) {
            weightedRisk.text = "\(weighted_avg)/10 — Low Risk"
            weightedRisk.textColor = UIColor.green
        } else if (weighted_avg <= 6) {
            weightedRisk.text = "\(weighted_avg)/10 — Medium Risk"
            weightedRisk.textColor = UIColor.orange
        } else {
            weightedRisk.text = "\(weighted_avg)/10 — High Risk"
            weightedRisk.textColor = UIColor.red
        }
    }

}




extension UIColor {
    convenience init(hex: String) {
        var cString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if (cString.count != 6) {
            self.init(
                red: 1.0,
                green: 1.0,
                blue: 1.0,
                alpha: 0.5
            )
        } else {
            var rgbValue: UInt32 = 0
            Scanner(string: cString).scanHexInt32(&rgbValue)
            
            self.init(
                red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
                blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
                alpha: CGFloat(1.0)
            )
        }
    }
}



extension UIView {
    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}
