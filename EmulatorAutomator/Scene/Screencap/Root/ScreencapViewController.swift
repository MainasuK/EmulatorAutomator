//
//  ScreencapViewController.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-5-4.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import os
import Cocoa
import Combine
import SwiftUI
import CocoaPreviewProvider

final class ScreencapViewModel {
    // input & output
    let screencapTriggerRelay = PassthroughSubject<Void, Never>()
}

final class ScreencapViewController: NSViewController {
    
    var scene: AppScene?
    
    var disposeBag = Set<AnyCancellable>()
    let viewModel = ScreencapViewModel()
    var screencapStore = ScreencapStore()
    
    let splitViewController = ScreencapSplitViewController()
    
    override func loadView() {
        view = NSView()
    }
    
    override var representedObject: Any? {
        didSet {
            // Pass down the represented object to all of the child view controllers.
            for child in children {
                child.representedObject = representedObject
            }
        }
    }
    
    weak var document: Document? {
        return representedObject as? Document
    }
    
}

extension ScreencapViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set view environment object
        splitViewController.screencapContentViewController.screencapStore = screencapStore
        splitViewController.screencapUtilityViewController.screencapStore = screencapStore
        
        addChild(splitViewController)
        splitViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(splitViewController.view)
        NSLayoutConstraint.activate([
            splitViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            splitViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            splitViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            splitViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        viewModel.screencapTriggerRelay
            .sink { [weak self] _ in
                self?.screencapStore.dispatch(.takeScreenshot)
            }
            .store(in: &disposeBag)
        
        screencapStore.screencapState.utility.saveAssetActionPublisher
            .sink { [weak self] image in
                guard let `self` = self else { return }
                guard let window = self.view.window else { return }
                
                guard let document = self.document else {
                    assertionFailure()
                    return
                }
                
                let saveAssetWindowController = AppSceneManager.shared.open(.saveAsset(document: document, screencapStore: self.screencapStore))
                guard let saveAssetWindow = saveAssetWindowController.window else {
                    assertionFailure()
                    return
                }
                window.beginSheet(saveAssetWindow) { response in
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: save asset modal response", ((#file as NSString).lastPathComponent), #line, #function, String(describing: response))
                    saveAssetWindow.close()
                }
            }
            .store(in: &disposeBag)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        // trigger init screenshot
        viewModel.screencapTriggerRelay.send(Void())
    }
    
}


struct ScreencapViewController_Previews: PreviewProvider {
    static var previews: some View {
        NSViewControllerPreview {
            ScreencapViewController()
        }
    }
}
