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
    
    func getServices(completionHandler: ([Service]) -> Void) {
        let url = NSURL(string: "http://anliegen.bonn.de/georeport/v2/services.json")
        let request = NSURLRequest(URL: url!, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData, timeoutInterval: 10)
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: { (response, data, error) -> Void in
            if error == nil {
                let services = self.parseServices(data)
                completionHandler(services)
            } else {
                println("Error: \(error.localizedDescription)")
            }
        })
    }
    
    func parseServices(data: NSData) -> [Service] {
        var output = [Service]()
        var error: NSError?
        let services = NSJSONSerialization.JSONObjectWithData(data, options: .MutableLeaves, error: &error) as! NSArray
        for s in services {
            if let sDict:NSDictionary = s as? NSDictionary {
                if let sCode = sDict["service_code"] as? String, sName = sDict["service_name"] as? String {
                    let service = Service(code: sCode, name: sName)
                    output.append(service)
                }
            }
        }
        return output
    }
    
    func getConcerns(completionHandler: ([Concern]) -> Void) {
        let url = NSURL(string: "http://anliegen.bonn.de/georeport/v2/requests.json")
        let request = NSURLRequest(URL: url!)
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: { (response, data, error) -> Void in
            let concerns = self.parseConcerns(data)
            completionHandler(concerns)
        })
    }
    
    func parseConcerns(data: NSData) -> [Concern] {
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
