//
//  ProfileCtrl.swift
//  Liber
//
//  Created by Alexandru Rosianu on 24/11/2018.
//  Copyright © 2018 Liber. All rights reserved.
//

import UIKit
import Firebase
import Charts

struct Transaction {
    var descr: String
    var amount: Int
    var dt: Date
}

class PortfolioCtrl: UITableViewController {
    
    
    @IBOutlet weak var total1: UILabel!
    
    @IBOutlet weak var chartView: LineChartView!
    @IBOutlet weak var total2: UILabel!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let ref = Database.database().reference()
    var transactions: [Transaction] = []
    
    @IBAction func onWithdrawClicked(_ sender: Any) {
        let alert = UIAlertController(title: "Withdraw", message: "How much would you like to withdraw?", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "2"
            textField.keyboardType = .decimalPad
        }
        
        print(UserDefaults.standard.string(forKey: "logged_in_phone_number"))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Withdraw", style: .default, handler: { [weak alert] (_) in
            guard let inputText = alert!.textFields![0].text else { return }
            guard inputText.count > 0 else { return }
            let amount = Float(inputText)!
            
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencySymbol = ""
            print(formatter.string(from: NSNumber(value: amount))!)
            
            self.appDelegate.functions.httpsCallable("withdraw").call([
                "name": "Alexandru Rosianu",
                "sortcode": "040004",
                "accno": "24536754",
                "phoneNumber": self.appDelegate.phoneNumber!,
                "amount": formatter.string(from: NSNumber(value: amount))!
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
                    
                    UIAlertView(title: "Success!", message: "Your transfer will be processed in a few minutes 🥰", delegate: nil, cancelButtonTitle: "OK").show()
                }
            }
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    var ledger_amount: Float = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone.autoupdatingCurrent
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        ref.child("users").child(appDelegate.phoneNumber!).child("ledger/amount")
            .observe(.value, with: { (snapshot) in
                if let v = snapshot.value as? NSNumber {
                    print("we ledger_amount")
                    print(self.ledger_amount)
                    self.ledger_amount = v.floatValue
                } else {
                    print("no v")
                    print(snapshot.value)
                }
            })
        
        ref.child("users").child(appDelegate.phoneNumber!).child("valuation_chart")
            .observe(.value, with: { (snapshot) in
                if let v = snapshot.value as? [String:AnyObject] {
                    print("we have v!!!!!")
                    let my_data = Array(v.values).map{ $0 as! [String:AnyObject] }
                        .sorted(by: { ($0["timestamp"] as! NSNumber).doubleValue < ($1["timestamp"] as! NSNumber).doubleValue })
                    self.updateLineChart(data: my_data)
                    if let most_updated = my_data.last {
                        let formatter = NumberFormatter()
                        formatter.numberStyle = .currency
                        formatter.maximumFractionDigits = 6
                        formatter.minimumFractionDigits = 6
                        print(most_updated["value"] as! NSNumber)
                        print(most_updated["timestamp"])
                        self.total1.text = formatter.string(from: most_updated["value"] as! NSNumber)!
                        let curr_dbl = (most_updated["value"] as! NSNumber).floatValue
                        let chg = (curr_dbl - self.ledger_amount) / self.ledger_amount
                        
                        let formatter2 = NumberFormatter()
                        formatter2.numberStyle = .percent
                        formatter2.positivePrefix = "+"
                        formatter2.negativePrefix = "-"
                        formatter2.maximumFractionDigits = 2
                        formatter2.minimumFractionDigits = 2
                        self.total2.text = formatter2.string(from: NSNumber(value: chg))
                        
                        if chg < 0 {
                            self.total1.textColor = UIColor.red
                            self.total2.textColor = UIColor.red
                        } else {
                            self.total1.textColor = UIColor.green
                            self.total2.textColor = UIColor.green
                        }
                    }
                    //print(my_data)
                } else {
                    print("no v")
                    print(snapshot.value)
                }
//                self.transactions = []
//                if let v = snapshot.value as? [[String:AnyObject]] {
//                    v.forEach { tx in
//                        if tx["transaction_type"] as! String == "transaction-type-receive" {
//                            let amount = Int(Float(tx["amount"]!.description)! * 100)
//                            self.transactions.insert(Transaction(descr: "Deposit", amount: amount,
//                                                                 dt: dateFormatter.date(from: tx["created_at"] as! String)!), at: 0)
//                        }
//
//                        if tx["transaction_type"] as! String == "transaction-type-send" {
//                            let amount = Int(Float(tx["amount"]!.description)! * 100)
//                            self.transactions.insert(Transaction(descr: "Withdrawal", amount: -amount,
//                                                                 dt: dateFormatter.date(from: tx["created_at"] as! String)!), at: 0)
//                        }
//                    }
//                    self.tableView.reloadSections(IndexSet(arrayLiteral: 0), with: .automatic)
//                    //                    self.updateLineChart()
//                    self.updateTotal()
//                }
            })
        
        ref.child("users").child(appDelegate.phoneNumber!).child("transactions")
            .observe(.value, with: { (snapshot) in
                self.transactions = []
                if let v = snapshot.value as? [[String:AnyObject]] {
                    v.forEach { tx in
                        if tx["transaction_type"] as! String == "transaction-type-receive" {
                            let amount = Int(Float(tx["amount"]!.description)! * 100)
                            self.transactions.insert(Transaction(descr: "Deposit", amount: amount,
                                                                 dt: dateFormatter.date(from: tx["created_at"] as! String)!), at: 0)
                        }
                        
                        if tx["transaction_type"] as! String == "transaction-type-send" {
                            let amount = Int(Float(tx["amount"]!.description)! * 100)
                            self.transactions.insert(Transaction(descr: "Withdrawal", amount: -amount,
                                                                 dt: dateFormatter.date(from: tx["created_at"] as! String)!), at: 0)
                        }
                    }
                    self.tableView.reloadSections(IndexSet(arrayLiteral: 0), with: .automatic)
//                    self.updateLineChart()
//                    self.updateTotal()
                }
            })
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactions.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "fancyTransactionCard", for: indexPath) as! FancyTransactionCell
        
