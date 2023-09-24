//
//  DpkgWrapper.swift
//  Anemone
//
//  Created by CoolStar on 6/23/19.
//  Copyright © 2019 Sileo Team. All rights reserved.
//

import Foundation

class DpkgWrapper {
    
    public class func isVersion(_ version: String, greaterThan: String) -> Bool {
        compareVersion(version, Int32(version.count + 1), greaterThan, Int32(greaterThan.count + 1)) > 0
    }
    
}
