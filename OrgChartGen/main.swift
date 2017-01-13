//
//  main.swift
//  OrgChartGen
//
//  Created by Florian Kistner on 01/07/16.
//  Copyright © 2016 Florian Kistner. All rights reserved.
//

import Foundation
import Cocoa

let userDefaults = UserDefaults.standard

if let inPath = userDefaults.string(forKey: "path") {
    let version = userDefaults.string(forKey: "version")
    
    Renderer.render(path: inPath, version: version) {
        exit(0)
    }
    
    RunLoop.main.run()
} else {
    exit(NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv))
}
