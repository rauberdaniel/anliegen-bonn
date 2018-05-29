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
        if let data = UserDefaults.standard.object(forKey: "services") as? Data {
            if let services = NSKeyedUnarchiver.unarchiveObject(with: data) as? [Service] {
                return services
            }
        }
        return []
    }
    
    func updateServices() {
        print("ServiceManager :: Updating");
        ApiHandler.sharedHandler.getServices { (services) -> Void in
            let data = NSKeyedArchiver.archivedData(withRootObject: services)
            UserDefaults.standard.set(data, forKey: "services")
            print("ServiceManager :: Updated")
        }
    }
}
