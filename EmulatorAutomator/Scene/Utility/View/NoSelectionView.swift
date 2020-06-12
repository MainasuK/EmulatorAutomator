//
//  NoSelectionView.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-4-9.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Cocoa

final class NoSelectionView: NSView {
    
    let label: NSTextField = {
        let label = NSTextField(labelWithString: "No Selection")
        label.alignment = .center
        return label
    }()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension NoSelectionView {
    
    private func _init() {
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
    
}
