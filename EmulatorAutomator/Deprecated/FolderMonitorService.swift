//
//  FolderMonitorService.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-3-29.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import os
import Foundation

protocol FolderMonitorDelegate: class {
    func folderMonitorEventHandler(_ monitor: FolderMonitor)
}

class FolderMonitor {
    
    weak var delegate: FolderMonitorDelegate?
    
    let url: URL
    let fileDescriptor: Int32
    let queue = DispatchQueue.global(qos: .utility)
    let source: DispatchSourceFileSystemObject
    
    init(url: URL) throws {
        self.url = url
        
        // create folder if not exists
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        
        fileDescriptor = open(url.path, O_EVTONLY)
        source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fileDescriptor, eventMask: .write, queue: queue)
        
        
        source.setEventHandler {
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                self.delegate?.folderMonitorEventHandler(self)
            }
        }
        
        source.setCancelHandler {
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                close(self.fileDescriptor)
            }
        }
            
        source.resume()
        os_log(.info, log: .logic, "%{public}s[%{public}ld], %{public}s: observe %s", ((#file as NSString).lastPathComponent), #line, #function, url.path)
    }
    
    deinit {
        source.cancel()
    }
    
}

extension FolderMonitor {
    
    func suspend() {
        source.suspend()
    }
    
    func active() {
        source.activate()
    }
    
}

extension FolderMonitor {
    
    static func applicationSupportDocumentDirectory() throws -> URL {
        let applicationSupportFolderURL = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let folderName = Bundle.main.bundleIdentifier ?? "com.mainasuk.EmulatorAutomator"
        let documentDirectory = applicationSupportFolderURL.appendingPathComponent(folderName, isDirectory: true)
        
        return documentDirectory
    }
    
}
