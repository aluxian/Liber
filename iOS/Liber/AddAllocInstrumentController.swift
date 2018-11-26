import UIKit

class AddAllocInstrumentController: UITableViewController {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var callback: ((String, Int) -> Void)?
    var instruments: [[String:AnyObject]] = [] // fields
    var pct_available: Int = 0
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return instruments.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reusedBasicCell", for: indexPath)
        
        cell.textLabel!.text = "\(instruments[indexPath.row]["name"] as! String) — \(instruments[indexPath.row]["ticker"] as! String)"
        cell.detailTextLabel!.text = "Risk \(instruments[indexPath.row]["risk"] as! Int)/10"
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if (pct_available == 0) {
            UIAlertView(title: "Oops", message: "You don't have enough cash. Adjust other allocations first.", delegate: nil, cancelButtonTitle: "OK").show()
            return
        }
        
        let alert = UIAlertController(title: instruments[indexPath.row]["name"] as! String, message: "What percentage of your deposits should be invested in \(instruments[indexPath.row]["ticker"] as! String)? Must be at least 1% and at most \(pct_available)%.", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.keyboardType = .numberPad
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { [weak alert] (_) in
            guard let inputText = alert!.textFields![0].text else { return }
            guard inputText.count > 0 else { return }
            let pct = Int(inputText)!
            guard pct > 0 else { return }
            guard pct <= self.pct_available else { return }
            self.callback!(self.instruments[indexPath.row]["ticker"] as! String, pct)
            self.navigationController?.popViewController(animated: true)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
}
