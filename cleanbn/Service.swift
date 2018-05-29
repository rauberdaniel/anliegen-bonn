//
//  Service.swift
//  cleanbn
//
//  Created by Daniel Rauber on 18.04.15.
//  Copyright (c) 2015 Daniel Rauber. All rights reserved.
//

import Foundation

class Service: NSObject, NSCoding {

    let code: String
    let name: String
    
    init(code: String, name: String) {
        self.code = code
        self.name = name
    }
    
    required init?(coder aDecoder: NSCoder) {
        let dict = aDecoder.decodeObject(forKey: "service") as! [String:String]
        self.code = dict["code"]!
        self.name = dict["name"]!
    }
    
    override var description: String {
        return "Service (\(code) | \(name))"
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(["code":code,"name":name], forKey: "service")
        
    }
    
}
