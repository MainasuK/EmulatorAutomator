//
//  ScreencapViewController.swift
//  EmulatorAutomator
//
//  Created by MainasuK Cirno on 2020/3/14.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Cocoa
import Combine
import SwiftUI

final class ScreencapViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    let asset = CurrentValueSubject<Asset?, Never>(nil)
    let currentScreencap = CurrentValueSubject<NSImage?, Never>(nil)
    
    init() {
        let updateQueue = DispatchQueue.global(qos: .userInitiated)
        asset
            .subscribe(on: updateQueue)
            .map { asset -> NSImage? in
                guard let asset = asset else { return nil }
                return NSImage(contentsOf: asset.imageURL)
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.value, on: currentScreencap)
            .store(in: &disposeBag)
    }
    
}

final class ScreencapViewController: NSViewController {
    
    var disposeBag = Set<AnyCancellable>()
    let viewModel = ScreencapViewModel()

    let screencapContentView = NSHostingView(rootView: ScreencapContentView())
    
    override func loadView() {
        view = NSView()
    }
    
}

extension ScreencapViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        screencapContentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(screencapContentView)
        NSLayoutConstraint.activate([
            screencapContentView.topAnchor.constraint(equalTo: view.topAnchor),
            screencapContentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            screencapContentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            screencapContentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        NotificationCenter.default.addObserver(self, selector: #selector(ScreencapViewController.didSelecteAsset(_:)), name: AssetTableViewController.NotificationName.didSelectAsset, object: nil)
        
        // listen screencap
        viewModel.currentScreencap
            .receive(on: DispatchQueue.main)
            .sink { image in
                self.screencapContentView.rootView.screencapImgae.image = image ?? NSImage()
            }
            .store(in: &disposeBag)
    }
    
}

extension ScreencapViewController {
    
    @objc private func didSelecteAsset(_ notification: Notification) {
        let asset = notification.object as? Asset
        viewModel.asset.send(asset)
    }

}

