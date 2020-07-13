//
//  Document.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-4-9.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Cocoa
import CommonOSLog
import MessagePack

class Document: NSDocument {
        
    @objc var content = Content()
    
    private(set) lazy var consoleLogService = ConsoleLogService(id: content.meta.uuid.uuidString)
    
    
    // default untitled document
    lazy var documentFileWrapper: FileWrapper = FileWrapper(directoryWithFileWrappers:[:])
    
    override init() {
        super.init()
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: %{public}s", ((#file as NSString).lastPathComponent), #line, #function, String(describing: self))
    }
    
    override class var autosavesInPlace: Bool {
        return true
    }
    
    override func canAsynchronouslyWrite(to url: URL, ofType typeName: String, for saveOperation: NSDocument.SaveOperationType) -> Bool {
        return true
    }
    
    override func makeWindowControllers() {
        // Returns the storyboard that contains your document window.
        let windowController = AppSceneManager.shared.open(.main(document: self, tabID: 0))
        windowController.contentViewController?.representedObject = self
        
        addWindowController(windowController)
        
    }
    
    override func fileWrapper(ofType typeName: String) throws -> FileWrapper {
        os_log(.info, log: .logic, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        guard let fileWrappers = documentFileWrapper.fileWrappers else {
            throw NSError(domain: NSOSStatusErrorDomain, code: NSFileReadUnknownError, userInfo: nil)
        }
        
        // check and save meta
        let metaWrapper = fileWrappers[Content.Meta.filename]
        if metaWrapper == nil {
            let metaData = try PropertyListEncoder().encode(content.meta)
            documentFileWrapper.addRegularFile(withContents: metaData, preferredFilename: Content.Meta.filename)
        }
        
        // update sources
        let sourcesDirectory: FileWrapper = {
            if let fileWrapper = fileWrappers[FileWrapper.sourcesDirectoryName] {
                return fileWrapper
            } else {
                let fileWrapper = FileWrapper(directoryWithFileWrappers: [:])
                fileWrapper.preferredFilename = FileWrapper.sourcesDirectoryName
                return fileWrapper
            }
        }()
        save(nodes: content.sources, in: sourcesDirectory)
        documentFileWrapper.addFileWrapper(sourcesDirectory)

        // update assets
        let assetDirectory: FileWrapper = {
            if let fileWrapper = fileWrappers[FileWrapper.assetsDirectoryName] {
                return fileWrapper
            } else {
                let fileWrapper = FileWrapper(directoryWithFileWrappers: [:])
                fileWrapper.preferredFilename = FileWrapper.assetsDirectoryName
                return fileWrapper
            }
        }()
        save(nodes: content.assets, in: assetDirectory)
        documentFileWrapper.addFileWrapper(assetDirectory)
        
        return documentFileWrapper
    }
    
    override func read(from fileWrapper: FileWrapper, ofType typeName: String) throws {
        os_log(.info, log: .logic, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)

        // disabel undo when reading document and enable after finish reading
        undoManager?.disableUndoRegistration()
        defer {
            undoManager?.enableUndoRegistration()
        }
        
        guard let fileWrappers = fileWrapper.fileWrappers else {
            throw NSError(domain: NSOSStatusErrorDomain, code: NSFileReadUnknownError, userInfo: nil)
        }
        
        // read meta
        guard let metaWrapper = fileWrappers[Content.Meta.filename],
        let metaData = metaWrapper.regularFileContents else {
            throw NSError(domain: NSOSStatusErrorDomain, code: NSFileReadCorruptFileError, userInfo: nil)
        }
        content.meta = try PropertyListDecoder().decode(Content.Meta.self, from: metaData)
        
        // read sources
        if let sourcesFileWrapper = fileWrappers[FileWrapper.sourcesDirectoryName] {
            content.sources = read(in: sourcesFileWrapper)
        }
        
        // read assets
        if let assetsFileWrapper = fileWrappers[FileWrapper.assetsDirectoryName] {
            content.assets = read(in: assetsFileWrapper)
        }
    }
    
}

extension Document {
    
