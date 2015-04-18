//
//  Concern.swift
//  cleanbn
//
//  Created by Daniel Rauber on 17.04.15.
//  Copyright (c) 2015 Daniel Rauber. All rights reserved.
//

import Foundation
import CoreLocation

class Concern: NSObject, CLLocationManagerDelegate {
    
    var dateReported: NSDate
    var locationName: String = "Unknown Location"
    var location: CLLocation? {
        didSet {
            //updateLocationName()
        }
    }
    var title: String = ""
    var desc: String = ""
    
    override init() {
        dateReported = NSDate()
        title = "Concern"
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
        if let name = dict["service_name"] as? String {
            title = name
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
    }
    
    func updateLocationName() {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
            if let placemark = placemarks[0] as? CLPlacemark {
                self.locationName = "\(placemark.thoroughfare) \(placemark.subThoroughfare)"
            }
        })
    }
    
    
    
}
