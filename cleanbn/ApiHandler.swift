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
    
    let baseUrl = "https://anliegen.bonn.de/georeport/v2/"
    let imageUrl = "https://cleanbn.danielrauber.de/image.php"
    
    class var sharedHandler: ApiHandler {
        return _ApiHandlerInstance
    }
    
    /**
        Returns an array of services provided by the API
    */
    func getServices(_ completionHandler: @escaping ([Service]) -> Void) {
        let url = URL(string: baseUrl+"services.json")
        let request = URLRequest(url: url!, cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData, timeoutInterval: 10)
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if error == nil {
                let services = self.parseServices(data!)
                completionHandler(services)
            } else {
                print("Error: \(String(describing: error?.localizedDescription))")
            }
        }
    }
    
    fileprivate func parseServices(_ data: Data) -> [Service] {
        var output = [Service]()
        let services = (try! JSONSerialization.jsonObject(with: data, options: .mutableLeaves)) as! NSArray
        for s in services {
            if let sDict:NSDictionary = s as? NSDictionary {
                if let sCode = sDict["service_code"] as? String, let sName = sDict["service_name"] as? String {
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
    func getConcerns(_ completionHandler: @escaping ([Concern], NSError?) -> Void) {
        print("GetConcerns")
        let url = URL(string: baseUrl+"requests.json")
        let request = URLRequest(url: url!)
        
        let dataTask = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            print("Reponse")
            
            if(error == nil){
                let concerns = self.parseConcerns(data!)
                completionHandler(concerns, nil)
            } else {
                completionHandler([], error! as NSError)
            }
        })
        
        dataTask.resume()
    }
    
    fileprivate func parseConcerns(_ data: Data) -> [Concern] {
        var output = [Concern]()
        let concerns = (try! JSONSerialization.jsonObject(with: data, options: .mutableLeaves)) as! NSArray
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
    func submitConcern(_ concern: Concern, sender: AddViewController) {
        let submissionTitle = "submission.processing.title".localized
        let submissionText = "submission.processing.text".localized
        let progressAlert = UIAlertController(title: submissionTitle, message: submissionText, preferredStyle: .alert)
        sender.present(progressAlert, animated: true, completion: nil)
        
        let closeAction = UIAlertAction(title: "general.ok".localized, style: .cancel, handler: nil)
        
        uploadImage(concern, sender: sender, completionHandler: { (imageUrl) -> Void in
            concern.imageUrl = imageUrl
            self.submitConcernForm(concern, completionHandler: { (data, response, error) -> Void in
                
                if error == nil {
                    var jsonData : Any
                    
                    do {
                        jsonData = try JSONSerialization.jsonObject(with: data!, options: .mutableLeaves)
                        
                        print(jsonData)
                        
                        if let jsonDict = (jsonData as! NSArray)[0] as? Dictionary<String,String>, let requestID = jsonDict["service_request_id"] {
                            // requestID like "A-4523"
                            UserDefaults.standard.mutableArrayValue(forKey: "requestsSent").add(requestID)
                            print("ApiHandler :: SubmitConcernForm :: Submitted :: \(requestID)")
                            
                            let successTitle = "submission.done.title".localized
                            let successText = "submission.done.text".localized
                            let successAlert = UIAlertController(title: successTitle, message: successText, preferredStyle: UIAlertControllerStyle.alert)
                            let closeAndBackAction = UIAlertAction(title: "general.ok".localized, style: .cancel, handler: { (action) -> Void in
                                sender.navigationController?.popViewController(animated: true)
                            })
                            print("We should be fine")
                            successAlert.addAction(closeAndBackAction)
                            progressAlert.dismiss(animated: true, completion: { () -> Void in
                                sender.present(successAlert, animated: true, completion: nil)
                            })
                        }
                    } catch let error {
                        print("Serialization Error \(error)")
                    }
                    
                } else {
                    // Connection Error
                    print("ApiHandler :: SubmitConcernForm :: Error :: \(String(describing: error?.localizedDescription)) :: \(String(describing: NSString(data: data!, encoding: String.Encoding.utf8.rawValue)))")
                    sender.sendButton.isEnabled = true
                    let errorTitle = "submission.error.title".localized
                    let errorText = "submission.error.text".localized
                    let errorAlert = UIAlertController(title: errorTitle, message: errorText, preferredStyle: .alert)
                    errorAlert.addAction(closeAction)
                    progressAlert.dismiss(animated: true, completion: { () -> Void in
                        sender.present(errorAlert, animated: true, completion: nil)
                    })
                }
            })
        })
    }
    
    /**
        Submits the concern data to the API
    */
    fileprivate func submitConcernForm(_ concern: Concern, completionHandler: @escaping (_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void) {
        let url = URL(string: baseUrl+"requests.json")
        
        let formString = concern.getFormString()
        
        if let formString = formString {
            let dataString = AuthenticationHandler.sharedHandler.getAuthenticatedDataString(formString)
            let data = dataString.data(using: String.Encoding.utf8, allowLossyConversion: false)
            if let data = data {
                var request = URLRequest.init(url: url!)
                
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                request.setValue("\(data.count)", forHTTPHeaderField: "Content-Length")
                request.httpMethod = "POST"
                request.httpBody = data
                
                let dataTask = URLSession.shared.dataTask(with: request, completionHandler: completionHandler)
                
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
    fileprivate func uploadImage(_ concern: Concern, sender: AddViewController, completionHandler: @escaping (_ imageUrl: URL?) -> Void) {
        let url = URL(string: imageUrl)
        if let imageData = concern.getImageData() {
            let base64ImageString = imageData.base64EncodedString(options: [])
            let base64ImageData = base64ImageString.data(using: String.Encoding.utf8, allowLossyConversion: false)
            // Create and Send Request, call completionhandler with returned url
            var request = URLRequest(url: url!)
            request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
            request.setValue("\(String(describing: base64ImageData?.count))", forHTTPHeaderField: "Content-Length")
            request.httpMethod = "POST"
            request.httpBody = base64ImageData
            
            print("ApiHandler :: Upload Image")
            
            let dataTask = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
                if let data = data, let imageUrlString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as String?, let imageUrl = URL(string: imageUrlString) {
                    print("ApiHandler :: Image uploaded :: \(imageUrl)")
                    completionHandler(imageUrl)
                } else {
                    print("ApiHandler :: Image upload failed :: \(String(describing: error?.localizedDescription))")
                    let errorTitle = "submission.error.title".localized
                    let errorText = "submission.error.text".localized
                    let alert = UIAlertController(title: errorTitle, message: errorText, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "general.ok".localized, style: .cancel, handler: nil))
                    sender.present(alert, animated: true, completion: nil)
                }
            })
            dataTask.resume()
        } else {
            completionHandler(nil)
        }
    }
}
