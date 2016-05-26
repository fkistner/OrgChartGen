//
//  AppDelegate.swift
//  OrgChartGen
//
//  Created by Florian Kistner on 25/05/16.
//  Copyright © 2016 Florian Kistner. All rights reserved.
//

import Cocoa
import ApplicationServices.ColorSync
import Mustache

protocol Initializable {
    init()
}

extension Array: Initializable {}
extension Dictionary: Initializable {}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        
        let inPath: String
        inPath = Process.arguments[1]
        /*switch Process.arguments.count {
        case 2:
            inPath = Process.arguments[1]
            break
        default:
            print("Usage: \(Process.arguments[0]) path")
            exit(-1)
        }*/
        
        let inURL = NSURL(fileURLWithPath: inPath, isDirectory: true)
        let picturesTeamsURL = inURL.URLByAppendingPathComponent("pictures/Teams")
        let picturesProgramManagersURL = inURL.URLByAppendingPathComponent("pictures/Program Management")
        let logosURL = inURL.URLByAppendingPathComponent("logos")
        
        let teams = enumerateTeams(picturesTeamsURL, logosURL: logosURL)
        let programManagers = enumerateMembers(picturesProgramManagersURL)
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
            .writeToURL(inURL.URLByAppendingPathComponent("org_chart.htm"), atomically: false)
        cssRendered
            .dataUsingEncoding(NSUTF8StringEncoding)?
            .writeToURL(inURL.URLByAppendingPathComponent("org_chart.css"), atomically: false)
        
        exit(0)
    }
    
    func genPalette(noColors: Int) -> [String] {
        return (0..<noColors).map { i in
            let color = NSColor(deviceHue: CGFloat(i)/CGFloat(noColors), saturation: 0.4, brightness: 1.0, alpha: 1.0)
            return "\(Int(round(color.redComponent * 255))),\(Int(round(color.greenComponent * 255))),\(Int(round(color.blueComponent * 255)))"
        }
    }
    
    func extractName(fileName: String) -> [String] {
        let nameParts = Array(fileName.characters.split { $0 == "_" }
            .lazy.dropFirst().map(String.init))
        return nameParts.count > 0 ? nameParts : [fileName]
    }
    
    func enumerateFs<T where T: Initializable>(url: NSURL, descend: Bool = false, action: (T,NSURL) -> T) -> T {
        let memberEnumerator = NSFileManager.defaultManager()
            .enumeratorAtURL(url, includingPropertiesForKeys: [NSURLIsDirectoryKey], options: [.SkipsHiddenFiles, .SkipsSubdirectoryDescendants], errorHandler: nil)
        
        return memberEnumerator?.reduce(T()) { members,memberURL in
            let memberURL = memberURL as! NSURL
            return action(members, memberURL)
        } ?? T()
    }
    
    func enumerateLogos(logosURL: NSURL) -> [String: String] {
        return enumerateFs(logosURL) { (logos: [String: String], logoURL: NSURL) in
            if !logoURL.hasDirectoryPath {
                var logos = logos
                let name = self.extractName(logoURL.URLByDeletingPathExtension!.lastPathComponent!)
                logos[name.first!] = logoURL.absoluteString
                return logos
            }
            return logos
        }
    }
    
    func enumerateMembers(partURL: NSURL) -> [Member] {
        return enumerateFs(partURL) { (members: [Member], memberURL: NSURL) in
            if !memberURL.hasDirectoryPath {
                var members = members
                let name = self.extractName(memberURL.URLByDeletingPathExtension!.lastPathComponent!)
                let member = Member(name: name.first!, teamname: name.count > 1 ? name[1] : nil, imagePath: memberURL.absoluteString)
                members.append(member)
                return members
            }
            return members
        }
    }
    
    func enumerateParts(teamURL: NSURL) -> [String:[Member]] {
        return enumerateFs(teamURL) { (parts: [String:[Member]], partURL: NSURL) in
            if partURL.hasDirectoryPath {
                var parts = parts
                parts[partURL.lastPathComponent!] = self.enumerateMembers(partURL)
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
                let parts = self.enumerateParts(teamURL)
                let name = self.extractName(teamURL.lastPathComponent!).first!
                let team = Team(name: name,
                                logoPath: logos[name],
                                customers:       parts["1_Customer"]!,
                                projectLeaders:  parts["2_Project Leader"]!,
                                coaches:         parts["3_Coach"]!,
                                modelingManager: parts["4_Modeling"]!.first!,
                                releaseManager:  parts["5_Release Mgmt"]!.first!,
                                mergeManager:    parts["6_Merge Mgmt"]!.first!,
                                teamMembers:     parts["9_Team"]!)
                teams.append(team)
                return teams
            }
            return teams
        }
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

}

