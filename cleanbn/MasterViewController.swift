//
//  MasterViewController.swift
//  cleanbn
//
//  Created by Daniel Rauber on 17.04.15.
//  Copyright (c) 2015 Daniel Rauber. All rights reserved.
//

import UIKit
import CoreLocation

class MasterViewController: UITableViewController {

    var objects = [Concern]()


    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        var refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "reloadData:", forControlEvents: .ValueChanged)
        self.refreshControl = refreshControl
        
        let addButton = self.navigationItem.rightBarButtonItem
        
        tableView.rowHeight = 60
        
        reloadData(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        if let selected = tableView.indexPathForSelectedRow() {
            tableView.deselectRowAtIndexPath(selected, animated: true)
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func insertNewObject(sender: AnyObject) {
        let concern = Concern()
        objects.insert(concern, atIndex: 0)
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }
    
    // MARK: - Data
    
    func reloadData(sender: AnyObject) {
        let url = NSURL(string: "http://anliegen.bonn.de/georeport/v2/requests.json?status=open")
        let request = NSURLRequest(URL: url!)
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) { (response, data, error) -> Void in
            let concerns = self.parseData(data)
            self.objects = concerns
            //self.objects = self.sortByDistance(concerns)
            self.tableView.reloadData()
            self.refreshControl?.endRefreshing()
        }
    }
    
    func sortByDistance(concerns:[Concern]) -> [Concern] {
        return concerns
    }
    
    func parseData(data: NSData) -> [Concern] {
        var output = [Concern]()
        var error: NSError?
        let concerns = NSJSONSerialization.JSONObjectWithData(data, options: .MutableLeaves, error: &error) as! NSArray
        for c in concerns {
            if let cDict:NSDictionary = c as? NSDictionary {
                let concern = Concern(fromDictionary: cDict)
                output.append(concern)
            }
        }
        return output
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow() {
                let object = objects[indexPath.row]
            (segue.destinationViewController as! DetailViewController).detailItem = object
            }
        }
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60.0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell

        let concern = objects[indexPath.row]
        cell.textLabel!.text = concern.title
        cell.detailTextLabel!.text = "\(NSDate.shortStringFromDate(concern.dateReported)) — \(concern.locationName)"
        
        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            objects.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }


}

