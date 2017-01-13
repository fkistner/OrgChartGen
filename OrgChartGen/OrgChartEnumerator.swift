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
    let baseURL: URL
    let baseComponents: [String]
    
    let logosURL: URL
    let picturesTeamsURL: URL
    let picturesProgramManagersURL: URL
    let picturesInfraManagersURL: URL
    let picturesCrossProjectURL: URL
    
    func shouldUseTwoColumns(_ parts: [Part:[Member]]) -> Bool {
        return parts[.team]?.count ?? 0 > 5
    }
    
    init(at inURL: URL) {
        baseURL = inURL
        baseComponents = baseURL.pathComponents 
        logosURL = inURL.appendingPathComponent("CustomerLogos")
        
        let picturesURL = inURL.appendingPathComponent("Pictures")
        picturesTeamsURL = picturesURL.appendingPathComponent("Teams")
        picturesProgramManagersURL = picturesURL.appendingPathComponent("Program Management")
        picturesInfraManagersURL = picturesURL.appendingPathComponent("Infrastructure")
        picturesCrossProjectURL = picturesURL.appendingPathComponent("Cross Project")
    }
    
    func enumerateAll() -> (title: String, teams: [Team], programManagers: [Member], infraManagers: [Member], crossProject: Team) {
        let title = parse(fileName: baseURL.lastPathComponent).name
        let teams = enumerateTeams(at: picturesTeamsURL, logosURL: logosURL)
        let programManagers = enumerateMembers(at: picturesProgramManagersURL, defaultRole: "Program Manager")
        let infraManagers = enumerateMembers(at: picturesInfraManagersURL, defaultRole: nil)
        let crossProject = enumerateTeam(at: picturesCrossProjectURL)
        
        let colors = genPalette(size: teams.count)
        for (i,color) in colors.enumerated() {
            teams[i].color = color
        }
        
        return (title: title, teams: teams, programManagers: programManagers, infraManagers: infraManagers, crossProject: crossProject)
    }
    
    func genPalette(size: Int) -> [String] {
        return (0..<size).map { i in
            let color = NSColor(deviceHue: CGFloat(i)/CGFloat(size), saturation: 0.45, brightness: 1.0, alpha: 1.0)
            return "\(Int(round(color.redComponent * 255))),\(Int(round(color.greenComponent * 255))),\(Int(round(color.blueComponent * 255)))"
        }
    }
    
    func parse(fileName: String) -> (name: String, roles: [String]?) {
        let fileName = fileName.replacingOccurrences(of: ":", with: "/")
        let nameParts = fileName.characters.split { $0 == "_" }.dropFirst()
        let name = nameParts.first.flatMap(String.init) ?? fileName
        let roles = nameParts.count > 1 ? nameParts.dropFirst().map(String.init) : nil as [String]?
        return (name: name, roles: roles)
    }
    
    func resolveRelative(components: [String]) -> [String] {
        var common = min(baseComponents.count, components.count)
        for i in 0..<common {
            if baseComponents[i] != components[i] {
                common = i
                break
            }
        }
        
        let up = repeatElement("..", count: baseComponents.count - common)
        let down = components.dropFirst(common)
        return Array(up) + down
    }
    
    fileprivate func enumerateFs<T>(at url: URL, descend: Bool = false, action: (T,URL) -> T) -> T where T: Initializable {
        let relativeComponents = resolveRelative(components: url.pathComponents)
        let memberEnumerator = FileManager.default
            .enumerator(at: url, includingPropertiesForKeys: [URLResourceKey.isDirectoryKey], options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants], errorHandler: { url,error in print(error.localizedDescription); return true })
        
        return memberEnumerator?.reduce(T()) { members,memberURL in
            let memberURL = memberURL as! URL
            let components = relativeComponents + memberURL.pathComponents.dropFirst(url.pathComponents.count)
            let relURL = URL(fileURLWithPath: NSString.path(withComponents: components), relativeTo: baseURL)
            return action(members, relURL)
            } ?? T()
    }
    
    func enumerateLogos(at logosURL: URL) -> [String: Logo] {
        return enumerateFs(at: logosURL) { (logos: [String: Logo], logoURL: URL) in
            if !logoURL.hasDirectoryPath {
                var logos = logos
                let id = logoURL.deletingPathExtension().lastPathComponent
                logos[id] = Logo(url: logoURL)
                return logos
            }
            return logos
        }
    }
    
    func enumerateMembers(at partURL: URL, defaultRole: String?) -> [Member] {
        return enumerateFs(at: partURL) { (members: [Member], memberURL: URL) in
            if !memberURL.hasDirectoryPath {
                var members = members
                let name = self.parse(fileName: memberURL.deletingPathExtension().lastPathComponent)
                let roles = name.roles ?? defaultRole.flatMap{ [$0] } ?? []
                let member = Member(name: name.name, roles: roles, imagePath: memberURL.relativeString)
                members.append(member)
                return members
            }
            return members
        }
    }
    
    func enumerateParts(at teamURL: URL, teamName: String) -> [Part:[Member]] {
        return enumerateFs(at: teamURL) { (parts: [Part:[Member]], partURL: URL) in
            if partURL.hasDirectoryPath,
                let part = Part(directoryName: partURL.lastPathComponent) {
                var parts = parts
                let defaultRole = part == .customer ? teamName : part.defaultRole
                parts[part] = self.enumerateMembers(at: partURL, defaultRole: defaultRole)
                return parts
            }
            return parts
        }
    }
    
    func enumerateTeam(at teamURL: URL, logos: [String: Logo] = [:]) -> Team {
        let id = teamURL.lastPathComponent
        let name = self.parse(fileName: id).name
        let parts = self.enumerateParts(at: teamURL, teamName: name)
        return Team(id: id,
                    name: name,
                    logo: logos[id],
                    twoColumns: shouldUseTwoColumns(parts),
                    customers:        parts[.customer],
                    projectLeaders:   parts[.projectLeader],
                    coaches:          parts[.coach],
                    modelingManagers: parts[.modeling],
                    releaseManagers:  parts[.releaseMgmt],
                    mergeManagers:    parts[.mergeMgmt],
                    teamMembers:      parts[.team])
    }
    
    func enumerateTeams(at teamsURL: URL, logosURL: URL) -> [Team] {
        var logos = enumerateLogos(at: logosURL)
        var teams = enumerateFs(at: teamsURL) { (teams: [Team], teamURL: URL) in
            if teamURL.hasDirectoryPath {
                var teams = teams
                let team = self.enumerateTeam(at: teamURL, logos: logos)
                teams.append(team)
                return teams
            }
            return teams
        }
        for team in teams {
            logos.removeValue(forKey: team.id)
        }
        for (id,logo) in logos {
            let name = self.parse(fileName: id).name
            teams.append(Team(id: id, name: name, logo: logo))
        }
        teams.sort { a,b in a.id < b.id }
        return teams
    }
}
