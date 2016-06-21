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
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(SettingsViewController.submit(_:)))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: #selector(SettingsViewController.close(_:)))
        tableView.rowHeight = 60
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - View Controls
    
    func submit(sender: AnyObject) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        var success: Bool = false
        if let mailCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) {
            if let mailField = mailCell.viewWithTag(2) as? UITextField, mailFieldText = mailField.text {
                if ValidationHandler.isValidEmail(mailFieldText) {
                    userDefaults.setObject(mailField.text, forKey: "email")
                    success = true
                    
                    if userDefaults.boolForKey("termsAccepted") {
                        self.dismissViewControllerAnimated(true, completion: nil)
                    } else {
                        let termsAlert = UIAlertController(title: "Nutzungsbedingungen", message: "Hiermit stimmst du zu, dass du die Nutzungsregeln und Datenschutzhinweise gelesen hast und diese akzeptierst.", preferredStyle: .Alert)
                        let confirmAction = UIAlertAction(title: "Zustimmen", style: .Default, handler: { (action) -> Void in
                            userDefaults.setBool(true, forKey: "termsAccepted")
                            userDefaults.synchronize()
                            self.dismissViewControllerAnimated(true, completion: nil)
                        })
                        termsAlert.addAction(confirmAction)
                        let cancelAction = UIAlertAction(title: "Abbrechen", style: .Cancel, handler: nil)
                        termsAlert.addAction(cancelAction)
                        self.presentViewController(termsAlert, animated: true, completion: nil)
                    }
                }
            }
        }
        if !success {
            let alert = UIAlertController(title: "Ungültige Adresse", message: "Die angegebene Adresse ist keine gültige E-Mail Adresse.", preferredStyle: .Alert)
            let closeAction = UIAlertAction(title: "Ok", style: .Cancel, handler: nil)
            alert.addAction(closeAction)
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func close(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - TableViewController
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 2
        default:
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("MailCell")!
            
            if let mail = NSUserDefaults.standardUserDefaults().stringForKey("email") {
                (cell.viewWithTag(2) as! UITextField).text = mail
            }
            return cell
        }
        
        let cell = tableView.dequeueReusableCellWithIdentifier("TermsCell")!
        
        if indexPath.row == 0 {
            cell.textLabel?.text = "Datenschutzhinweise"
        } else {
            cell.textLabel?.text = "Nutzungsregeln"
        }
    
        return cell
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "E-Mail Adresse"
        case 1:
            return "Datenschutz & Nutzungsregeln"
        default:
            return ""
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 1 {
            if indexPath.row == 0 {
                
            }
        }
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showTerms" {
            if let dest = segue.destinationViewController as? TermsViewController {
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
