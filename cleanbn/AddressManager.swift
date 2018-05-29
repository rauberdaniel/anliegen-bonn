//
//  AddressManager.swift
//  cleanbn
//
//  Created by Daniel Rauber on 26.04.15.
//  Copyright (c) 2015 Daniel Rauber. All rights reserved.
//

import Foundation
import CoreLocation

private let _AddressManagerInstance = AddressManager()

class AddressManager: NSObject {
    class var sharedManager: AddressManager {
        return _AddressManagerInstance
    }
    
    func getAddressStringFromPlacemark(_ placemark: CLPlacemark?, includeLocality: Bool) -> String {
        var street = "location.unknown.title".localized
        var locality = ""
        if let placemark = placemark {
            if let thoroughfare = placemark.thoroughfare {
                street = "\(thoroughfare)"
                
                if let subThoroughfare = placemark.subThoroughfare {
                    street += " \(subThoroughfare)"
                }
            }
            if (placemark.locality != nil && placemark.postalCode != nil) {
                locality = ", \(String(describing: placemark.postalCode)) \(String(describing: placemark.locality))"
            }
        }
        if includeLocality {
            return street+locality
        }
        return street
    }
}
