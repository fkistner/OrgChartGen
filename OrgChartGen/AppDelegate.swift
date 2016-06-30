//
//  AppDelegate.swift
//  OrgChartGen
//
//  Created by Florian Kistner on 25/05/16.
//  Copyright © 2016 Florian Kistner. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        if Process.arguments.count > 1 {
            let inPath = Process.arguments[1]
            let version: String? = Process.arguments.count > 2
                ? Process.arguments[2]
                : nil
            
            Renderer.render(inPath, version: version) {
                exit(0)
            }
        }
        
    }
}

