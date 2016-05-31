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
    let picturesInfraManagersURL: NSURL
    let picturesCrossProjectURL: NSURL
    let logosURL: NSURL
    
    init(_ inURL: NSURL) {
        baseURL = inURL
        baseComponents = baseURL.pathComponents ?? []
        picturesTeamsURL = inURL.URLByAppendingPathComponent("pictures/Teams")
        picturesProgramManagersURL = inURL.URLByAppendingPathComponent("pictures/Program Management")
        picturesInfraManagersURL = inURL.URLByAppendingPathComponent("pictures/Infrastructure")
        picturesCrossProjectURL = inURL.URLByAppendingPathComponent("pictures/Cross Project")
        logosURL = inURL.URLByAppendingPathComponent("logos")
    }
    
    func generate(to htmlURL: NSURL) {
        let teams = enumerateTeams(picturesTeamsURL, logosURL: logosURL)
        let programManagers = enumerateMembers(picturesProgramManagersURL, defaultRole: "Program Manager")
        let infraManagers = enumerateMembers(picturesInfraManagersURL, defaultRole: nil)
        let crossProject = teamFromURL(picturesCrossProjectURL, logos: [:])
        
        let colors = genPalette(teams.count)
        for (i,color) in colors.enumerate() {
            teams[i].color = color
        }
        
        let box = Box([
            "teams": teams,
            "programManagers": programManagers,
            "infraManagers": infraManagers,
            "crossProject": crossProject
        ])
        
        let htmlRepo = TemplateRepository(bundle: NSBundle.mainBundle(), templateExtension: "htm")
        let cssRepo = TemplateRepository(bundle: NSBundle.mainBundle(), templateExtension: "css")
        let htmlTemplate = try! htmlRepo.template(named: "org_chart")
        let cssTemplate = try! cssRepo.template(named: "org_chart")
        
        for template in [htmlTemplate, cssTemplate] {
            template.extendBaseContext(MustacheBox(keyedSubscript: literalSubscript))
            template.registerInBaseContext("logoScale", Box(determineLogoScaleByArea))
            template.registerInBaseContext("each", Box(StandardLibrary.each))
        }
        
        let htmlRendered = try! htmlTemplate.render(box)
        let cssRendered = try! cssTemplate.render(box)
        
        htmlRendered
            .dataUsingEncoding(NSUTF8StringEncoding)?
            .writeToURL(htmlURL, atomically: false)
        let cssURL = htmlURL.URLByDeletingPathExtension!.URLByAppendingPathExtension("css")
        cssRendered
            .dataUsingEncoding(NSUTF8StringEncoding)?
            .writeToURL(cssURL, atomically: false)
    }
    
    let literalSubscript: KeyedSubscriptFunction = { key in
        if let intValue = Int(key) {
            return Box(NSNumber(integer: intValue))
        } else if let floatValue = Float(key) {
            return Box(NSNumber(float: floatValue))
        }
        return Box()
    }
    
    let determineLogoScaleByArea = VariadicFilter { boxes in
        guard boxes.count == 3,
            let logo = boxes[0].value as? [String: AnyObject],
            let logoWidth = logo["width"] as? Float,
            let logoHeight = logo["height"] as? Float,
            let width = (boxes[1].value as? NSNumber)?.floatValue,
            let height = (boxes[2].value as? NSNumber)?.floatValue
            else { throw MustacheError(kind: .RenderError) }
        let magnification = max(logoWidth / width, logoHeight / height)
        let scale = sqrt(width * height / logoWidth / logoHeight) * magnification
        let (widthScale, heightScale) = width/height > logoWidth/logoHeight ? (1, scale) : (scale, 1)
        return Box([ "widthScale": widthScale, "heightScale": heightScale])
    }
    
    func genPalette(noColors: Int) -> [String] {
        return (0..<noColors).map { i in
            let color = NSColor(deviceHue: CGFloat(i)/CGFloat(noColors), saturation: 0.4, brightness: 1.0, alpha: 1.0)
            return "\(Int(round(color.redComponent * 255))),\(Int(round(color.greenComponent * 255))),\(Int(round(color.blueComponent * 255)))"
        }
    }
    
    func extractName(fileName: String) -> (name: String, roles: [String]?) {
        let fileName = fileName.stringByReplacingOccurrencesOfString(":", withString: "/")
        let nameParts = fileName.characters.split { $0 == "_" }.dropFirst()
        let name = nameParts.first.flatMap(String.init) ?? fileName
        let roles = nameParts.count > 1 ? nameParts.dropFirst().map(String.init) : nil as [String]?
        return (name: name, roles: roles)
    }
    
    func resolveRelativeComponents(components: [String]) -> [String] {
        var common = min(baseComponents.count, components.count)
        for i in 0..<common {
            if baseComponents[i] != components[i] {
                common = i
                break
            }
        }
        
        let up = Repeat<String>(count: baseComponents.count - common, repeatedValue: "..")
        let down = components.dropFirst(common)
        return Array(up) + down
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
    
    func enumerateLogos(logosURL: NSURL) -> [String: Logo] {
        return enumerateFs(logosURL) { (logos: [String: Logo], logoURL: NSURL) in
            if !logoURL.hasDirectoryPath {
                var logos = logos
                let name = self.extractName(logoURL.URLByDeletingPathExtension!.lastPathComponent!)
                logos[name.name] = Logo(url: logoURL)
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
                let roles = name.roles ?? defaultRole.flatMap{ [$0] } ?? []
                let member = Member(name: name.name, roles: roles, imagePath: memberURL.relativeString!)
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
    
    func teamFromURL(teamURL: NSURL, logos: [String: Logo]) -> Team {
        let name = self.extractName(teamURL.lastPathComponent!).name
        let parts = self.enumerateParts(teamURL, teamName: name)
        return Team(name: name,
                    logo: logos[name],
                    twoColumns: parts[.Team]?.count > 4,
                    customers:        parts[.Customer] ?? [],
                    projectLeaders:   parts[.ProjectLeader] ?? [],
                    coaches:          parts[.Coach] ?? [],
                    modelingManagers: parts[.Modeling] ?? [],
                    releaseManagers:  parts[.ReleaseMgmt] ?? [],
                    mergeManagers:    parts[.MergeMgmt] ?? [],
                    teamMembers:      parts[.Team] ?? [])
    }
    
    func enumerateTeams(teamsURL: NSURL, logosURL: NSURL) -> [Team] {
        let logos = enumerateLogos(logosURL)
        return enumerateFs(teamsURL) { (teams: [Team], teamURL: NSURL) in
            if teamURL.hasDirectoryPath {
                var teams = teams
                let team = self.teamFromURL(teamURL, logos: logos)
                teams.append(team)
                return teams
            }
            return teams
        }
    }
}