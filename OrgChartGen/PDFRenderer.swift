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
    var callback: ((Data) -> ())?
    
    override init() {
        self.webView = WebView()
        super.init()
        
        webView.frameLoadDelegate = self
        webView.preferences.shouldPrintBackgrounds = true
    }
    
    func render(url: URL, to pdfURL: URL, callback: @escaping () -> ()) {
        self.callback = { data in
            try! data.write(to: pdfURL, options: [.atomic])
            callback()
        }
        webView.mainFrame.load(URLRequest(url: url))
    }
    
    func webView(_ sender: WebView!, didFinishLoadFor frame: WebFrame!) {
        if let callback = callback {
            let documentView = frame.frameView.documentView
            callback((documentView?.dataWithPDF(inside: (documentView?.frame)!))!)
        }
    }
}
