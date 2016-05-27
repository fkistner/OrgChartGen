//
//  Generator.swift
//  OrgChartGen
//
//  Created by Florian Kistner on 26/05/16.
//  Copyright © 2016 Florian Kistner. All rights reserved.
//

import Foundation
import Mustache

private protocol Initializable {
    init()
}

extension Array: Initializable {}
extension Dictionary: Initializable {}

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

class HTMLGenerator {
    let baseURL: NSURL
    let baseComponents: [String]
    
    let picturesTeamsURL: NSURL
    let picturesProgramManagersURL: NSURL
    let logosURL: NSURL
    
    init(_ inURL: NSURL) {
        baseURL = inURL
        baseComponents = baseURL.pathComponents ?? []
        picturesTeamsURL = inURL.URLByAppendingPathComponent("pictures/Teams")
        picturesProgramManagersURL = inURL.URLByAppendingPathComponent("pictures/Program Management")
        logosURL = inURL.URLByAppendingPathComponent("logos")
    }
    
    func generate(to outURL: NSURL) {
        let teams = enumerateTeams(picturesTeamsURL, logosURL: logosURL)
        let programManagers = enumerateMembers(picturesProgramManagersURL, defaultRole: "Program Manager")
        let colors = genPalette(teams.count)
        
        for (i,color) in colors.enumerate() {
            teams[i].color = color
        }
        
        let box = Box(["teams": teams, "programManagers": programManagers])
        
        let htmlRepo = TemplateRepository(bundle: NSBundle.mainBundle(), templateExtension: "htm")
        let cssRepo = TemplateRepository(bundle: NSBundle.mainBundle(), templateExtension: "css")
        let htmlTemplate = try! htmlRepo.template(named: "org_chart")
        let cssTemplate = try! cssRepo.template(named: "org_chart")
        cssTemplate.registerInBaseContext("each", Box(StandardLibrary.each))
        
        let htmlRendered = try! htmlTemplate.render(box)
        let cssRendered = try! cssTemplate.render(box)
        
        htmlRendered
            .dataUsingEncoding(NSUTF8StringEncoding)?
            .writeToURL(outURL.URLByAppendingPathComponent("org_chart.htm"), atomically: false)
        cssRendered
            .dataUsingEncoding(NSUTF8StringEncoding)?
            .writeToURL(outURL.URLByAppendingPathComponent("org_chart.css"), atomically: false)
    }
    
    func genPalette(noColors: Int) -> [String] {
        return (0..<noColors).map { i in
            let color = NSColor(deviceHue: CGFloat(i)/CGFloat(noColors), saturation: 0.4, brightness: 1.0, alpha: 1.0)
            return "\(Int(round(color.redComponent * 255))),\(Int(round(color.greenComponent * 255))),\(Int(round(color.blueComponent * 255)))"
        }
    }
    
    func extractName(fileName: String) -> [String] {
        let fileName = fileName.stringByReplacingOccurrencesOfString(":", withString: "/")
        let nameParts = Array(fileName.characters.split { $0 == "_" }
            .lazy.dropFirst().map(String.init))
        return nameParts.count > 0 ? nameParts : [fileName]
    }
    
    func resolveRelativeComponents(components: [String]) -> [String] {
        let totalLength  = max(self.baseComponents.count, components.count)
        
        var baseComponents: [String?] = self.baseComponents.map { $0 }
        baseComponents.appendContentsOf(Repeat(count: totalLength - self.baseComponents.count, repeatedValue: nil))
        var components: [String?] = components.map { $0 }
        components.appendContentsOf(Repeat(count: totalLength - components.count, repeatedValue: nil))
        
        var common = true
        var up = [String]()
        var down = [String]()
        
        for (b,c) in zip(baseComponents, components) {
            if b != c {
                common = false
            }
            if !common, let _ = b {
                up.append("..")
            }
            if !common, let c = c {
                down.append(c)
            }
        }
        return up + down
    }
    
    private func enumerateFs<T where T: Initializable>(url: NSURL, descend: Bool = false, action: (T,NSURL) -> T) -> T {
        let relativeComponents = resolveRelativeComponents(url.pathComponents!)
        let memberEnumerator = NSFileManager.defaultManager()
            .enumeratorAtURL(url, includingPropertiesForKeys: [NSURLIsDirectoryKey], options: [.SkipsHiddenFiles, .SkipsSubdirectoryDescendants], errorHandler: nil)
        
        return memberEnumerator?.reduce(T()) { members,memberURL in
            let memberURL = memberURL as! NSURL
            let components = relativeComponents + memberURL.pathComponents!.dropFirst(url.pathComponents!.count)
            let relURL = NSURL(fileURLWithPath: NSString.pathWithComponents(components), relativeToURL: baseURL)
            return action(members, relURL)
        } ?? T()
    }
    
    func enumerateLogos(logosURL: NSURL) -> [String: String] {
        return enumerateFs(logosURL) { (logos: [String: String], logoURL: NSURL) in
            if !logoURL.hasDirectoryPath {
                var logos = logos
                let name = self.extractName(logoURL.URLByDeletingPathExtension!.lastPathComponent!)
                logos[name.first!] = logoURL.relativeString!
                return logos
            }
            return logos
        }
    }
    
    func enumerateMembers(partURL: NSURL, defaultRole: String?) -> [Member] {
        return enumerateFs(partURL) { (members: [Member], memberURL: NSURL) in
            if !memberURL.hasDirectoryPath {
                var members = members
                let name = self.extractName(memberURL.URLByDeletingPathExtension!.lastPathComponent!)
                let member = Member(name: name.first!, role: name.count > 1 ? name[1] : defaultRole, imagePath: memberURL.relativeString!)
                members.append(member)
                return members
            }
            return members
        }
    }
    
    func enumerateParts(teamURL: NSURL, teamName: String) -> [Part:[Member]] {
        return enumerateFs(teamURL) { (parts: [Part:[Member]], partURL: NSURL) in
            if partURL.hasDirectoryPath,
                let part = Part(directoryName: partURL.lastPathComponent!) {
                var parts = parts
                let defaultRole = part == .Customer ? teamName : part.defaultRole
                parts[part] = self.enumerateMembers(partURL, defaultRole: defaultRole)
                return parts
            }
            return parts
        }
    }
    
    func enumerateTeams(teamsURL: NSURL, logosURL: NSURL) -> [Team] {
        let logos = enumerateLogos(logosURL)
        return enumerateFs(teamsURL) { (teams: [Team], teamURL: NSURL) in
            if teamURL.hasDirectoryPath {
                var teams = teams
                let name = self.extractName(teamURL.lastPathComponent!).first!
                let parts = self.enumerateParts(teamURL, teamName: name)
                let team = Team(name: name,
                                logoPath: logos[name],
                                customers:        parts[.Customer] ?? [],
                                projectLeaders:   parts[.ProjectLeader] ?? [],
                                coaches:          parts[.Coach] ?? [],
                                modelingManagers: parts[.Modeling] ?? [],
                                releaseManagers:  parts[.ReleaseMgmt] ?? [],
                                mergeManagers:    parts[.MergeMgmt] ?? [],
                                teamMembers:      parts[.Team] ?? [])
                teams.append(team)
                return teams
            }
            return teams
        }
    }
}