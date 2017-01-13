//
//  Renderer.swift
//  OrgChartGen
//
//  Created by Florian Kistner on 29/06/16.
//  Copyright © 2016 Florian Kistner. All rights reserved.
//

import Foundation

final class Renderer {
    class func render(path inPath: String, version: String? = nil, callback: (() -> ())? = nil) {
        let inURL = URL(fileURLWithPath: inPath, isDirectory: true)
        let htmlURL = inURL.appendingPathComponent("org_chart.htm")
        
        let enumerator = OrgChartEnumerator(at: inURL)
        let input = enumerator.enumerateAll()
        
        let generator = HTMLGenerator(title:           input.title,
                                      teams:           input.teams,
                                      programManagers: input.programManagers,
                                      infraManagers:   input.infraManagers,
                                      crossProject:    input.crossProject,
                                      version:         version)
        generator.generate(to: htmlURL)
        
        PDFRenderer.shared.render(url: htmlURL, to: inURL.appendingPathComponent("org_chart.pdf")) {
            callback?()
        }
    }
}
