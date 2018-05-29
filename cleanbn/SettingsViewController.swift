//
//  SettingsViewController.swift
//  cleanbn
//
//  Created by Daniel Rauber on 11.05.15.
//  Copyright (c) 2015 Daniel Rauber. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(SettingsViewController.submit(_:)))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(SettingsViewController.close(_:)))
        tableView.rowHeight = 60
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - View Controls
    
    @objc func submit(_ sender: AnyObject) {
        let userDefaults = UserDefaults.standard
        var success: Bool = false
        if let mailCell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) {
            if let mailField = mailCell.viewWithTag(2) as? UITextField, let mailFieldText = mailField.text {
                if ValidationHandler.isValidEmail(mailFieldText) {
                    userDefaults.set(mailField.text, forKey: "email")
                    success = true
                    
                    if userDefaults.bool(forKey: "termsAccepted") {
                        self.dismiss(animated: true, completion: nil)
                    } else {
                        let termsAlert = UIAlertController(title: "Nutzungsbedingungen", message: "Hiermit stimmst du zu, dass du die Nutzungsregeln und Datenschutzhinweise gelesen hast und diese akzeptierst.", preferredStyle: .alert)
                        let confirmAction = UIAlertAction(title: "Zustimmen", style: .default, handler: { (action) -> Void in
                            userDefaults.set(true, forKey: "termsAccepted")
                            userDefaults.synchronize()
                            self.dismiss(animated: true, completion: nil)
                        })
                        termsAlert.addAction(confirmAction)
                        let cancelAction = UIAlertAction(title: "Abbrechen", style: .cancel, handler: nil)
                        termsAlert.addAction(cancelAction)
                        self.present(termsAlert, animated: true, completion: nil)
                    }
                }
            }
        }
        if !success {
            let alert = UIAlertController(title: "Ungültige Adresse", message: "Die angegebene Adresse ist keine gültige E-Mail Adresse.", preferredStyle: .alert)
            let closeAction = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
            alert.addAction(closeAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @objc func close(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - TableViewController
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 2
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MailCell")!
            
            if let mail = UserDefaults.standard.string(forKey: "email") {
                (cell.viewWithTag(2) as! UITextField).text = mail
            }
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TermsCell")!
        
        if indexPath.row == 0 {
            cell.textLabel?.text = "Datenschutzhinweise"
        } else {
            cell.textLabel?.text = "Nutzungsregeln"
        }
    
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "E-Mail Adresse"
        case 1:
            return "Datenschutz & Nutzungsregeln"
        default:
            return ""
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            if indexPath.row == 0 {
                
            }
        }
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showTerms" {
            if let dest = segue.destination as? TermsViewController {
                if tableView.indexPathForSelectedRow?.row == 0 {
                    dest.type = "privacy"
                }
                if tableView.indexPathForSelectedRow?.row == 1 {
                    dest.type = "rules"
                }
            }
        }
    }
    
}
