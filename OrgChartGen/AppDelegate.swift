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
        // Insert code here to initialize your application
        
        let inPath: String
        inPath = Process.arguments[1]
        /*switch Process.arguments.count {
        case 2:
            inPath = Process.arguments[1]
            break
        default:
            print("Usage: \(Process.arguments[0]) path")
            exit(-1)
        }*/
        
        let inURL = NSURL(fileURLWithPath: inPath, isDirectory: true)
        HTMLGenerator(inURL).generate(to: inURL)
        exit(0)
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

}

