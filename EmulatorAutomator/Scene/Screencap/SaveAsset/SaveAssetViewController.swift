//
//  SaveAssetViewController.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-7-8.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import os
import Cocoa
import Combine

final class SaveAssetViewController: NSViewController {
    
    var disposeBag = Set<AnyCancellable>()
    
    weak var screencapStore: ScreencapStore!
    
    let assetNameLabel: NSTextField = {
        return NSTextField(labelWithString: "Asset Name: ")
    }()
    
    private lazy var assetNameTextField: NSTextField = {
        let textField = NSTextField()
        return textField
    }()
    
    let assetImageView: NSImageView = {
        let imageView = NSImageView()
        imageView.imageScaling = .scaleProportionallyDown
        return imageView
    }()
    
    private lazy var actionButton: NSButton = {
        let button = NSButton(title: "Create", target: self, action: #selector(SaveAssetViewController.createButtonPressed(_:)))
        button.bezelStyle = .rounded
        button.keyEquivalent = "\r"
        button.isHighlighted = true
        return button
    }()
    
    private lazy var cancelButton: NSButton = {
        let button = NSButton(title: "Cancel", target: self, action: #selector(SaveAssetViewController.cancelButtonPressed(_:)))
        // Escape
        // NSResponder.cancelOperation: will find it
        button.keyEquivalent = "\u{1b}"
        return button
    }()
    
    override func loadView() {
        view = NSView()
        view.wantsLayer = true
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension SaveAssetViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        assetNameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(assetNameLabel)
        NSLayoutConstraint.activate([
            assetNameLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 32),
            assetNameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 64),
        ])
        
        assetNameTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(assetNameTextField)
        NSLayoutConstraint.activate([
            assetNameTextField.centerYAnchor.constraint(equalTo: assetNameLabel.centerYAnchor),
            assetNameTextField.leadingAnchor.constraint(equalTo: assetNameLabel.trailingAnchor, constant: 8),
            view.trailingAnchor.constraint(equalTo: assetNameTextField.trailingAnchor, constant: 64),
        ])
        
        assetImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(assetImageView)
        NSLayoutConstraint.activate([
            assetImageView.topAnchor.constraint(equalTo: assetNameLabel.bottomAnchor, constant: 16),
            assetImageView.leadingAnchor.constraint(equalTo: assetNameLabel.leadingAnchor),
            assetImageView.trailingAnchor.constraint(equalTo: assetNameTextField.trailingAnchor),
            assetImageView.heightAnchor.constraint(equalToConstant: 200),
        ])
        
                
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(actionButton)
        NSLayoutConstraint.activate([
            actionButton.topAnchor.constraint(greaterThanOrEqualTo: assetImageView.bottomAnchor, constant: 32),
            view.trailingAnchor.constraint(equalTo: actionButton.trailingAnchor, constant: 22),
            view.bottomAnchor.constraint(equalTo: actionButton.bottomAnchor, constant: 22),
        ])
        
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cancelButton)
        NSLayoutConstraint.activate([
            actionButton.leadingAnchor.constraint(equalTo: cancelButton.trailingAnchor, constant: 12),
            actionButton.centerYAnchor.constraint(equalTo: cancelButton.centerYAnchor),
        ])
        
        assetImageView.image = screencapStore.screencapState.utility.flannMatchingImage
        
        let assetNameTextFieldText = NotificationCenter.default
            .publisher(for: NSTextField.textDidChangeNotification, object: assetNameTextField)
            .map { _ in self.assetNameTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines) }
            .share()
        
        assetNameTextFieldText
            .map { !$0.isEmpty }
            .assign(to: \.isEnabled, on: actionButton)
            .store(in: &disposeBag)
    }
    
}

extension SaveAssetViewController {
    
    @objc private func createButtonPressed(_ sender: NSButton) {
        
    }
    
    @objc private func cancelButtonPressed(_ sender: NSButton) {
        guard let window = view.window, let parentWindow = window.sheetParent else {
            return
        }
        
        parentWindow.endSheet(window)
    }
    
}
