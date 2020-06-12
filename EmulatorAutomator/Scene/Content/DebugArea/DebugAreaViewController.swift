//
//  DebugAreaViewController.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-5-3.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Cocoa
import Combine

final class DebugAreaViewController: NSViewController {
    
    override var representedObject: Any? {
        didSet {
            weak var document = representedObject as? Document
            
            disposeBag.removeAll()
            if let document = document {
                document.consoleLogService.relay
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] log in
                        let attributedString = NSAttributedString(string: log, attributes: [NSAttributedString.Key.foregroundColor : NSColor.white])
                        self?.consoleTextView.textStorage?.append(attributedString)
                    }
                    .store(in: &disposeBag)
                
                document.consoleLogService.started
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] _ in
                        self?.consoleTextView.textStorage?.setAttributedString(NSAttributedString(string: ""))
                    }
                    .store(in: &disposeBag)
                document.consoleLogService.finished
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] _ in
                        let attributedString = NSAttributedString(string: "Program ended with exit code: 0", attributes: [NSAttributedString.Key.foregroundColor : NSColor.white])
                        self?.consoleTextView.textStorage?.append(attributedString)
                    }
                    .store(in: &disposeBag)
            }
        }
    }
    
    var disposeBag = Set<AnyCancellable>()
    
    let scrollView: NSScrollView =  {
        let scrollView = NSScrollView()
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        
        return scrollView
    }()
        
    let consoleTextView: NSTextView = {
        let rect = CGRect(x: 0, y: 0, width: 0, height: Int.max)
        
        let textStorage = NSTextStorage()
    
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        
        let textContainer = NSTextContainer(size: rect.size)
        layoutManager.addTextContainer(textContainer)
        
        textContainer.widthTracksTextView = true
        textContainer.heightTracksTextView = false
        
        let textView = NSTextView(frame: rect, textContainer: textContainer)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.maxSize = CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        
        textView.enabledTextCheckingTypes = .zero
        textView.isContinuousSpellCheckingEnabled = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.allowsUndo = true
        
//        let rect = CGRect(x: 0, y: 0, width: 0, height: Int.max)
//
//        let layoutManager = NSLayoutManager()
//
//        let textContainer = NSTextContainer(size: rect.size)
//        layoutManager.addTextContainer(textContainer)
//
//        textContainer.widthTracksTextView = true
//        textContainer.heightTracksTextView = false
//
//        let textView = NSTextView(frame: .zero, textContainer: textContainer)
////        let textView = NSTextView()
//        textView.isVerticallyResizable = true
//        textView.isHorizontallyResizable = false
//        textView.maxSize = CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
//
//        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
//        textView.isEditable = false
//        textView.backgroundColor = .black
//        textView.textColor = .white
        return textView
    }()
    
    override func loadView() {
        view = NSView()
    }
    
}

extension DebugAreaViewController {
    
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

        scrollView.documentView = consoleTextView
        consoleTextView.autoresizingMask = .width
        
//        consoleTextView.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(consoleTextView)
//        NSLayoutConstraint.activate([
//            consoleTextView.topAnchor.constraint(equalTo: view.topAnchor),
//            consoleTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            view.trailingAnchor.constraint(equalTo: consoleTextView.trailingAnchor),
//            view.bottomAnchor.constraint(equalTo: consoleTextView.bottomAnchor),
//        ])
//
//        consoleTextView.setContentHuggingPriority(.fittingSizeCompression, for: .vertical)
    }
    
//    override func viewDidLayout() {
//        super.viewDidLayout()
//
//        consoleTextView.frame = view.bounds
//    }
    
}