        let tx = transactions[indexPath.row]
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone.autoupdatingCurrent
        dateFormatter.dateFormat = "d MMM yyyy 'at' HH:mm"
        
        cell.descr.text = tx.descr
        cell.amount.text = "£\(Float(tx.amount) / 100)"
        cell.date.text = dateFormatter.string(from: tx.dt)
        
        if tx.amount > 0 {
            cell.amount.textColor = UIColor.green
        } else {
            cell.amount.textColor = UIColor.red
        }

        cell.card.layer.cornerRadius = 6.0
        cell.card.layer.shadowColor = UIColor(red:0.15, green:0.24, blue:0.35, alpha:1.00).cgColor
        cell.card.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        cell.card.layer.shadowRadius = 4.0
        cell.card.layer.shadowOpacity = 0.1
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return nil
    }
    
    func updateLineChart(data: [[String:AnyObject]]) {
        var i = -1
        
        let yVals1 = data.suffix(150).map { (orig_datapoint) -> ChartDataEntry in
            let val = (orig_datapoint["value"] as! NSNumber).doubleValue
            i = i + 1
            return ChartDataEntry(x: Double(i), y: val)
        }
        
        chartView.legend.enabled = false
        chartView.drawBordersEnabled = false
        chartView.chartDescription?.enabled = false
        
        chartView.rightAxis.enabled = false
        chartView.xAxis.drawGridLinesEnabled = false
        
        chartView.xAxis.gridColor = UIColor.clear
        chartView.xAxis.axisLineColor = UIColor.clear
        
        chartView.leftAxis.gridColor = UIColor.clear
        chartView.leftAxis.axisLineColor = UIColor.clear
        
        let leftAxis = chartView.leftAxis
        leftAxis.enabled = true
        leftAxis.labelFont = .systemFont(ofSize: 12, weight: .light)
        leftAxis.drawLabelsEnabled = true
        leftAxis.drawGridLinesEnabled = false
        leftAxis.granularityEnabled = true
//        leftAxis.axisMinimum = 0
//        leftAxis.axisMaximum = 170
        leftAxis.yOffset = -9
        leftAxis.labelTextColor = UIColor.gray

        chartView.xAxis.drawLabelsEnabled = false
        
        let set1 = LineChartDataSet(values: yVals1, label: nil)
        
        set1.axisDependency = .left
        set1.setColor(UIColor(red: 51/255, green: 181/255, blue: 229/255, alpha: 1))
        set1.lineWidth = 1.5
        set1.drawCirclesEnabled = false
        set1.drawValuesEnabled = false
        set1.fillAlpha = 0.26
        set1.fillColor = UIColor(red: 51/255, green: 181/255, blue: 229/255, alpha: 1)
        set1.highlightColor = UIColor(red: 244/255, green: 117/255, blue: 117/255, alpha: 1)
        set1.drawCircleHoleEnabled = false
        set1.mode = .cubicBezier
        set1.drawFilledEnabled = true
        
        let data = LineChartData(dataSet: set1)
        
        chartView.data = data
        
//        chartView.animate(xAxisDuration: 0.5)
    
    }
    
//    func updateTotal() {
//        return
//        var totalGBP: Int = 0
//
//        transactions.forEach { (tx) in
//            totalGBP += tx.amount
//        }
//
//        total1.text = "£\(Float(totalGBP) / 100)"
//
//        //total2
//
//        //get instruments from AllocationViewController
//        var instruments: [[String:AnyObject]] = [] // fields
//        //
//
//        instruments.forEach { (inst) in
//
//        }
//    }
    
}
