//
//  Part.swift
//  OrgChartGen
//
//  Created by Florian Kistner on 30/06/16.
//  Copyright © 2016 Florian Kistner. All rights reserved.
//

enum Part {
    case customer, projectLeader, coach, modeling, releaseMgmt, mergeMgmt, team
}

extension Part {
    var defaultRole: String? {
        switch self {
        case .projectLeader:
            return "Project Leader"
        case .coach:
            return "Team Coach"
        default:
            return nil
        }
    }
    
    init?(directoryName name: String) {
        switch name {
        case "1_Customer":
            self = .customer
        case "2_Project Leader":
            self = .projectLeader
        case "3_Coach":
            self = .coach
        case "4_Modeling":
            self = .modeling
        case "5_Release Mgmt":
            self = .releaseMgmt
        case "6_Merge Mgmt":
            self = .mergeMgmt
        case "9_Team":
            self = .team
        default:
            return nil
        }
    }
}
