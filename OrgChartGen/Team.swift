//
//  Team.swift
//  OrgChartGen
//
//  Created by Florian Kistner on 25/05/16.
//  Copyright © 2016 Florian Kistner. All rights reserved.
//

import Foundation
import Mustache

class Team {
    let name: String
    let logo: Logo?
    var color: String?
    let twoColumns: Bool
    let customers: [Member]
    let projectLeaders: [Member]
    let coaches: [Member]
    let modelingManagers: [Member]
    let releaseManagers: [Member]
    let mergeManagers: [Member]
    let teamMembers: [Member]
    
    init(name: String, logo: Logo?, twoColumns: Bool, customers: [Member], projectLeaders: [Member], coaches: [Member], modelingManagers: [Member], releaseManagers: [Member], mergeManagers: [Member], teamMembers: [Member]) {
        self.name = name
        self.logo = logo
        self.twoColumns = twoColumns
        self.customers = customers
        self.projectLeaders = projectLeaders
        self.coaches = coaches
        self.modelingManagers = modelingManagers
        self.releaseManagers = releaseManagers
        self.mergeManagers = mergeManagers
        self.teamMembers = teamMembers
    }
}

extension Team : MustacheBoxable {
    var mustacheBox: MustacheBox {
        var props: [String: AnyObject] = [
            "teamname": name,
            "twoColumns": twoColumns,
            "customers": customers,
            "projectLeaders": projectLeaders,
            "coaches": coaches,
            "modelingManagers": modelingManagers,
            "releaseManagers": releaseManagers,
            "mergeManagers": mergeManagers,
            "teamMembers": teamMembers
        ]
        if let logo = logo {
            props["logo"] = logo
        }
        if let color = color {
            props["color"] = color
        }
        return Box(props)
    }
}

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
