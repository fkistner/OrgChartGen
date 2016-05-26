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
    let modelingManager: Member
    let releaseManager: Member
    let mergeManager: Member
    let teamMembers: [Member]
    
    init(name: String, logoPath: String?, customers: [Member], projectLeaders: [Member], coaches: [Member], modelingManager: Member, releaseManager: Member, mergeManager: Member, teamMembers: [Member]) {
        self.name = name
        self.logoPath = logoPath
        self.customers = customers
        self.projectLeaders = projectLeaders
        self.coaches = coaches
        self.modelingManager = modelingManager
        self.releaseManager = releaseManager
        self.mergeManager = mergeManager
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
        "modelingManager": teams.map({ $0.modelingManager }),
        "releaseManager": teams.map({ $0.releaseManager }),
        "mergeManager": teams.map({ $0.mergeManager })
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
            "modelingManager": modelingManager,
            "releaseManager": releaseManager,
            "mergeManager": mergeManager,
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
    let teamname: String?
    let imagePath: String
    
    init(name: String, teamname: String?, imagePath: String) {
        self.name = name
        self.teamname = teamname
        self.imagePath = imagePath
    }
}

extension Member : MustacheBoxable {
    var mustacheBox: MustacheBox {
        var props: [String: AnyObject] = [
            "name": name,
            "imagePath": imagePath
        ]
        if let teamname = teamname {
            props["teamname"] = teamname
        }
        return Box(props)
    }
}
