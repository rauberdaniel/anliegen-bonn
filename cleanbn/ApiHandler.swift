//
//  ApiHandler.swift
//  cleanbn
//
//  Created by Daniel Rauber on 18.04.15.
//  Copyright (c) 2015 Daniel Rauber. All rights reserved.
//

import Foundation
import UIKit

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
    
    func submitConcern(concern: Concern, sender: AddViewController) {
        
        let progressAlert = UIAlertController(title: "Anliegen wird übermittelt…", message: "Bitte hab einen Moment Geduld, während dein Anliegen übermittelt wird.", preferredStyle: .Alert)
        sender.presentViewController(progressAlert, animated: true, completion: nil)
        
        let closeAction = UIAlertAction(title: "Ok", style: .Cancel, handler: nil)
        
        uploadImage(concern, completionHandler: { (imageUrl) -> Void in
            concern.imageUrl = imageUrl
            self.submitConcernForm(concern, completionHandler: { (response, data, error) -> Void in
                if error != nil {
                    println("ApiHandler :: SubmitConcernForm :: Error :: \(NSString(data: data, encoding: NSUTF8StringEncoding))")
                    sender.sendButton.enabled = true
                    let errorAlert = UIAlertController(title: "Fehler", message: "Dein Anliegen konnte nicht übermittelt werden. Bitte verbinde dich mit dem Internet, um dein Anliegen zu senden.", preferredStyle: .Alert)
                    errorAlert.addAction(closeAction)
                    progressAlert.dismissViewControllerAnimated(true, completion: { () -> Void in
                        sender.presentViewController(errorAlert, animated: true, completion: nil)
                    })
                    return
                }
                let successAlert = UIAlertController(title: "Anliegen übermittelt", message: "Dein Anliegen wurde erfolgreich übermittelt und wird zeitnah bearbeitet.", preferredStyle: UIAlertControllerStyle.Alert)
                let closeAndBackAction = UIAlertAction(title: "Ok", style: .Cancel, handler: { (action) -> Void in
                    sender.navigationController?.popViewControllerAnimated(true)
                })
                successAlert.addAction(closeAndBackAction)
                progressAlert.dismissViewControllerAnimated(true, completion: { () -> Void in
                    sender.presentViewController(successAlert, animated: true, completion: nil)
                })
            })
        })
    }
    
    func submitConcernForm(concern: Concern, completionHandler: (response: NSURLResponse!, data: NSData!, error: NSError!) -> Void) {
        let url = NSURL(string: "http://anliegen.bonn.de/georeport/v2/requests.json")
        
        var formString = concern.getFormString()
        
        if let formString = formString {
            let dataString = AuthenticationHandler.sharedHandler.getAuthenticatedDataString(formString)
            let data = dataString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
            if let data = data {
                var request = NSMutableURLRequest(URL: url!)
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                request.setValue("\(data.length)", forHTTPHeaderField: "Content-Length")
                request.HTTPMethod = "POST"
                request.HTTPBody = data
                NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: completionHandler)
            } else {
                println("ApiHandler :: Data Encoding failed")
            }
        } else {
            println("ApiHandler :: No FormString given")
        }
    }
    
    func uploadImage(concern: Concern, completionHandler: (imageUrl: NSURL?) -> Void) {
        let url = NSURL(string: "http://cleanbn.danielrauber.de/image.php")
        if let imageData = concern.getImageData() {
            let base64ImageString = imageData.base64EncodedStringWithOptions(.allZeros)
            let base64ImageData = base64ImageString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
            // Create and Send Request, call completionhandler with returned url
            var request = NSMutableURLRequest(URL: url!)
            request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
            request.setValue("\(base64ImageData?.length)", forHTTPHeaderField: "Content-Length")
            request.HTTPMethod = "POST"
            request.HTTPBody = base64ImageData
            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: { (response, data, error) -> Void in
                if let imageUrlString = NSString(data: data, encoding: NSUTF8StringEncoding) as? String, imageUrl = NSURL(string: imageUrlString) {
                    println("ApiHandler :: Image uploaded :: \(imageUrl)")
                    completionHandler(imageUrl: imageUrl)
                } else {
                    println("ApiHandler :: Image upload failed :: \(error.localizedDescription)")
                }
            })
        } else {
            completionHandler(imageUrl: nil)
        }
    }
}
