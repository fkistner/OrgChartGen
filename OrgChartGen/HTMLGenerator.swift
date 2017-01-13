//
//  Generator.swift
//  OrgChartGen
//
//  Created by Florian Kistner on 26/05/16.
//  Copyright © 2016 Florian Kistner. All rights reserved.
//

import Foundation
import Mustache

struct HTMLGenerator {
    let box: Dictionary<String, Any>
    
    init(title: String, teams: [Team], programManagers: [Member], infraManagers: [Member], crossProject: Team, version: String? = nil) {
        box = [
            "title": title,
            "teams": teams,
            "programManagers": programManagers,
            "infraManagers": infraManagers,
            "crossProject": crossProject,
            "version": version ?? ""
        ]
    }
    
    func generate(to htmlURL: URL) {
        let htmlRepo = TemplateRepository(bundle: Bundle.main, templateExtension: "htm")
        let cssRepo = TemplateRepository(bundle: Bundle.main, templateExtension: "css")
        let htmlTemplate = try! htmlRepo.template(named: "org_chart")
        let cssTemplate = try! cssRepo.template(named: "org_chart")
        
        for template in [htmlTemplate, cssTemplate] {
            template.extendBaseContext(literalSubscript)
            template.register(determineLogoScaleByArea, forKey: "logoScale")
            template.register(StandardLibrary.each, forKey: "each")
        }
        
        let htmlRendered = try! htmlTemplate.render(box)
        let cssRendered = try! cssTemplate.render(box)
        
        try! htmlRendered
            .data(using: String.Encoding.utf8)?
            .write(to: htmlURL, options: [.atomic])
        let cssURL = htmlURL.deletingPathExtension().appendingPathExtension("css")
        try! cssRendered
            .data(using: String.Encoding.utf8)?
            .write(to: cssURL, options: [.atomic])
    }
    
    let literalSubscript: KeyedSubscriptFunction = { key in
        CGFloat.NativeType(key).flatMap({ CGFloat($0) })
    }
    
    let determineLogoScaleByArea = VariadicFilter { boxes in
        guard boxes.count == 3,
            let logo = boxes[0].value as? [String: Any],
            let logoWidth = logo["width"] as? CGFloat,
            let logoHeight = logo["height"] as? CGFloat,
            let width = boxes[1].value as? CGFloat,
            let height = boxes[2].value as? CGFloat
            else { throw MustacheError(kind: .renderError) }
        let magnification = max(logoWidth / width, logoHeight / height)
        let scale = sqrt(width * height / logoWidth / logoHeight) * magnification
        let (widthScale, heightScale) = width/height > logoWidth/logoHeight ? (1, scale) : (scale, 1)
        return [ "widthScale": widthScale, "heightScale": heightScale]
    }
}
