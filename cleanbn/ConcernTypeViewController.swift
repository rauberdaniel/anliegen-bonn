//
//  ConcernTypeViewController.swift
//  cleanbn
//
//  Created by Daniel Rauber on 18.04.15.
//  Copyright (c) 2015 Daniel Rauber. All rights reserved.
//

import UIKit

class ConcernTypeViewController: UITableViewController {
    
    var services: [Service] = []
    var addController: AddViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        services = ServiceManager.sharedManager.services
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as! UITableViewCell
        
        let name = services[indexPath.row].name
        cell.textLabel?.text = "\(name)"
        
        return cell
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return services.count
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let addController = addController {
            addController.service = services[indexPath.row]
        }
        navigationController?.popViewControllerAnimated(true)
    }
}
