//
//  ServiceManager.swift
//  cleanbn
//
//  Created by Daniel Rauber on 18.04.15.
//  Copyright (c) 2015 Daniel Rauber. All rights reserved.
//

import Foundation

private let _ServiceManagerInstance = ServiceManager()

class ServiceManager: NSObject {
    class var sharedManager: ServiceManager {
        return _ServiceManagerInstance
    }
    
    override init() {
        super.init()
        updateServices()
    }
    
    func getServices() -> [Service] {
        if let data = NSUserDefaults.standardUserDefaults().objectForKey("services") as? NSData {
            if let services = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [Service] {
                return services
            }
        }
        return []
    }
    
    func updateServices() {
        println("ServiceManager :: Updating");
        ApiHandler.sharedHandler.getServices { (services) -> Void in
            let data = NSKeyedArchiver.archivedDataWithRootObject(services)
            NSUserDefaults.standardUserDefaults().setObject(data, forKey: "services")
            println("ServiceManager :: Updated")
        }
    }
}
