//
//  DirectoryEnumerator.swift
//  OrgChartGen
//
//  Created by Florian Kistner on 30/06/16.
//  Copyright © 2016 Florian Kistner. All rights reserved.
//

import Foundation
import AppKit

private protocol Initializable {
    init()
}

extension Array: Initializable {}
extension Dictionary: Initializable {}

struct OrgChartEnumerator {
    let baseURL: NSURL
    let baseComponents: [String]
    
    let logosURL: NSURL
    let picturesTeamsURL: NSURL
    let picturesProgramManagersURL: NSURL
    let picturesInfraManagersURL: NSURL
    let picturesCrossProjectURL: NSURL
    
    func shouldUseTwoColumns(parts: [Part:[Member]]) -> Bool {
        return parts[.Team]?.count > 4
    }
    
    init(_ inURL: NSURL) {
        baseURL = inURL
        baseComponents = baseURL.pathComponents ?? []
        logosURL = inURL.URLByAppendingPathComponent("CustomerLogos")
        
        let picturesURL = inURL.URLByAppendingPathComponent("Pictures")
        picturesTeamsURL = picturesURL.URLByAppendingPathComponent("Teams")
        picturesProgramManagersURL = picturesURL.URLByAppendingPathComponent("Program Management")
        picturesInfraManagersURL = picturesURL.URLByAppendingPathComponent("Infrastructure")
        picturesCrossProjectURL = picturesURL.URLByAppendingPathComponent("Cross Project")
    }
    
    func enumerateAll() -> (title: String, teams: [Team], programManagers: [Member], infraManagers: [Member], crossProject: Team) {
        let title = extractName(baseURL.lastPathComponent!).name
        let teams = enumerateTeams(picturesTeamsURL, logosURL: logosURL)
        let programManagers = enumerateMembers(picturesProgramManagersURL, defaultRole: "Program Manager")
        let infraManagers = enumerateMembers(picturesInfraManagersURL, defaultRole: nil)
        let crossProject = enumerateTeam(picturesCrossProjectURL)
        
        let colors = genPalette(teams.count)
        for (i,color) in colors.enumerate() {
            teams[i].color = color
        }
        
        return (title: title, teams: teams, programManagers: programManagers, infraManagers: infraManagers, crossProject: crossProject)
    }
    
    func genPalette(noColors: Int) -> [String] {
        return (0..<noColors).map { i in
            let color = NSColor(deviceHue: CGFloat(i)/CGFloat(noColors), saturation: 0.45, brightness: 1.0, alpha: 1.0)
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
            .enumeratorAtURL(url, includingPropertiesForKeys: [NSURLIsDirectoryKey], options: [.SkipsHiddenFiles, .SkipsSubdirectoryDescendants], errorHandler: { url,error in print(error.localizedDescription); return true })
        
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
    
    func enumerateTeam(teamURL: NSURL, logos: [String: Logo] = [:]) -> Team {
        let name = self.extractName(teamURL.lastPathComponent!).name
        let parts = self.enumerateParts(teamURL, teamName: name)
        return Team(name: name,
                    logo: logos[name],
                    twoColumns: shouldUseTwoColumns(parts),
                    customers:        parts[.Customer],
                    projectLeaders:   parts[.ProjectLeader],
                    coaches:          parts[.Coach],
                    modelingManagers: parts[.Modeling],
                    releaseManagers:  parts[.ReleaseMgmt],
                    mergeManagers:    parts[.MergeMgmt],
                    teamMembers:      parts[.Team])
    }
    
    func enumerateTeams(teamsURL: NSURL, logosURL: NSURL) -> [Team] {
        var logos = enumerateLogos(logosURL)
        var teams = enumerateFs(teamsURL) { (teams: [Team], teamURL: NSURL) in
            if teamURL.hasDirectoryPath {
                var teams = teams
                let team = self.enumerateTeam(teamURL, logos: logos)
                teams.append(team)
                return teams
            }
            return teams
        }
        for team in teams {
            logos.removeValueForKey(team.name)
        }
        for (name,logo) in logos {
            teams.append(Team(name: name, logo: logo))
        }
        teams.sortInPlace { a,b in a.name < b.name }
        return teams
    }
}