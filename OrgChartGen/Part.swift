//
//  Part.swift
//  OrgChartGen
//
//  Created by Florian Kistner on 30/06/16.
//  Copyright © 2016 Florian Kistner. All rights reserved.
//

enum Part {
    case Customer, ProjectLeader, Coach, Modeling, ReleaseMgmt, MergeMgmt, Team
}

extension Part {
    var defaultRole: String? {
        switch self {
        case .ProjectLeader:
            return "Project Leader"
        case .Coach:
            return "Team Coach"
        default:
            return nil
        }
    }
    
    init?(directoryName name: String) {
        switch name {
        case "1_Customer":
            self = .Customer
        case "2_Project Leader":
            self = .ProjectLeader
        case "3_Coach":
            self = .Coach
        case "4_Modeling":
            self = .Modeling
        case "5_Release Mgmt":
            self = .ReleaseMgmt
        case "6_Merge Mgmt":
            self = .MergeMgmt
        case "9_Team":
            self = .Team
        default:
            return nil
        }
    }
}