//
//  ScreencapViewController.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-5-4.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

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
