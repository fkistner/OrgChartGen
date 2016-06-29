//
//  Renderer.swift
//  OrgChartGen
//
//  Created by Florian Kistner on 30/05/16.
//  Copyright © 2016 Florian Kistner. All rights reserved.
//

import Foundation
import WebKit

class PDFRenderer: NSObject, WebFrameLoadDelegate {
    
    static var shared = PDFRenderer()
    
    let webView: WebView
    var callback: (NSData -> ())?
    
    override init() {
        self.webView = WebView()
        super.init()
        
        webView.frameLoadDelegate = self
        webView.preferences.shouldPrintBackgrounds = true
    }
    
    func render(url: NSURL, to pdfURL: NSURL, callback: () -> ()) {
        self.callback = { data in
            data.writeToURL(pdfURL, atomically: true)
            callback()
        }
        webView.mainFrame.loadRequest(NSURLRequest(URL: url))
    }
    
    func webView(sender: WebView!, didFinishLoadForFrame frame: WebFrame!) {
        if let callback = callback {
            let documentView = frame.frameView.documentView
            callback(documentView.dataWithPDFInsideRect(documentView.frame))
        }
    }
}