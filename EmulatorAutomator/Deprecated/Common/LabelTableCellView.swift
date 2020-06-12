//
//  LabelTableCellView.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-4-8.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Cocoa

final class LabelTableCellView: NSTableCellView {
    
    let nameTextField: NSTextField = {
        let textField = NSTextField(labelWithString: "")
        textField.lineBreakMode = .byTruncatingMiddle
        return textField
    }()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
    private func _init() {
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        addSubview(nameTextField)
        NSLayoutConstraint.activate([
            nameTextField.topAnchor.constraint(equalTo: topAnchor),
            nameTextField.leadingAnchor.constraint(equalTo: leadingAnchor),
            nameTextField.trailingAnchor.constraint(equalTo: trailingAnchor),
            nameTextField.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
    
    static func new(identifier: NSUserInterfaceItemIdentifier) -> LabelTableCellView {
        let cell = LabelTableCellView()
        cell.identifier = identifier
        return cell
    }
    
}
