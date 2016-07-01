//
//  main.swift
//  OrgChartGen
//
//  Created by Florian Kistner on 01/07/16.
//  Copyright © 2016 Florian Kistner. All rights reserved.
//

import Foundation
import Cocoa

let userDefaults = NSUserDefaults.standardUserDefaults()

if let inPath = userDefaults.stringForKey("path") {
    let version = userDefaults.stringForKey("version")
    
    Renderer.render(inPath, version: version) {
        exit(0)
    }
    
    NSRunLoop.mainRunLoop().run()
} else {
    NSApplicationMain(Process.argc, Process.unsafeArgv)
}
