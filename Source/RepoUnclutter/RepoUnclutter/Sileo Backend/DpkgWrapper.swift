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
        guard let dpkgCmp = try? compareVersions(version, greaterThan) else {
            return false
        }
        
        if dpkgCmp > 0 {
            return true
        }
        return false
    }
}

struct DpkgVersion {
    var epoch: UInt
    var version: ArraySlice<CChar>
    var revision: ArraySlice<CChar>
}

func isBlank(char: CChar) -> Bool {
    isblank(Int32(char)) != 0
}

func parseversion(version: String) throws -> DpkgVersion {
    let strArr = version.utf8.map { Int8($0) } + [0]

    var version = ArraySlice<CChar>(strArr)
    var searchIdx = 0
    var found = false
    for char in version {
        if char == 58 { // 58 means a colon :
            found = true
            break
        }
        searchIdx += 1
    }

    var epochNum = 0
    if found {
        var epochStr = version.dropLast(version.count - searchIdx)
        version = version.dropFirst(searchIdx + 1)
        
        guard !version.isEmpty else {
            throw ControlFileParser.Error.expectedSeparator
        }
        
        errno = 0
        epochNum = try epochStr.withUnsafeMutableBufferPointer {
            var baseAddrPtr = $0.baseAddress
            let num = strtol($0.baseAddress, &baseAddrPtr, 10)
            guard baseAddrPtr != $0.baseAddress else {
                throw ControlFileParser.Error.expectedSeparator
            }
            return num
        }
        guard epochNum <= INT_MAX && errno != ERANGE else {
            throw ControlFileParser.Error.expectedSeparator
        }
        guard epochNum > 0 else {
            throw ControlFileParser.Error.expectedSeparator
        }
    }

    searchIdx = version.count
    found = false
    for char in version.reversed() {
        searchIdx -= 1
        if char == 45 { // 45 means a dash -
            found = true
            break
        }
    }

    if found {
        version[version.startIndex + searchIdx] = 0
    }
    
    let versionStr = found ? version.dropLast(version.count - (searchIdx + 1)) : version
    let revisionStr = found ? version.dropFirst(searchIdx + 1) : ArraySlice<CChar>([0])

    for char in versionStr {
        guard isDigit(char: char) || isAlpha(char: char) || strrchr(".-+~:", Int32(char)) != nil else {
            throw ControlFileParser.Error.expectedSeparator
        }
    }

    for char in revisionStr {
        guard isDigit(char: char) || isAlpha(char: char) || strrchr(".-+~:", Int32(char)) != nil else {
            throw ControlFileParser.Error.expectedSeparator
        }
    }
    if versionStr.last != 0 {
        fatalError("Needs null termination")
    }
    if revisionStr.last != 0 {
        fatalError("Needs null termination")
    }
    return DpkgVersion(epoch: UInt(epochNum), version: versionStr, revision: revisionStr)
}

func compareVersions(_ aStr: String, _ bStr: String) throws -> Int {
    let aVer = try parseversion(version: aStr)
    let bVer = try parseversion(version: bStr)
    
    if aVer.epoch > bVer.epoch {
        return 1
    }
    if aVer.epoch < bVer.epoch {
        return -1
    }
    
    let retVal = verrevcmp(val: aVer.version, ref: bVer.version)
    if retVal != 0 {
        return retVal
    }
    
    return verrevcmp(val: aVer.revision, ref: bVer.revision)
}

func isDigit(char: CChar) -> Bool {
    isdigit(Int32(char)) != 0
}

func isAlpha(char: CChar) -> Bool {
    isalpha(Int32(char)) != 0
}

func order(char: CChar) -> Int {
    if isAlpha(char: char) {
        return Int(char)
    } else if char == 126 {
        return -1
    } else if char > 0 {
        return Int(char) + 256
    }
    return 0
}

func verrevcmp(val: ArraySlice<CChar>, ref: ArraySlice<CChar>) -> Int {
    var val = val
    var ref = ref
    while !val.isEmpty || !ref.isEmpty {
        var firstDiff = 0
        var digitPrefix = 0
        for (valchar, refchar) in zip(val, ref) {
            if isDigit(char: valchar) || isDigit(char: refchar) {
                break
            }
            
            let valord = order(char: valchar)
            let reford = order(char: refchar)
            
            if valord != reford {
                return valord - reford
            }
            
            digitPrefix += 1
        }
        val = val.dropFirst(digitPrefix)
        ref = ref.dropFirst(digitPrefix)
        
        digitPrefix = 0
        for valchar in val {
            guard valchar == 48 else {
                break
            }
            digitPrefix += 1
        }
        val = val.dropFirst(digitPrefix)
        
        digitPrefix = 0
        for refchar in ref {
            guard refchar == 48 else {
                break
            }
            digitPrefix += 1
        }
        ref = ref.dropFirst(digitPrefix)
        
        digitPrefix = 0
        for (valchar, refchar) in zip(val, ref) {
            guard isDigit(char: valchar) && isDigit(char: refchar) else {
                break
            }
            if firstDiff == 0 {
                firstDiff = Int(valchar - refchar)
            }
            digitPrefix += 1
        }
        val = val.dropFirst(digitPrefix)
        ref = ref.dropFirst(digitPrefix)
        
        if !val.isEmpty && isDigit(char: val[val.startIndex]) {
            return 1
        }
        if !ref.isEmpty && isDigit(char: ref[ref.startIndex]) {
            return -1
        }
        if firstDiff != 0 {
            return firstDiff
        }
    }
    
    return 0
}
