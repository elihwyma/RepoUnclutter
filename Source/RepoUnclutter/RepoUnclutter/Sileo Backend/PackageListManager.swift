//
//  PublicListManager.swift
//  Sileo
//
//  Created by CoolStar on 7/3/19.
//  Copyright © 2019 Sileo Team. All rights reserved.
//

import Foundation

final class PackageListManager {

    class func package(packageEnum: [String: String]) -> Package? {
        let dictionary = packageEnum
        guard let packageID = dictionary["package"] else {
            return nil
        }
        guard let packageVersion = dictionary["version"] else {
            return nil
        }
        
        let package = Package(package: packageID, version: packageVersion)
        package.name = dictionary["name"]
        if package.name == nil {
            package.name = package.package
        }
        package.icon = dictionary["icon"]
        package.architecture = dictionary["architecture"]
        package.maintainer = dictionary["maintainer"]
        if package.maintainer != nil {
            if dictionary["author"] != nil {
                package.author = dictionary["author"]
            } else {
                package.author = dictionary["maintainer"]
            }
        }
        package.filename = dictionary["filename"]
        package.rawControl = dictionary
        return package
    }

    public class func readPackages(rawPackagesData: Data) -> [String: Package] {
        var dict = [String: Package]()

        var index = 0
        var separator = "\n\n".data(using: .utf8)!
        
        guard let firstSeparator = rawPackagesData.range(of: "\n".data(using: .utf8)!, options: [], in: 0..<rawPackagesData.count) else {
            return dict
        }
        if firstSeparator.lowerBound != 0 {
            let subdata = rawPackagesData.subdata(in: firstSeparator.lowerBound-1..<firstSeparator.lowerBound)
            let character = subdata.first
            if character == 13 { // 13 means carriage return (\r, Windows line ending)
                separator = "\r\n\r\n".data(using: .utf8)!
            }
        }
        while index < rawPackagesData.count {
            let range = rawPackagesData.range(of: separator, options: [], in: index..<rawPackagesData.count)
            var newIndex = 0
            if range == nil {
                newIndex = rawPackagesData.count
            } else {
                newIndex = range!.lowerBound + separator.count
            }
            
            let subRange = index..<newIndex
            let packageData = rawPackagesData.subdata(in: subRange)
            
            index = newIndex
            
            guard let rawPackageEnum = try? ControlFileParser.dictionary(controlData: packageData, isReleaseFile: false) else {
                continue
            }
            let rawPackage = rawPackageEnum
            guard let packageID = rawPackage["package"] else {
                continue
            }
            if packageID.isEmpty {
                continue
            }
            if packageID.hasPrefix("gsc.") {
                continue
            }
            if packageID.hasPrefix("cy+") {
                continue
            }
            if packageID == "firmware" {
                continue
            }
            
            guard let package = self.package(packageEnum: rawPackageEnum) else {
                continue
            }
            package.rawData = packageData

            if let otherPkg = dict[packageID] {
                if DpkgWrapper.isVersion(package.version, greaterThan: otherPkg.version) {
                    package.addOld([otherPkg])
                    dict[packageID] = package
                }
                otherPkg.addOldInternal(Array(package.allVersionsInternal.values))
                package.allVersionsInternal = otherPkg.allVersionsInternal
            } else {
                dict[packageID] = package
            }
        }
        return dict
    }
}

extension Thread {

    var threadName: String {
        if let currentOperationQueue = OperationQueue.current?.name {
            return "OperationQueue: \(currentOperationQueue)"
        } else if let underlyingDispatchQueue = OperationQueue.current?.underlyingQueue?.label {
            return "DispatchQueue: \(underlyingDispatchQueue)"
        } else {
            let name = __dispatch_queue_get_label(nil)
            return String(cString: name, encoding: .utf8) ?? Thread.current.description
        }
    }
    
}
