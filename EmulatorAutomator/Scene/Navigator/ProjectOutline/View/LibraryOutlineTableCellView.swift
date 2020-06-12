//
//  LibraryOutlineTableCellView.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-3-29.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Cocoa
import SwiftUI
import Combine

final class LibraryOutlineTableCellView: NSTableCellView {
    
    var disposeBag = Set<AnyCancellable>()
    
    let name = CurrentValueSubject<String, Never>("")
    fileprivate let verticalCenterTextViewModel = VerticalCenterTextViewModel()
    fileprivate let verticalTextView = VerticalCenterTextView()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
    private func _init() {
        let hostingView = NSHostingView(rootView: verticalTextView.environmentObject(verticalCenterTextViewModel))
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hostingView)
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: topAnchor),
            hostingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostingView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        name.sink(receiveValue: { [weak self] name in
            self?.verticalCenterTextViewModel.text = name
        })
        .store(in: &disposeBag)
    }
    
}

fileprivate class VerticalCenterTextViewModel: ObservableObject {
    @Published var text = ""
}

fileprivate struct VerticalCenterTextView: View {

    @EnvironmentObject var viewModel: VerticalCenterTextViewModel
    
    var body: some View {
        HStack {
            Text(viewModel.text)
                .truncationMode(.middle)
            Spacer()
        }
    }
}
