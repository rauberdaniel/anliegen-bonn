//
//  ApiHandler.swift
//  cleanbn
//
//  Created by Daniel Rauber on 18.04.15.
//  Copyright (c) 2015 Daniel Rauber. All rights reserved.
//

import Foundation

private let _ApiHandlerInstance = ApiHandler()

class ApiHandler: NSObject {
    class var sharedHandler: ApiHandler {
        return _ApiHandlerInstance
    }
    
    func getConcerns(completionHandler: ([Concern]) -> Void) {
        let url = NSURL(string: "http://anliegen.bonn.de/georeport/v2/requests.json")
        let request = NSURLRequest(URL: url!)
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: { (response, data, error) -> Void in
            let concerns = self.parseData(data)
            completionHandler(concerns)
        })
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
    
    func submitConcern(concern: Concern, completionHandler: (response: NSURLResponse!, data: NSData!, error: NSError!) -> Void) {
        let url = NSURL(string: "http://cleanbn.danielrauber.de/submit.php")
        
        let data = concern.getJSONData()
        
        if let data = data {
            var request = NSMutableURLRequest(URL: url!)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.HTTPMethod = "POST"
            request.HTTPBody = data
            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: completionHandler)
        } else {
            println("No Concern given")
        }
    }
}
