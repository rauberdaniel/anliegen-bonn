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
    
    var services: [Service] {
        get {
            return getServices()
        }
    }
    
    override init() {
        super.init()
        
        /*
        let types: [[String: String]] = [
            ["id":"0001", "name":"Ampel defekt"],
            ["id":"0002", "name":"Glassplitter"],
            ["id":"0006", "name":"Grünüberwuchs Verkehrsraum"],
            ["id":"0009", "name":"Herrenlose Fahrräder, Fahrzeuge (Schrott)"],
            ["id":"0010", "name":"Wilde Müllkippe, Sperrmüllreste"],
            ["id":"0021", "name":"Graffiti"],
        ]
        
        for type in types {
            if let name = type["name"], id = type["id"] {
                services.append(Service(code: id, name: name))
            }
        }
        */
        
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
        println("updateServices");
        ApiHandler.sharedHandler.getServices { (services) -> Void in
            let data = NSKeyedArchiver.archivedDataWithRootObject(services)
            NSUserDefaults.standardUserDefaults().setObject(data, forKey: "services")
            println("ServiceManager :: Services updated")
        }
    }
}
