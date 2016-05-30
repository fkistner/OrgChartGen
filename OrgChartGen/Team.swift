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
    let logoPath: String?
    var color: String?
    let customers: [Member]
    let projectLeaders: [Member]
    let coaches: [Member]
    let modelingManagers: [Member]
    let releaseManagers: [Member]
    let mergeManagers: [Member]
    let teamMembers: [Member]
    
    init(name: String, logoPath: String?, customers: [Member], projectLeaders: [Member], coaches: [Member], modelingManagers: [Member], releaseManagers: [Member], mergeManagers: [Member], teamMembers: [Member]) {
        self.name = name
        self.logoPath = logoPath
        self.customers = customers
        self.projectLeaders = projectLeaders
        self.coaches = coaches
        self.modelingManagers = modelingManagers
        self.releaseManagers = releaseManagers
        self.mergeManagers = mergeManagers
        self.teamMembers = teamMembers
    }
}

func PivotBox(teams: [Team]) -> MustacheBox {
    let props = [
        "name": teams.map({ $0.name }),
        "logoPath": teams.map({ $0.logoPath ?? NSNull() }),
        "customers": teams.map({ $0.customers }),
        "projectLeaders": teams.map({ $0.projectLeaders }),
        "coaches": teams.map({ $0.coaches }),
        "modelingManagers": teams.map({ $0.modelingManagers }),
        "releaseManagers": teams.map({ $0.releaseManagers }),
        "mergeManagers": teams.map({ $0.mergeManagers })
    ]
    return Box(props)
}

extension Team : MustacheBoxable {
    var mustacheBox: MustacheBox {
        var props: [String: AnyObject] = [
            "teamname": name,
            "customers": customers,
            "projectLeaders": projectLeaders,
            "coaches": coaches,
            "modelingManagers": modelingManagers,
            "releaseManagers": releaseManagers,
            "mergeManagers": mergeManagers,
            "teamMembers": teamMembers
        ]
        if let logoPath = logoPath {
            props["logoPath"] = logoPath
        }
        if let color = color {
            props["color"] = color
        }
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
