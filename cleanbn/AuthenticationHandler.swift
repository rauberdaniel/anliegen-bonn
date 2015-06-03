//
//  ServiceManager.swift
//  cleanbn
//
//  Created by Daniel Rauber on 18.04.15.
//  Copyright (c) 2015 Daniel Rauber. All rights reserved.
//

import Foundation

private let _AuthenticationHandlerInstance = AuthenticationHandler()

class AuthenticationHandler: NSObject {
    class var sharedHandler: AuthenticationHandler {
        return _AuthenticationHandlerInstance
    }
    
    func getAuthenticatedDataString(dataString: String) -> String {
        return dataString + "&api_key=APIKEY"
    }
}
