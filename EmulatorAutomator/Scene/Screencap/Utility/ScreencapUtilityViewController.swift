//
//  ScreencapUtilityViewController.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-5-4.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Cocoa
import SwiftUI

final class ScreencapUtilityViewController: NSViewController {
    
    weak var screencapStore: ScreencapStore?
    lazy var screencapUtilityView = ScreencapUtilityView()

    override func loadView() {
        view = NSView()
    }
    
}

extension ScreencapUtilityViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let store = screencapStore else {
            return
        }
        
        let hostingView = NSHostingView(rootView: screencapUtilityView.environmentObject(store))
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingView)
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: view.topAnchor),
            hostingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
}
