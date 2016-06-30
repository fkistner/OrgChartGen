//
//  Renderer.swift
//  OrgChartGen
//
//  Created by Florian Kistner on 29/06/16.
//  Copyright © 2016 Florian Kistner. All rights reserved.
//

import Foundation

final class Renderer {
    class func render(inPath: String, callback: (() -> ())? = nil) {
        let inURL = NSURL(fileURLWithPath: inPath, isDirectory: true)
        let htmlURL = inURL.URLByAppendingPathComponent("org_chart.htm")
        
        let enumerator = OrgChartEnumerator(inURL)
        let input = enumerator.enumerateAll()
        
        let generator = HTMLGenerator(teams:           input.teams,
                                      programManagers: input.programManagers,
                                      infraManagers:   input.infraManagers,
                                      crossProject:    input.crossProject)
        generator.generate(to: htmlURL)
        
        PDFRenderer.shared.render(htmlURL, to: inURL.URLByAppendingPathComponent("org_chart.pdf")) {
            callback?()
        }
    }
}