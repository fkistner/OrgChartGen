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
    let box: MustacheBox
    
    init(title: String, teams: [Team], programManagers: [Member], infraManagers: [Member], crossProject: Team, version: String? = nil) {
        box = Box([
            "title": title,
            "teams": teams,
            "programManagers": programManagers,
            "infraManagers": infraManagers,
            "crossProject": crossProject,
            "version": version ?? ""
        ])
    }
    
    func generate(to htmlURL: NSURL) {
        let htmlRepo = TemplateRepository(bundle: NSBundle.mainBundle(), templateExtension: "htm")
        let cssRepo = TemplateRepository(bundle: NSBundle.mainBundle(), templateExtension: "css")
        let htmlTemplate = try! htmlRepo.template(named: "org_chart")
        let cssTemplate = try! cssRepo.template(named: "org_chart")
        
        for template in [htmlTemplate, cssTemplate] {
            template.extendBaseContext(MustacheBox(keyedSubscript: literalSubscript))
            template.registerInBaseContext("logoScale", Box(determineLogoScaleByArea))
            template.registerInBaseContext("each", Box(StandardLibrary.each))
        }
        
        let htmlRendered = try! htmlTemplate.render(box)
        let cssRendered = try! cssTemplate.render(box)
        
        htmlRendered
            .dataUsingEncoding(NSUTF8StringEncoding)?
            .writeToURL(htmlURL, atomically: false)
        let cssURL = htmlURL.URLByDeletingPathExtension!.URLByAppendingPathExtension("css")
        cssRendered
            .dataUsingEncoding(NSUTF8StringEncoding)?
            .writeToURL(cssURL, atomically: false)
    }
    
    let literalSubscript: KeyedSubscriptFunction = { key in
        if let intValue = Int(key) {
            return Box(NSNumber(integer: intValue))
        } else if let floatValue = Float(key) {
            return Box(NSNumber(float: floatValue))
        }
        return Box()
    }
    
    let determineLogoScaleByArea = VariadicFilter { boxes in
        guard boxes.count == 3,
            let logo = boxes[0].value as? [String: AnyObject],
            let logoWidth = logo["width"] as? Float,
            let logoHeight = logo["height"] as? Float,
            let width = (boxes[1].value as? NSNumber)?.floatValue,
            let height = (boxes[2].value as? NSNumber)?.floatValue
            else { throw MustacheError(kind: .RenderError) }
        let magnification = max(logoWidth / width, logoHeight / height)
        let scale = sqrt(width * height / logoWidth / logoHeight) * magnification
        let (widthScale, heightScale) = width/height > logoWidth/logoHeight ? (1, scale) : (scale, 1)
        return Box([ "widthScale": widthScale, "heightScale": heightScale])
    }
}