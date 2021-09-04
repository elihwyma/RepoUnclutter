//
//  main.swift
//  RepoUnclutter
//
//  Created by Andromeda on 20/08/2021.
//

import Foundation

let repoURL = URL(fileURLWithPath: "RepoList.json")
guard let listData = try? Data(contentsOf: repoURL),
      let repoJson = try? JSONSerialization.jsonObject(with: listData, options: []) as? [[String: String]] else { fatalError("Missing Repolist File") }

let allowedTweaksUrl = URL(fileURLWithPath: "PackageWhitelist.json")
guard let tweakData = try? Data(contentsOf: allowedTweaksUrl),
      let allowedTweaks = try? JSONSerialization.jsonObject(with: tweakData, options: []) as? [String] else { fatalError("Missing Package Whitelist") }

var repoList = [Repo]()
for repoData in repoJson {
    guard let uri = repoData["URI"],
          let suites = repoData["Suites"],
          let components = repoData["Components"],
          let compression = repoData["Compression"] else { continue }
    let repo = Repo()
    repo.rawURL = uri
    repo.suite = suites
    repo.components = [components]
    repo.compression = compression
    repoList.append(repo)
}

var packagesFileData = NSMutableData()
var packagesToKeep = [Package]()

for repo in repoList {
    guard let url = repo.packagesURL(arch: "iphoneos-arm"),
          let repoUrl = URL(string: repo.displayURL) else { continue }
    let tmpUrl = URL(fileURLWithPath: "temppackages.bz2")
    let packagesUrl = url.appendingPathExtension(repo.compression)
    
    var request = URLRequest(url: packagesUrl)
    request.setValue("Cum", forHTTPHeaderField: "X-Machine")
    request.setValue("Cock", forHTTPHeaderField: "X-Unique-ID")
    request.setValue("Balls", forHTTPHeaderField: "X-Firmware")
    // I cba doing this async
    guard let packagesData = try? NSURLConnection.sendSynchronousRequest(request, returning: nil) else { fatalError("Unable to connect to \(packagesUrl.absoluteString)")  }
    do {
        try packagesData.write(to: tmpUrl, options: .atomic)
    } catch {
        fatalError("Unable to write data")
    }
    let (error, data) = BZIP.decompress(path: tmpUrl.path)
    guard let data = data else {
        fatalError("Unable to unarchive data with error \(error ?? "Unknown")")
    }
    
    let packagesDict = PackageListManager.readPackages(rawPackagesData: data)
    for package in packagesDict.values where allowedTweaks.contains(package.packageID) {
        for version in package.allVersions {
            guard let filename = package.filename else { continue }
            var string = ""
            for (key, value) in package.rawControl {
                if key == "filename" {
                    string += "filename: \(repoUrl.appendingPathComponent(filename))\n"
                } else if key == "tag" {
                    continue
                } else {
                    string += "\(key): \(value)\n"
                }
            }
            string += "\n"
            guard let data = string.data(using: .utf8) else { fatalError("failed to encode packages file") }
            packagesFileData.append(data)
        }
    }
    try? FileManager.default.removeItem(at: tmpUrl)
}

try? packagesFileData.write(to: URL(fileURLWithPath: "Packages"), atomically: true)