    private func save(nodes: [Content.Node], in fileWrapper: FileWrapper) {
        guard fileWrapper.isDirectory else {
            assertionFailure()
            return
        }
        
        for node in nodes {
            switch node.content {
            case .directory:
                let directory = FileWrapper(directoryWithFileWrappers: [:])
                directory.preferredFilename = node.name
                fileWrapper.addFileWrapper(directory)
                save(nodes: node.children, in: directory)
            default:
                guard fileWrapper.fileWrappers?[node.id.uuidString] == nil else {
                    continue
                }
                do {
                    let encoded = try MessagePackEncoder().encode(node)
                    fileWrapper.addRegularFile(withContents: encoded, preferredFilename: node.id.uuidString)
                } catch {
                    assertionFailure(error.localizedDescription)
                }
            }
        }
    }

    private func read(in directoryFileWrapper: FileWrapper) -> [Content.Node] {
        guard directoryFileWrapper.isDirectory, let fileWrappers = directoryFileWrapper.fileWrappers else {
            assertionFailure()
            return []
        }
        
        var nodes: [Content.Node] = []
        for (filename, fileWrapper) in fileWrappers {
            if fileWrapper.isDirectory {
                let directoryNode = Content.Node(name: filename, content: .directory)
                directoryNode.children = read(in: fileWrapper)
                nodes.append(directoryNode)
            } else if fileWrapper.isRegularFile, let content = fileWrapper.regularFileContents {
                do {
                    let node = try MessagePackDecoder().decode(Content.Node.self, from: content)
                    nodes.append(node)
                } catch {
                    assertionFailure()
                    continue
                }
            }
        }
        
        return nodes
    }
    
    private func invalid(node: Content.Node, in fileWrapper: FileWrapper) {
        guard fileWrapper.isDirectory else {
            assertionFailure()
            return
        }
        
        for (filename, innerFileWrapper) in fileWrapper.fileWrappers ?? [:] {
            if innerFileWrapper.isDirectory {
                invalid(node: node, in: innerFileWrapper)
            } else if innerFileWrapper.isRegularFile, filename == node.id.uuidString {
                fileWrapper.removeFileWrapper(innerFileWrapper)
                break
            } else {
                continue
            }
        }
    }
    
}

extension Document {
    
    enum NodeType {
        case source
        case asset
    }
    
    // Update node name
    func update(node: Content.Node) {
        content.objectWillChange.send()

        invalid(node: node, in: documentFileWrapper)
    }
    
    // Update file data
    func create(node: Content.Node, type: NodeType) {
        switch type {
        case .source:
            guard !content.sources.contains(node) else { return }
            content.sources.append(node)
        case .asset:
            guard !content.assets.contains(node) else { return }
            content.assets.append(node)
        }
        
        content.objectWillChange.send()
    }
    
    func delete(node: Content.Node, type: NodeType) {
        invalid(node: node, in: documentFileWrapper)
        
        switch type {
        case .source:
            content.sources = delete(node: node, in: content.sources)
        case .asset:
            content.assets = delete(node: node, in: content.assets)
        }
        
        content.objectWillChange.send()
    }
    
    private func delete(node: Content.Node, in nodes: [Content.Node]) -> [Content.Node] {
        var nodes = nodes
        
        if let index = nodes.firstIndex(where: { $0.id == node.id }) {
            nodes.remove(at: index)
        } else {
            for directory in nodes {
                switch directory.content {
                case .directory:
                    directory.children = delete(node: node, in: directory.children)
                default:
                    continue
                }
            }
        }
        
        return nodes
    }
    
}

//extension Document {
//
//    func findTargetAndParentFileWrapper(for contentNode: Content.Node, with root: FileWrapper) -> (target: FileWrapper, parent: FileWrapper)? {
//        guard let fileWrappers = root.fileWrappers else {
//            // no more children for search
//            return nil
//        }
//
//        for (key, value) in fileWrappers {
//            if value.
//            guard let (target, parent) = findTargetAndParentFileWrapper(for: contentNode, with: fileWrapper) else {
//                continue
//            }
//
//            return (target, parent)
//        }
//    }
//
//}
