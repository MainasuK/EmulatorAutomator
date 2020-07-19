//
//  EditorTabViewController.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-7-16.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Cocoa
import Combine
import CommonOSLog

final class EditorTabViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let currentSelectionContentNode = CurrentValueSubject<Document.Content.Node?, Never>(nil)
    
}

final class EditorTabViewController: NSTabViewController {

    var disposeBag = Set<AnyCancellable>()
    
    override var representedObject: Any? {
        didSet {
            // Pass down the represented object to all of the child view controllers.
            for child in children {
                child.representedObject = representedObject
            }
        }
    }
    
    let viewModel = EditorTabViewModel()
    
    let sourceEditorViewControllerViewController = CodeEditorViewController()
    let assetEditorViewControllerViewController = AssetEditorViewController()
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension EditorTabViewController {
    enum NotificationName {
        static let didSelectViewController = Notification.Name("EditorTabViewController.didSelectViewController")
    }
}

extension EditorTabViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabStyle = .unspecified
        
        addChild(sourceEditorViewControllerViewController)
        addChild(assetEditorViewControllerViewController)
        
        viewModel.currentSelectionContentNode
            .sink { [weak self] node in
                guard let `self` = self else { return }
                guard let node = node else { return }
                switch node.content {
                case .plaintext:
                    self.selectedTabViewItemIndex = 0
                case .image:
                    self.selectedTabViewItemIndex = 1
                default:
                    break
                }
            }
            .store(in: &disposeBag)
        
    }
    
    override func tabView(_ tabView: NSTabView, willSelect tabViewItem: NSTabViewItem?) {
        super.tabView(tabView, willSelect: tabViewItem)
    }
    
    override func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        super.tabView(tabView, didSelect: tabViewItem)
        
        NotificationCenter.default.post(name: EditorTabViewController.NotificationName.didSelectViewController, object: tabViewItem?.viewController)
    }
    
}
