//
//  EditorViewController.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-5-3.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Cocoa
import Combine
import SwiftUI
import CocoaPreviewProvider
import Highlightr
import CommonOSLog

final class EditorViewControllerViewModel {
    
    var disposeBag = Set<AnyCancellable>()

    // input
    let currentSelectionContentNode = CurrentValueSubject<Document.Content.Node?, Never>(nil)
    
    // output
    let latestSelectionFileContentNode = CurrentValueSubject<Document.Content.Node?, Never>(nil)
    
    
    init() {
        currentSelectionContentNode
            .compactMap { node -> Document.Content.Node? in
                guard let node = node else { return nil }
                return node.isFile ? node : nil
            }
            .assign(to: \.value, on: self.latestSelectionFileContentNode)
            .store(in: &disposeBag)
    }

}

final class EditorViewController: NSViewController {
    
    var disposeBag = Set<AnyCancellable>()
    let viewModel = EditorViewControllerViewModel()
    
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

    // setup Highlightr
    let textStorage = CodeAttributedString()
    private(set) lazy var editorTextView: NSTextView = {
        let rect = CGRect(x: 0, y: 0, width: 0, height: Int.max)

        textStorage.language = "javascript"
        textStorage.font = textStorage.highlightr.theme.codeFont
        
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
        
        return textView
    }()
    
    override func loadView() {
        view = NSView()
    }
    
    deinit {
        // try to fix memory leak issue
        editorTextView.textContainer = nil
        textStorage.layoutManagers.forEach {
            textStorage.removeLayoutManager($0)
        }
        textStorage.language = nil
        textStorage.highlightr.themeChanged = nil
        
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: deinit", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension EditorViewController {
    
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

        scrollView.documentView = editorTextView
        editorTextView.autoresizingMask = .width

        editorTextView.backgroundColor = textStorage.highlightr.theme.themeBackgroundColor!
        editorTextView.insertionPointColor = NSColor.blue
        editorTextView.delegate = self
        
        viewModel.latestSelectionFileContentNode
            //.print()
            .sink { [weak self] contentNode in
                guard let `self` = self else { return }
                guard let contentNode = contentNode  else { return }
                
                guard !contentNode.content.elementsEqual(self.editorTextView.attributedString().string) else {
                    // fix blink update issue
                    return
                }
                
                if let attributedString = self.textStorage.highlightr.highlight(contentNode.content) {
                    self.textStorage.setAttributedString(attributedString)
                }
            }
            .store(in: &disposeBag)
    }
    
}

// MARK: - NSTextViewDelegate
extension EditorViewController: NSTextViewDelegate {
    
    func textDidBeginEditing(_ notification: Notification) {
    }
    
    func textDidChange(_ notification: Notification) {
        document?.objectDidBeginEditing(self)
        if let node = viewModel.latestSelectionFileContentNode.value {
            document?.updateSources(for: node, content: editorTextView.attributedString().string)
        }
        document?.objectDidEndEditing(self)
        
        // set document edited
        document?.updateChangeCount(.changeDone)
    }
    
    func textDidEndEditing(_ notification: Notification) {
    }
    
    func undoManager(for view: NSTextView) -> UndoManager? {
        return document?.undoManager
    }
    
}

struct EditorViewController_Previews: PreviewProvider {
    static var previews: some View {
        NSViewControllerPreview {
            let sampleCode = """
            function $initHighlight(block, cls) {
                try {
                    if (cls.search(/\\bno\\-highlight\\b/) != -1)
                        return process(block, true, 0x0F) +
                            ` class="${cls}"`;
                } catch (e) {
                /* handle exception */
                }
                for (var i = 0 / 2; i < classes.length; i++) {
                if (checkCondition(classes[i]) === undefined)
                    console.log('undefined');
                }

                return (
                    <div>
                        <web-component>{block}</web-component>
                    </div>
                )
            }

            export $initHighlight;
            """
            
            let viewController = EditorViewController()
            viewController.textStorage.setAttributedString(NSAttributedString(string: sampleCode))
            return viewController
        }
    }
}
