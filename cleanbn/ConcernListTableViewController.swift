//
//  ConcernListTableViewController.swift
//  cleanbn
//
//  Created by Daniel Rauber on 15.06.15.
//  Copyright (c) 2015 Daniel Rauber. All rights reserved.
//

import UIKit

class ConcernListTableViewController: UITableViewController {
    
    var concerns: [Concern]? = nil
    var ownConcerns: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "close:")

        self.tableView.rowHeight = 60
        
        if let requestsSent = NSUserDefaults.standardUserDefaults().arrayForKey("requestsSent") as? [String] {
            ownConcerns = requestsSent
        }
        
        ApiHandler.sharedHandler.getConcerns { (concerns) -> Void in
            print("ConcernList :: ReceivedConcerns :: \(concerns.count)")
            self.concerns = concerns
            self.tableView.reloadData()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation
    
    func close(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        if let concerns = concerns {
            tableView.backgroundView = nil
            tableView.separatorStyle = .SingleLine
            
            return concerns.count
        }
        
        let backgroundLabel = UILabel(frame: tableView.frame)
        backgroundLabel.text = "Anliegen werden geladen"
        backgroundLabel.textAlignment = .Center
        backgroundLabel.textColor = UIColor(white: 0, alpha: 0.2)
        tableView.backgroundView = UIView(frame: tableView.frame)
        tableView.backgroundView?.addSubview(backgroundLabel)
        tableView.separatorStyle = .None
        
        return 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ConcernCell", forIndexPath: indexPath) 

        // Configure the cell...
        if let concerns = concerns {
            let concern = concerns[indexPath.row]
            if let id = concern.id, date = concern.dateReported {
                if ownConcerns.contains(id) {
                    // this request was sent by the user
                    cell.imageView?.backgroundColor = UIColor(white: 0.9, alpha: 1)
                } else {
                    cell.imageView?.backgroundColor = nil
                }
                let shortDateString = NSDate.shortStringFromDate(date)
                cell.textLabel?.text = "\(id) – \(concern.service.name)"
                var detailString = "\(shortDateString)"
                if let locationName = concern.locationName {
                    detailString = "\(detailString) — \(locationName)"
                }
                cell.detailTextLabel?.text = detailString
            } else {
                if let id = concern.id {
                    cell.detailTextLabel?.text = "\(id)"
                } else {
                    cell.detailTextLabel?.text = "Unbekanntes Anliegen"
                }
            }
            cell.imageView?.image = UIImage(named: "StateOpen")
            if concern.state == "closed" {
                cell.imageView?.image = UIImage(named: "StateClosed")
            }
        }

        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
