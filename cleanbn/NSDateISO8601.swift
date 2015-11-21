//
//  NSDateISO8601.swift
//  cleanbn
//
//  Created by Daniel Rauber on 17.04.15.
//  Copyright (c) 2015 Daniel Rauber. All rights reserved.
//

import Foundation

public extension NSDate {
    public class func ISOStringFromDate(date: NSDate) -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        dateFormatter.timeZone = NSTimeZone(abbreviation: "GMT")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        return dateFormatter.stringFromDate(date)
    }
    
    public class func dateFromISOString(string: String) -> NSDate? {
        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        dateFormatter.timeZone = NSTimeZone.localTimeZone()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        return dateFormatter.dateFromString(string)
    }
    
    public class func shortStringFromDate(date: NSDate) -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .ShortStyle
        dateFormatter.timeStyle = .NoStyle
        
        return dateFormatter.stringFromDate(date)
    }
}