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
    
    var dateReported: NSDate
    var locationName: String?
    var location: CLLocation? {
        didSet {
            //updateLocationName()
        }
    }
    var desc: String = ""
    var service: Service
    var imageUrl: String?
    var state: String?
    var image: UIImage?
    
    override init() {
        dateReported = NSDate()
        service = Service(code: "0000", name: "Undefined")
    }
    
    init(fromDictionary dict: NSDictionary) {
        if let reportedString = dict["requested_datetime"] as? String {
            if let date = NSDate.dateFromISOString(reportedString) {
                dateReported = date
            } else {
                dateReported = NSDate()
            }
        } else {
            dateReported = NSDate()
        }
        if let name = dict["service_name"] as? String, code = dict["service_code"] as? String {
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
        if let lat = dict["lat"] as? NSNumber, lon = dict["long"] as? NSNumber {
            location = CLLocation(latitude: lat.doubleValue, longitude: lon.doubleValue)
        }
        if let imageUrl = dict["media_url"] as? String {
            self.imageUrl = imageUrl
        }
        if let state = dict["status"] as? String {
            self.state = state
        }
    }
    
    func updateLocationName() {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
            if let placemark = placemarks[0] as? CLPlacemark {
                self.locationName = "\(placemark.thoroughfare) \(placemark.subThoroughfare)"
            }
        })
    }
    
    func getJSONData() -> NSData? {
        
        var dict: Dictionary<String, AnyObject> = [:]
        dict["service_name"] = service.name
        dict["service_code"] = service.code
        dict["lat"] = location?.coordinate.latitude
        dict["long"] = location?.coordinate.longitude
        dict["address"] = locationName
        
        if let image = image {
            let imageData = UIImageJPEGRepresentation(image, 0.6)
            let base64ImageString = imageData.base64EncodedStringWithOptions(.allZeros)
            dict["image"] = base64ImageString
        }
        
        var parseError: NSError?
        let data = NSJSONSerialization.dataWithJSONObject(dict, options: NSJSONWritingOptions.allZeros, error: &parseError)
        return data
    }
    
}
