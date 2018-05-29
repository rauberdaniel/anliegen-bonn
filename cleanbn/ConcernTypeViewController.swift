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
        
        services = ServiceManager.sharedManager.getServices()
        
        self.title = "general.service".localized
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        
        let name = services[indexPath.row].name
        cell.textLabel?.text = "\(name)"
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return services.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let addController = addController {
            addController.service = services[indexPath.row]
        }
        navigationController?.popViewController(animated: true)
    }
}
