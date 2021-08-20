//
//  ControlFileParser.swift
//  Sileo
//
//  Created by CoolStar on 6/22/19.
//  Copyright © 2019 Sileo Team. All rights reserved.
//

import Foundation

final class ControlFileParser {
    enum Error: LocalizedError {
        case invalidStringData
        case invalidMultilineValue
        case expectedSeparator
    }
    
    // static let dispatchLock = DispatchSemaphore(value: 1)

    class func dictionary(controlFile: String, isReleaseFile: Bool) throws -> [String: String] {
        guard let controlData = controlFile.data(using: .utf8) else {
            throw Error.invalidStringData
        }
        return try dictionary(controlData: controlData, isReleaseFile: isReleaseFile)
    }
    
    class func dictionary(controlData: Data, isReleaseFile: Bool) throws -> ([String: String]) {
        var dictionary: [String: String] = Dictionary(minimumCapacity: 20)
        // self.dispatchLock.wait()
        
        let controlDataArr = [UInt8](controlData)
        parseControlFile(controlDataArr, controlData.count, isReleaseFile, { rawKey, rawVal in
            let key = String(cString: rawKey)
            let val = String(cString: rawVal)
            dictionary[key] = val
        }, { rawTags in

        })
        // self.dispatchLock.signal()
        return dictionary
    }
    
    class func authorName(string: String) -> String {
        guard let emailIndex = string.firstIndex(of: "<") else {
            return string.trimmingCharacters(in: .whitespaces)
        }
        return string[..<emailIndex].trimmingCharacters(in: .whitespaces)
    }
    
    class func authorEmail(string: String) -> String? {
        guard let emailIndex = string.firstIndex(of: "<") else {
            return nil
        }
        let email = string[emailIndex...]
        guard let emailLastIndex = email.firstIndex(of: ">") else {
            return nil
        }
        return String(email[..<emailLastIndex])
    }
}
