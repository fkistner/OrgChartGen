//
//  Team.swift
//  OrgChartGen
//
//  Created by Florian Kistner on 25/05/16.
//  Copyright © 2016 Florian Kistner. All rights reserved.
//

import Mustache

class Team {
    let id: String
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
    
    init(id: String, name: String, logo: Logo?, twoColumns: Bool = false, customers: [Member]? = nil, projectLeaders: [Member]? = nil, coaches: [Member]? = nil, modelingManagers: [Member]? = nil, releaseManagers: [Member]? = nil, mergeManagers: [Member]? = nil, teamMembers: [Member]? = nil) {
        self.id = id
        self.name = name
        self.logo = logo
        self.twoColumns = twoColumns
        self.customers = customers ?? []
        self.projectLeaders = projectLeaders ?? []
        self.coaches = coaches ?? []
        self.modelingManagers = modelingManagers ?? []
        self.releaseManagers = releaseManagers ?? []
        self.mergeManagers = mergeManagers ?? []
        self.teamMembers = teamMembers ?? []
    }
}

extension Team : MustacheBoxable {
    var mustacheBox: MustacheBox {
        var props: [String: Any] = [
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
