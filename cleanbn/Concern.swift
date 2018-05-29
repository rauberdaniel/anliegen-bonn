//
//  Concern.swift
//  cleanbn
//
//  Created by Daniel Rauber on 17.04.15.
//  Copyright (c) 2015 Daniel Rauber. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit
import CoreGraphics

class Concern: NSObject, CLLocationManagerDelegate {
    
    var id: String?
    var dateReported: Date?
    var locationName: String?
    var location: CLLocation? {
        didSet {
            //updateLocationName()
        }
    }
    var desc: String = ""
    var service: Service
    var imageUrl: URL?
    var state: String?
    var image: UIImage?
    
    override init() {
        service = Service(code: "0000", name: "Undefined")
    }
    
    init(fromDictionary dict: NSDictionary) {
        if let id = dict["service_request_id"] as? String {
            self.id = id
        }
        if let reportedString = dict["requested_datetime"] as? String {
            if let date = Date.dateFromISOString(reportedString) {
                dateReported = date
            } else {
                dateReported = Date()
            }
        } else {
            dateReported = Date()
        }
        if let name = dict["service_name"] as? String, let code = dict["service_code"] as? String {
            service = Service(code: code, name: name)
        } else {
            service = Service(code: "0000", name: "Undefined")
        }
        if let address = dict["address"] as? String {
            locationName = address
        }
        if let description = dict["description"] as? String {
            desc = description
        }
        if let lat = dict["lat"] as? NSNumber, let lon = dict["long"] as? NSNumber {
            location = CLLocation(latitude: lat.doubleValue, longitude: lon.doubleValue)
        }
        if let imageUrlString = dict["media_url"] as? String, let imageUrl = URL(string: imageUrlString) {
            self.imageUrl = imageUrl
        }
        if let state = dict["status"] as? String {
            self.state = state
        }
    }
    
    init(service: Service, location: CLLocation, address: String, description: String?, image: UIImage?){
        self.service = service
        self.location = location
        self.locationName = address
        if let description = description {
            self.desc = description
        }
        self.image = image
    }
    
    func updateLocationName() {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location!, completionHandler: { (placemarks, error) -> Void in
            if let placemarks = placemarks {
                let placemark = placemarks[0];
                self.locationName = "\(String(describing: placemark.thoroughfare)) \(String(describing: placemark.subThoroughfare))"
            }
        })    }
    
    func getImageData() -> Data? {
        if let image = image {
            let imageData = UIImageJPEGRepresentation(image, 0.6)
            return imageData
        }
        return nil
    }
    
    func getJSONData() -> Data? {
        var dict: Dictionary<String, AnyObject> = [:]
        dict["service_name"] = service.name as AnyObject
        dict["service_code"] = service.code as AnyObject
        dict["lat"] = location?.coordinate.latitude as AnyObject
        dict["long"] = location?.coordinate.longitude as AnyObject
        dict["address"] = locationName as AnyObject
        dict["description"] = desc as AnyObject
        if let mail = UserDefaults.standard.string(forKey: "email") {
            dict["email"] = mail as AnyObject
        }
        
        if let imageData = getImageData() {
            let base64ImageString = imageData.base64EncodedString(options: [])
            dict["image"] = base64ImageString as AnyObject
        }
        
        let data: Data?
        do {
            data = try JSONSerialization.data(withJSONObject: dict, options: JSONSerialization.WritingOptions())
        } catch let error as NSError {
            print(error)
            data = nil
        }
        return data
    }
    
    func getFormString() -> String? {
        if let mail = UserDefaults.standard.string(forKey: "email"), let lat = location?.coordinate.latitude, let long = location?.coordinate.longitude {
            var string = "service_code=\(service.code)&lat=\(lat)&long=\(long)&description=\(desc)&email=\(mail)"
            if let mediaUrl = imageUrl {
                string += "&media_url=\(mediaUrl.absoluteString)"
            }
            print("Concern :: Form Data :: \(string)")
            return string
        } else {
            print("Concern :: Mail or Location missing")
        }
        return nil
    }
    
}
