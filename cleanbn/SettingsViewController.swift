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
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "submit:")
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "close:")
        tableView.rowHeight = 60
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - View Controls
    
    func submit(sender: AnyObject) {
        var success: Bool = false
        if let mailCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) {
            if let mailField = mailCell.viewWithTag(2) as? UITextField {
                if isValidEmail(mailField.text) {
                    NSUserDefaults.standardUserDefaults().setObject(mailField.text, forKey: "email")
                    NSUserDefaults.standardUserDefaults().synchronize()
                    success = true
                    self.dismissViewControllerAnimated(true, completion: nil)
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
    
    // MARK: - Validation
    
    func isValidEmail(testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluateWithObject(testStr)
    }
    
    // MARK: - TableViewController
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MailCell") as! UITableViewCell
        
        if let mail = NSUserDefaults.standardUserDefaults().objectForKey("email") as? String {
            (cell.viewWithTag(2) as! UITextField).text = mail
        }
        
        return cell
    }
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
}
