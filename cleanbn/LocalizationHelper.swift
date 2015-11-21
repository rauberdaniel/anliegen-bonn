//
//  LocalizationHelper.swift
//  cleanbn
//
//  Created by Daniel Rauber on 19.06.15.
//  Copyright (c) 2015 Daniel Rauber. All rights reserved.
//

import Foundation

public extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}