//
//  Content.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-5-3.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Foundation
import Combine
import EmulatorAutomatorCommon

extension Document {
    class Content: NSObject {
        
        let objectWillChange = PassthroughSubject<Void, Never>()
        
        // init with default value. Update it when open document
        @objc dynamic var meta = Meta()
        @objc dynamic var sources: [Node] = [Node.defaultScriptNode]
        @objc dynamic var assets: [Node] = []
        
        override init() {
            super.init()
        }
        
        init(from fileWrapper: FileWrapper) {
            super.init()
        }
        
    }
}

extension Document.Content {
    class Meta: NSObject, Codable {
        static let filename = "project.plist"
        
        @objc dynamic var objectVersion = ObjectVersion.v1
        @objc dynamic var uuid = UUID()
        
        @objc enum ObjectVersion: Int, CaseIterable, Codable {
            case v1 = 1
            
            static var latest: ObjectVersion {
                return .v1
            }
        }
    }
}

fileprivate extension Document.Content {
    static let defaultScriptFileName = "main.js"
    static let defaultScriptFileContent = "console.log('Hello, world!');\n"
}

extension Document.Content {
    typealias Node = EmulatorAutomatorCommon.Node
}

extension Document.Content.Node {
    static var defaultScriptNode: Node {
        return Node(name: Document.Content.defaultScriptFileName, content: Document.Content.defaultScriptFileContent)
    }
    
    static let sourcesFileName = "sources.ea"
}

extension FileWrapper {
//    static let sourcesFileName = "sources.ea"
    static let assetsFileName = "Assets"
    
//    static var sources: FileWrapper {
//        let scriptWrapper = FileWrapper(regularFileWithContents: Content.defaultScriptFileData)
//        return FileWrapper(directoryWithFileWrappers: [Content.defaultScriptFileName: scriptWrapper])
//    }
//
//    static var assets: FileWrapper {
//        return FileWrapper(directoryWithFileWrappers: [:])
//    }
    
}
