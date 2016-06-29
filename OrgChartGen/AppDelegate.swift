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
    
    var inPath: String?
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {

        if Process.arguments.count > 1 {
            let inPath = Process.arguments[1]
            self.inPath = inPath
            
            Renderer.render(inPath) {
                exit(0)
            }
        }
        
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

}

