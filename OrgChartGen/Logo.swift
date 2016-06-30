//
//  Logo.swift
//  OrgChartGen
//
//  Created by Florian Kistner on 30/06/16.
//  Copyright © 2016 Florian Kistner. All rights reserved.
//

import Mustache

class Logo {
    let path: String
    let width: Int
    let height: Int
    let diagonal: Float
    let ratio: Float
    
    init(url: NSURL) {
        let image = NSImage(byReferencingURL: url)
        self.path = url.relativeString!
        width = Int(round(image.size.width))
        height = Int(round(image.size.height))
        diagonal = sqrt(Float(width) * Float(width) + Float(height) * Float(height))
        ratio = Float(max(width, height)) / Float(min(width,height))
    }
}

extension Logo : MustacheBoxable {
    var mustacheBox: MustacheBox {
        let props: [String: AnyObject] = [
            "path": path,
            "width": width,
            "height": height,
            "diagonal": diagonal,
            "ratio": ratio
        ]
        return Box(props)
    }
}
