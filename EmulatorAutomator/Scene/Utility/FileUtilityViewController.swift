//
//  FileUtilityViewController.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-4-8.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Cocoa
import Combine
import CommonOSLog

final class FileUtilityViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // Input
    let currentSelectionTreeNode = CurrentValueSubject<NSTreeNode?, Never>(nil)

    // Output
    let isNoSelection = PassthroughSubject<Bool, Never>()
    let currentSelectionContentNode = CurrentValueSubject<Document.Content.Node?, Never>(nil)

    
    init() {
        currentSelectionTreeNode
            .map { $0 == nil }
            .subscribe(isNoSelection)
            .store(in: &disposeBag)
        
        currentSelectionTreeNode
            .map { treeNode -> Document.Content.Node? in
                guard let node = treeNode?.representedObject as? OutlineViewModel.Node else {
                    return nil
                }
                
                switch node.object {
                case .contentNode(let contentNode):
                    return contentNode
                default:
                    return nil
                }
            }
            .assign(to: \.value, on: currentSelectionContentNode)
            .store(in: &disposeBag)
    }
    
}

final class FileUtilityViewController: NSViewController {
    
    weak var document: Document? {
        return representedObject as? Document
    }
    
    var disposeBag = Set<AnyCancellable>()
    let viewModel = FileUtilityViewModel()
    
//    let openWithExternalEditorButton: NSButton = {
//        let button = NSButton()
//        button.setButtonType(.momentaryPushIn)
//        button.bezelStyle = .rounded
//        button.title = "Open with External Editor"
//        return button
//    }()
    
    let noSelectionView = NoSelectionView()
    
    let nameLabel: NSTextField = {
        return NSTextField(labelWithString: "Name")
    }()
    let nameTextField: NSTextField = {
        let textField = NSTextField()
        return textField
    }()
    
    override func loadView() {
        view = NSView()
    }
    
}

final class FlippedClipView: NSClipView {
    override var isFlipped: Bool {
        return true
    }
}

extension FileUtilityViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
        ])
        
        let clipView = FlippedClipView()
        clipView.drawsBackground = false
        clipView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.contentView = clipView
        NSLayoutConstraint.activate([
            clipView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            clipView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: clipView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: clipView.bottomAnchor),
        ])
        
        let contentView = NSView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = contentView
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: clipView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: clipView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: clipView.trailingAnchor),
        ])
    
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            contentView.bottomAnchor.constraint(greaterThanOrEqualTo: nameLabel.bottomAnchor),
        ])
        
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameTextField)
        NSLayoutConstraint.activate([
            nameTextField.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 4),
            nameTextField.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            view.trailingAnchor.constraint(equalTo: nameTextField.trailingAnchor, constant: 8),
        ])
//        openWithExternalEditorButton.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(openWithExternalEditorButton)
//        NSLayoutConstraint.activate([
//            openWithExternalEditorButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
//            openWithExternalEditorButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
//            view.trailingAnchor.constraint(equalTo: openWithExternalEditorButton.trailingAnchor, constant: 16),
//        ])
        
        noSelectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(noSelectionView)
        NSLayoutConstraint.activate([
            noSelectionView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noSelectionView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        
//        openWithExternalEditorButton.target = self
//        openWithExternalEditorButton.action = #selector(FileUtilityViewController.openWithExternalEditorButtonPressed(_:))
        
        viewModel.isNoSelection
            .sink { [weak self] isNoSelection in
//                self?.openWithExternalEditorButton.isHidden = isNoSelection
                self?.noSelectionView.isHidden = !isNoSelection
            }
            .store(in: &disposeBag)
        
        viewModel.currentSelectionContentNode
            .sink { [weak self] node in
                self?.nameTextField.stringValue = node?.name ?? ""
            }
            .store(in: &disposeBag)
            
        
        nameTextField.delegate = self
    }
    
}

//extension FileUtilityViewController {
//
//    @objc private func didSelectScene(_ notification: Notification) {
//        os_log(.info, log: .logic, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
//
//        let scene = notification.object as? Scene
//        viewModel.scene.send(scene)
//    }
//
//    @objc private func openWithExternalEditorButtonPressed(_ sender: NSButton) {
//        os_log(.info, log: .interaction, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
//
//        guard let scene = viewModel.scene.value else { return }
//        NSWorkspace.shared.openFile(scene.scriptURL.path)
//    }
//
//}

// MARK: - NSTextFieldDelegate
extension FileUtilityViewController: NSTextFieldDelegate {
    
    func controlTextDidEndEditing(_ obj: Notification) {
        guard let contentNode = viewModel.currentSelectionContentNode.value else {
            return
        }

        assert(document != nil)
        
        if let sender = obj.object as? NSTextField, sender === nameTextField {
            guard !sender.stringValue.isEmpty else {
                sender.stringValue = contentNode.name
                return
            }
            
            contentNode.name = sender.stringValue
            document?.update(node: contentNode)
        }
    }
    
}
