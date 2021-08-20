//
//  Repo.swift
//  Sileo
//
//  Created by CoolStar on 7/21/19.
//  Copyright © 2019 Sileo Team. All rights reserved.
//

import Foundation

final class Repo: Equatable {

    var rawURL: String = ""
    var suite: String = ""
    var components: [String] = []
    var compression = ""

    var packageDict: [String: Package] = [:]
    var packageArray: [Package] {
        Array(packageDict.values)
    }

    var url: URL? {
        guard let rawURL = URL(string: rawURL) else {
            return nil
        }
        if isFlat {
            return suite == "./" ? rawURL : rawURL.appendingPathComponent(suite)
        } else {
            return rawURL.appendingPathComponent("dists").appendingPathComponent(suite)
        }
    }
    
    var repoURL: String {
        url?.absoluteString ?? ""
    }
    
    var displayURL: String {
        rawURL
    }
    
    var primaryComponentURL: URL? {
        if isFlat {
            return self.url
        } else {
            if components.isEmpty {
                return nil
            }
            return self.url?.appendingPathComponent(components[0])
        }
    }
    
    var isFlat: Bool {
        suite.hasSuffix("/") || components.isEmpty
    }
    
    func packagesURL(arch: String?) -> URL? {
        guard var packagesDir = primaryComponentURL else {
            return nil
        }
        if !isFlat,
            let arch = arch {
            packagesDir = packagesDir.appendingPathComponent("binary-".appending(arch))
        }
        return packagesDir.appendingPathComponent("Packages")
    }
}

func == (lhs: Repo, rhs: Repo) -> Bool {
    lhs.rawURL == rhs.rawURL && lhs.suite == rhs.suite
}
