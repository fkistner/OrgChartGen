//
//  ViewController.swift
//  OrgChartGen
//
//  Created by Florian Kistner on 25/05/16.
//  Copyright © 2016 Florian Kistner. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    @IBOutlet weak var pathField: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func selectPath(sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        
        if openPanel.runModal() == NSModalResponseOK,
            let path = openPanel.URLs.first?.path {
            pathField.stringValue = path
        }
    }
    
    @IBAction func generate(sender: NSButton) {
        sender.enabled = false
        Renderer.render(pathField.stringValue) {
            sender.enabled = true
        }
    }

}

