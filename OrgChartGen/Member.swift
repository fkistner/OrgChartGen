//
//  Member.swift
//  OrgChartGen
//
//  Created by Florian Kistner on 30/06/16.
//  Copyright © 2016 Florian Kistner. All rights reserved.
//

import Mustache

class Member {
    let name: String
    let roles: [String]
    let imagePath: String
    
    init(name: String, roles: [String], imagePath: String) {
        self.name = name
        self.roles = roles
        self.imagePath = imagePath
    }
}

extension Member : MustacheBoxable {
    var mustacheBox: MustacheBox {
        let props: [String: AnyObject] = [
            "name": name,
            "roles": roles,
            "imagePath": imagePath
        ]
        return Box(props)
    }
}
