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
    
    /**
        Returns an array of services provided by the API
    */
    func getServices(completionHandler: ([Service]) -> Void) {
        let url = NSURL(string: baseUrl+"services.json")
        let request = NSURLRequest(URL: url!, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData, timeoutInterval: 10)
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: { (response, data, error) -> Void in
            if error == nil {
                let services = self.parseServices(data!)
                completionHandler(services)
            } else {
                print("Error: \(error?.localizedDescription)")
            }
        })
    }
    
    private func parseServices(data: NSData) -> [Service] {
        var output = [Service]()
        let services = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableLeaves)) as! NSArray
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
    
    /**
        Returns an array of the last 50 concerns submitted
    */
    func getConcerns(completionHandler: ([Concern]) -> Void) {
        let url = NSURL(string: baseUrl+"requests.json")
        let request = NSURLRequest(URL: url!)
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: { (response, data, error) -> Void in
            if(error == nil){
                let concerns = self.parseConcerns(data!)
                completionHandler(concerns)
            }
        })
    }
    
    private func parseConcerns(data: NSData) -> [Concern] {
        var output = [Concern]()
        let concerns = (try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableLeaves)) as! NSArray
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
        let submissionTitle = "submission.processing.title".localized
        let submissionText = "submission.processing.text".localized
        let progressAlert = UIAlertController(title: submissionTitle, message: submissionText, preferredStyle: .Alert)
        sender.presentViewController(progressAlert, animated: true, completion: nil)
        
        let closeAction = UIAlertAction(title: "general.ok".localized, style: .Cancel, handler: nil)
        
        uploadImage(concern, sender: sender, completionHandler: { (imageUrl) -> Void in
            concern.imageUrl = imageUrl
            self.submitConcernForm(concern, completionHandler: { (data, response, error) -> Void in
                if error == nil {
                    var jsonData : AnyObject
                    
                    do {
                        jsonData = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableLeaves)
                        
                        if let jsonDict = jsonData[0] as? Dictionary<String,String>, requestID = jsonDict["service_request_id"] {
                            // requestID like "A-4523"
                            NSUserDefaults.standardUserDefaults().mutableArrayValueForKey("requestsSent").addObject(requestID)
                            print("ApiHandler :: SubmitConcernForm :: Submitted :: \(requestID)")
                            
                            let successTitle = "submission.done.title".localized
                            let successText = "submission.done.text".localized
                            let successAlert = UIAlertController(title: successTitle, message: successText, preferredStyle: UIAlertControllerStyle.Alert)
                            let closeAndBackAction = UIAlertAction(title: "general.ok".localized, style: .Cancel, handler: { (action) -> Void in
                                sender.navigationController?.popViewControllerAnimated(true)
                            })
                            successAlert.addAction(closeAndBackAction)
                            progressAlert.dismissViewControllerAnimated(true, completion: { () -> Void in
                                sender.presentViewController(successAlert, animated: true, completion: nil)
                            })
                        }
                    } catch let error {
                        print("Serialization Error \(error)")
                    }
                    
                } else {
                    // Connection Error
                    print("ApiHandler :: SubmitConcernForm :: Error :: \(error.localizedDescription) :: \(NSString(data: data, encoding: NSUTF8StringEncoding))")
                    sender.sendButton.enabled = true
                    let errorTitle = "submission.error.title".localized
                    let errorText = "submission.error.text".localized
                    let errorAlert = UIAlertController(title: errorTitle, message: errorText, preferredStyle: .Alert)
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
        
        let formString = concern.getFormString()
        
        if let formString = formString {
            let dataString = AuthenticationHandler.sharedHandler.getAuthenticatedDataString(formString)
            let data = dataString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
            if let data = data {
                let request = NSMutableURLRequest(URL: url!)
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                request.setValue("\(data.length)", forHTTPHeaderField: "Content-Length")
                request.HTTPMethod = "POST"
                request.HTTPBody = data
                
                let dataTask = NSURLSession.sharedSession().dataTaskWithRequest(request)
                dataTask.resume()
            } else {
                print("ApiHandler :: Data Encoding failed")
            }
        } else {
            print("ApiHandler :: No FormString given")
        }
    }
    
    /**
        Uploads the potential image of a concern to a separate server
    */
    private func uploadImage(concern: Concern, sender: AddViewController, completionHandler: (imageUrl: NSURL?) -> Void) {
        let url = NSURL(string: imageUrl)
        if let imageData = concern.getImageData() {
            let base64ImageString = imageData.base64EncodedStringWithOptions([])
            let base64ImageData = base64ImageString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
            // Create and Send Request, call completionhandler with returned url
            let request = NSMutableURLRequest(URL: url!)
            request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
            request.setValue("\(base64ImageData?.length)", forHTTPHeaderField: "Content-Length")
            request.HTTPMethod = "POST"
            request.HTTPBody = base64ImageData
            
            print("ApiHandler :: Upload Image")
            
            let dataTask = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
                if let data = data, imageUrlString = NSString(data: data, encoding: NSUTF8StringEncoding) as? String, imageUrl = NSURL(string: imageUrlString) {
                    print("ApiHandler :: Image uploaded :: \(imageUrl)")
                    completionHandler(imageUrl: imageUrl)
                } else {
                    print("ApiHandler :: Image upload failed :: \(error?.localizedDescription)")
                    let errorTitle = "submission.error.title".localized
                    let errorText = "submission.error.text".localized
                    let alert = UIAlertController(title: errorTitle, message: errorText, preferredStyle: .Alert)
                    alert.addAction(UIAlertAction(title: "general.ok".localized, style: .Cancel, handler: nil))
                    sender.presentViewController(alert, animated: true, completion: nil)
                }
            })
            dataTask.resume()
        } else {
            completionHandler(imageUrl: nil)
        }
    }
}
