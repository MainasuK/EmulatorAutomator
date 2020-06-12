//
//  Document.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-4-9.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Cocoa
import CommonOSLog

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
        let sourcesWrapper = fileWrappers[Content.Node.sourcesFileName]
        if sourcesWrapper == nil {
            let sourcesData = try PropertyListEncoder().encode(content.sources)
            documentFileWrapper.addRegularFile(withContents: sourcesData, preferredFilename: Content.Node.sourcesFileName)
        }

        
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
        if let sourcesWrapper = fileWrappers[Content.Node.sourcesFileName],
        let sourcesData = sourcesWrapper.regularFileContents {
            content.sources = try PropertyListDecoder().decode([Content.Node].self, from: sourcesData)
        } else {
            content.sources = []
        }
//
//        // read assets
//        if let assetsWrapper = fileWrappers[FileWrapper.assetsFileName], assetsWrapper.isDirectory {
//            content.assets = traverse(fileWrapper: assetsWrapper)
//        }
    }
    
}

extension Document {
    
    // traverse on root file wrapper to build node tree
//    private func traverse(fileWrapper: FileWrapper) -> [Content.Node] {
//        guard let fileWrappers = fileWrapper.fileWrappers else { return [] }
//
//        var children: [Content.Node] = []
//        for (key, value) in fileWrappers {
//            if value.isDirectory {
//                children.append(Content.Node(name: key, children: traverse(fileWrapper: value)))
//            } else if value.isRegularFile {
//                guard let fileContents = value.regularFileContents else { continue }
//                children.append(Content.Node(name: key, content: fileContents))
//            } else {
//                continue
//            }
//        }
//
//        return children
//    }
    
}

extension Document {

//    func invalidContentSouces() {
//        if let sourcesFileWrapper = documentFileWrapper.fileWrappers?[Content.Node.sourcesFileName] {
//            documentFileWrapper.removeFileWrapper(sourcesFileWrapper)
//        }
//    }
    
    // Update node name
    func updateSources(for contentNode: Content.Node, name: String) {
        contentNode.name = name
        content.objectWillChange.send()
        
        // invalid file wrapper
        if let sourcesFileWrapper = documentFileWrapper.fileWrappers?[Content.Node.sourcesFileName] {
            documentFileWrapper.removeFileWrapper(sourcesFileWrapper)
        }
    }

    // Update file data
    func updateSources(for contentNode: Content.Node, content: String) {
        contentNode.content = content
        
        // invalid file wrapper
        if let sourcesFileWrapper = documentFileWrapper.fileWrappers?[Content.Node.sourcesFileName] {
            documentFileWrapper.removeFileWrapper(sourcesFileWrapper)
        }
    }
    
    // Update file data
    func createSourceNode(node: Content.Node) {
        guard !content.sources.contains(node) else { return }
        content.sources.append(node)
        content.objectWillChange.send()
        
        // invalid file wrapper
        if let sourcesFileWrapper = documentFileWrapper.fileWrappers?[Content.Node.sourcesFileName] {
            documentFileWrapper.removeFileWrapper(sourcesFileWrapper)
        }
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
