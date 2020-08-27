//
//  AssetEditorViewController.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-7-16.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Cocoa
import Combine
import SwiftUI
import CocoaPreviewProvider
import Highlightr
import CommonOSLog

final class AssetEditorViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let currentSelectionContentNode = CurrentValueSubject<Document.Content.Node?, Never>(nil)
    
    // output

    
    init() {
    }
    
}

final class AssetEditorViewController: NSViewController {
    
    var disposeBag = Set<AnyCancellable>()
    let viewModel = CodeEditorViewControllerViewModel()
    
    weak var document: Document? {
        return representedObject as? Document
    }
    
    let scrollView: NSScrollView =  {
        let scrollView = NSScrollView()
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        
        return scrollView
    }()
    let contentImageView: NSImageView = {
        let imageView = AutoSizingImageView()
        imageView.imageScaling = .scaleProportionallyUpOrDown
        return imageView
    }()
    
    override func loadView() {
        view = NSView()
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: deinit", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension AssetEditorViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        contentImageView.frame = scrollView.bounds
        contentImageView.autoresizingMask = [.width, .height]
        scrollView.documentView = contentImageView

        viewModel.currentSelectionContentNode
            .sink { node in
                guard let node = node else {
                    self.contentImageView.image = nil
                    return
                }
                
                switch node.content {
                case .image(let image):
                    self.contentImageView.image = image
                default:
                    self.contentImageView.image = nil
                }
            }
            .store(in: &disposeBag)
    }
    
}
