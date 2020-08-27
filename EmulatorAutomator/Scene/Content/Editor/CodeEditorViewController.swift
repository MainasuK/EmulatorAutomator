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

final class CodeEditorViewControllerViewModel {
    
    var disposeBag = Set<AnyCancellable>()

    // input
    let currentSelectionContentNode = CurrentValueSubject<Document.Content.Node?, Never>(nil)
    
    // output
    let latestSelectionFileContentNode = CurrentValueSubject<Document.Content.Node?, Never>(nil)
    
    
    init() {
        currentSelectionContentNode
            .compactMap { node -> Document.Content.Node? in
                guard let node = node else { return nil }
                switch node.content {
                case .directory:
                    return nil
                default:
                    // only select file node
                    return node
                }
            }
            .assign(to: \.value, on: self.latestSelectionFileContentNode)
            .store(in: &disposeBag)
    }

}

final class CodeEditorViewController: NSViewController {
    
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

extension CodeEditorViewController {
    
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
                guard case let .plaintext(text) = contentNode.content else { return }
                
                guard !text.elementsEqual(self.editorTextView.attributedString().string) else {
                    // fix blink update issue
                    return
                }
                
                if let attributedString = self.textStorage.highlightr.highlight(text) {
                    self.textStorage.setAttributedString(attributedString)
                }
            }
            .store(in: &disposeBag)
    }
    
}

extension CodeEditorViewController {
    
    @objc func shiftLeft(_ sender: NSMenuItem) {
        let selectedRange = editorTextView.selectedRange()
        let nsString = editorTextView.string as NSString
        let lineRange = nsString.lineRange(for: selectedRange)
        let oldLines = nsString.substring(with: lineRange).replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression)
        let newLines = oldLines.replacingOccurrences(of: "    ", with: "")
        
        // make undo manager works
        if editorTextView.shouldChangeText(in: NSRange(location: lineRange.location, length: lineRange.length), replacementString: newLines),
            let attributedString = self.textStorage.highlightr.highlight(newLines) {
            textStorage.replaceCharacters(in: NSRange(location: lineRange.location, length: lineRange.length), with: attributedString)
            if selectedRange.length == 0 {
                editorTextView.setSelectedRange(NSRange(location: selectedRange.location + 4, length: 0))
            } else {
                editorTextView.setSelectedRange(NSRange(location: selectedRange.location + 4, length: (newLines as NSString).length))
            }
            editorTextView.didChangeText()
        }
    }
    
    @objc func shiftRight(_ sender: NSMenuItem) {
        let selectedRange = editorTextView.selectedRange()
        let nsString = editorTextView.string as NSString
        let lineRange = nsString.lineRange(for: selectedRange)
        let oldLines = nsString.substring(with: lineRange).replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression)
        let newLines = "    " + oldLines.replacingOccurrences(of: "\n", with: "\n    ")
        
        // make undo manager works
        if editorTextView.shouldChangeText(in: NSRange(location: lineRange.location, length: lineRange.length), replacementString: newLines),
        let attributedString = self.textStorage.highlightr.highlight(newLines) {
            textStorage.replaceCharacters(in: NSRange(location: lineRange.location, length: lineRange.length), with: attributedString)
            if selectedRange.length == 0 {
                editorTextView.setSelectedRange(NSRange(location: selectedRange.location + 4, length: 0))
            } else {
                editorTextView.setSelectedRange(NSRange(location: selectedRange.location + 4, length: (newLines as NSString).length))
            }
            editorTextView.didChangeText()
        }
    }
    
}

// MARK: - NSTextViewDelegate
extension CodeEditorViewController: NSTextViewDelegate {
    
    func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(insertTab(_:)) {
            textView.insertText("    ", replacementRange: textView.selectedRange())
            return true
        }
        
        return false
    }
    
    func textDidBeginEditing(_ notification: Notification) { }
    
    func textDidChange(_ notification: Notification) {
        document?.objectDidBeginEditing(self)
        if let node = viewModel.latestSelectionFileContentNode.value {
            node.content = .plaintext(editorTextView.attributedString().string)
            document?.update(node: node)
        }
        document?.objectDidEndEditing(self)
        
        // set document edited
        document?.updateChangeCount(.changeDone)
    }
    
    func textDidEndEditing(_ notification: Notification) { }
    
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
            
            let viewController = CodeEditorViewController()
            viewController.textStorage.setAttributedString(NSAttributedString(string: sampleCode))
            return viewController
        }
    }
}
