//
//  Candy.swift
//  XcodeProj
//
//  Created by apple on 2019/5/18.
//

import Foundation
import PathKit

public final class Candy {
    
    public let path: Path
    public let xcodeproj: XcodeProj
    
    public init(path: Path) throws {
        self.path = path
        self.xcodeproj = try XcodeProj(path: path)
    }
    
}

// MARK: - Properties

public enum CandyError: Error, CustomStringConvertible {
    case notFound(reason: String)
    
    public var description: String {
        switch self {
        case let .notFound(reason):
            return "The project cannot be found with \(reason)"
        }
    }
}

public extension Candy {
    var pbxproj: PBXProj {
        return xcodeproj.pbxproj
    }
    
    var applicationTargets: [PBXNativeTarget] {
        let nativeTargets = pbxproj.nativeTargets
        print("nativeTargets: \(nativeTargets.map { $0.name })")
        let targets = nativeTargets.filter { $0.productType == .application }
        return targets
    }
    
    func mainTarget() throws -> PBXNativeTarget {
        guard let mainTarget = applicationTargets.first else {
            throw CandyError.notFound(reason: "applicationTargets")
        }
        return mainTarget
    }
    
    func sourceGroups() throws -> [PBXGroup] {
        guard let rootObject = pbxproj.rootObject else {
            throw CandyError.notFound(reason: "rootObject")
        }
        print("rootObject: \(rootObject)")
        
        guard let mainGroup = rootObject.mainGroup else {
            throw CandyError.notFound(reason: "mainGroup")
        }
        print("mainGroup: \(mainGroup)")
        
        let sourceGroups = mainGroup.children.filter { (element) -> Bool in
            guard let group = element as? PBXGroup else {
                return false
            }
            guard let path = group.path else {
                return false
            }
            guard path != "Products" &&
                path != "Frameworks" else {
                    return false
            }
            guard (!path.hasSuffix("Tests")) &&
                (!path.hasSuffix("UITests")) else {
                    return false
            }
            return true
            } as! [PBXGroup]
        print("sourceGroups: \(sourceGroups)")
        
        return sourceGroups
    }
    
    func sourceGroup() throws -> PBXGroup {
        guard let sourceGroup = try sourceGroups().first else {
            throw CandyError.notFound(reason: "sourceGroups")
        }
        return sourceGroup
    }
    
    func sourcePath() throws -> Path {
        let sourceGroup = try self.sourceGroup()
        print("sourceGroup: \(sourceGroup)")
        
        let sourcePath = try fullPath(element: sourceGroup)
        
        return sourcePath
    }
    
    var projectPath: Path {
        if path.lastComponent.contains("xcodeproj") {
            let newPathString = path.components.dropLast().joined(separator: "/")
            return Path(newPathString)
        } else {
            return path
        }
    }
    
    func fullPath(element: PBXFileElement) throws -> Path {
        guard let path = try element.fullPath(sourceRoot: projectPath) else {
            throw CandyError.notFound(reason: "fullPath for element: \(element)")
        }
        return path
        
//        var elementPath = Path("")
//
//        var parent: PBXFileElement? = element
//        repeat {
//            if let path = parent?.path {
//                elementPath = Path(path) + elementPath
//            }
//            parent = parent?.parent
//        } while (parent != nil)
//
//        elementPath = projectPath + elementPath
//
//        return elementPath
    }
    
}

// MARK: - Methods

public extension Candy {
    
    func addGroup(_ groupName: String, options: GroupAddingOptions = []) throws -> [PBXGroup] {
        let newGroupPath = try sourcePath() + Path(groupName)
        
        if !newGroupPath.exists || !newGroupPath.isDirectory {
            print("Will create group path: \(newGroupPath)")
            
            try FileManager.default.createDirectory(atPath: newGroupPath.string, withIntermediateDirectories: true, attributes: nil)
        }
        
        let sourceGroup = try self.sourceGroup()
        let newGroups = try sourceGroup.addGroup(named: groupName, options: options)
        print("newGroups: \(newGroups)")
        
        /*
         Align xcode
         options:
         default: name == nil, path != nil
         withoutFolder: name != nil, path == nil
         */
        if !options.contains(.withoutFolder) {
            newGroups.forEach { (group) in
                group.name = nil
            }
            print("Align xcode newGroups: \(newGroups)")
        }
        
        return newGroups
    }
    
    func addFile(at group: PBXGroup, fileName: String, contents: Data? = nil) throws -> PBXFileReference {
        let groupPath = try fullPath(element: group)
        let filePath = groupPath + Path(fileName)
        
//        if !filePath.exists && !filePath.isFile {
            FileManager.default.createFile(atPath: filePath.string, contents: contents, attributes: nil)
//        }
        
        let file = try group.addFile(at: filePath, sourceRoot: path)
        print("file: \(file)")
        
        /*
         Align xcode
         */
        file.explicitFileType = nil
        file.name = nil
        file.path = fileName
        
        return file
    }
    
    func addBuildPhase(with file: PBXFileReference) throws -> PBXBuildFile? {
        return try mainTarget().sourcesBuildPhase()?.add(file: file)
    }
    
}

public extension Candy {
    func write(override: Bool = true) throws {
        try xcodeproj.write(path: path, override: override)
    }
}
