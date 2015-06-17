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
    
    let baseUrl = "http://anliegen.bonn.de/georeport/v2/"
    let imageUrl = "http://cleanbn.danielrauber.de/image.php"
    
    class var sharedHandler: ApiHandler {
        return _ApiHandlerInstance
    }
    
    func getServices(completionHandler: ([Service]) -> Void) {
        let url = NSURL(string: baseUrl+"services.json")
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
        let url = NSURL(string: baseUrl+"requests.json")
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
    
    /**
        Submits a concern by uploading a potential image and sending the concern data to the API
    */
    func submitConcern(concern: Concern, sender: AddViewController) {
        let progressAlert = UIAlertController(title: "Anliegen wird übermittelt…", message: "Bitte hab einen Moment Geduld, während dein Anliegen übermittelt wird.", preferredStyle: .Alert)
        sender.presentViewController(progressAlert, animated: true, completion: nil)
        
        let closeAction = UIAlertAction(title: "Ok", style: .Cancel, handler: nil)
        
        uploadImage(concern, sender: sender, completionHandler: { (imageUrl) -> Void in
            concern.imageUrl = imageUrl
            self.submitConcernForm(concern, completionHandler: { (data, response, error) -> Void in
                if error == nil {
                    var jsonError: NSErrorPointer = nil
                    if let jsonData = NSJSONSerialization.JSONObjectWithData(data, options: .MutableLeaves, error: jsonError) as? Array<AnyObject>, jsonDict = jsonData[0] as? Dictionary<String,String>, requestID = jsonDict["service_request_id"] {
                        // requestID like "A-4523"
                        NSUserDefaults.standardUserDefaults().mutableArrayValueForKey("requestsSent").addObject(requestID)
                        println("ApiHandler :: SubmitConcernForm :: Submitted :: \(requestID)")
                        
                        let successAlert = UIAlertController(title: "Anliegen übermittelt", message: "Dein Anliegen wurde erfolgreich übermittelt und wird zeitnah bearbeitet.", preferredStyle: UIAlertControllerStyle.Alert)
                        let closeAndBackAction = UIAlertAction(title: "Ok", style: .Cancel, handler: { (action) -> Void in
                            sender.navigationController?.popViewControllerAnimated(true)
                        })
                        successAlert.addAction(closeAndBackAction)
                        progressAlert.dismissViewControllerAnimated(true, completion: { () -> Void in
                            sender.presentViewController(successAlert, animated: true, completion: nil)
                        })
                    }
                } else {
                    // Connection Error
                    println("ApiHandler :: SubmitConcernForm :: Error :: \(error.localizedDescription) :: \(NSString(data: data, encoding: NSUTF8StringEncoding))")
                    sender.sendButton.enabled = true
                    let errorAlert = UIAlertController(title: "Fehler", message: "Dein Anliegen konnte nicht übermittelt werden. Bitte verbinde dich mit dem Internet, um dein Anliegen zu senden.", preferredStyle: .Alert)
                    errorAlert.addAction(closeAction)
                    progressAlert.dismissViewControllerAnimated(true, completion: { () -> Void in
                        sender.presentViewController(errorAlert, animated: true, completion: nil)
                    })
                }
            })
        })
    }
    
    /**
        Submits the concern data to the API
    */
    private func submitConcernForm(concern: Concern, completionHandler: (data: NSData!, response: NSURLResponse!, error: NSError!) -> Void) {
        let url = NSURL(string: baseUrl+"requests.json")
        
        var formString = concern.getFormString()
        
        if let formString = formString {
            let dataString = AuthenticationHandler.sharedHandler.getAuthenticatedDataString(formString)
            let data = dataString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
            if let data = data {
                var request = NSMutableURLRequest(URL: url!)
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                request.setValue("\(data.length)", forHTTPHeaderField: "Content-Length")
                request.HTTPMethod = "POST"
                
                NSURLSession.sharedSession().uploadTaskWithRequest(request, fromData: data, completionHandler: completionHandler)
            } else {
                println("ApiHandler :: Data Encoding failed")
            }
        } else {
            println("ApiHandler :: No FormString given")
        }
    }
    
    /**
        Uploads the potential image of a concern to a separate server
    */
    private func uploadImage(concern: Concern, sender: AddViewController, completionHandler: (imageUrl: NSURL?) -> Void) {
        let url = NSURL(string: imageUrl)
        if let imageData = concern.getImageData() {
            let base64ImageString = imageData.base64EncodedStringWithOptions(.allZeros)
            let base64ImageData = base64ImageString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
            // Create and Send Request, call completionhandler with returned url
            var request = NSMutableURLRequest(URL: url!)
            request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
            request.setValue("\(base64ImageData?.length)", forHTTPHeaderField: "Content-Length")
            request.HTTPMethod = "POST"
            
            NSURLSession.sharedSession().uploadTaskWithRequest(request, fromData: base64ImageData, completionHandler: { (data, response, error) -> Void in
                if let imageUrlString = NSString(data: data, encoding: NSUTF8StringEncoding) as? String, imageUrl = NSURL(string: imageUrlString) {
                    println("ApiHandler :: Image uploaded :: \(imageUrl)")
                    completionHandler(imageUrl: imageUrl)
                } else {
                    println("ApiHandler :: Image upload failed :: \(error.localizedDescription)")
                    let alert = UIAlertController(title: "Fehler", message: "Das Foto konnte nicht übertragen werden. Bitte versuche es später erneut.", preferredStyle: .Alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: nil))
                    sender.presentViewController(alert, animated: true, completion: nil)
                }
            })
        } else {
            completionHandler(imageUrl: nil)
        }
    }
}
