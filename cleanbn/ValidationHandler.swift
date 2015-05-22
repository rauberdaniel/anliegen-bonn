//
//  ValidationHandler.swift
//  cleanbn
//
//  Created by Daniel Rauber on 17.05.15.
//  Copyright (c) 2015 Daniel Rauber. All rights reserved.
//

import UIKit

class ValidationHandler: NSObject {
       
    class func isValidEmail(testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluateWithObject(testStr)
    }
    
}
