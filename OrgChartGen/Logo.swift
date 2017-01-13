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
    let width: CGFloat
    let height: CGFloat
    let diagonal: CGFloat
    let ratio: CGFloat
    
    init(url: URL) {
        let image = NSImage(byReferencing: url)
        self.path = url.relativeString
        width = image.size.width
        height = image.size.height
        diagonal = sqrt(width * width + height * height)
        ratio = max(width, height) / min(width, height)
    }
}

extension Logo : MustacheBoxable {
    var mustacheBox: MustacheBox {
        let props: [String: Any] = [
            "path": path,
            "width": width,
            "height": height,
            "diagonal": diagonal,
            "ratio": ratio
        ]
        return Box(props)
    }
}
