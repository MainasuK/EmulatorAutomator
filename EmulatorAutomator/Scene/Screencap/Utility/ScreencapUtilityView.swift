//
//  ScreencapUtilityView.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-5-4.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import SwiftUI

struct EditableSignedNumericTextField<T>: View where T: SignedNumeric & Strideable {
    
    let title: String
    let numberFormatter: NumberFormatter
    @Binding var number: T
    
    var body: some View {
        VStack(spacing: 1) {
            HStack(spacing: 1) {
                TextField(title, value: $number, formatter: numberFormatter)
                    .multilineTextAlignment(.trailing)
                Stepper(value: $number) { EmptyView() }
            }
            Text(title)
                .font(.caption)
                
        }
    }
    
}

struct TextTitleStyleModifier: ViewModifier {

    func body(content: Content) -> some View {
        return content
            .font(Font.caption.weight(.semibold))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
}

struct ScreencapUtilityView: View {
    
    @EnvironmentObject var store: ScreencapStore
    
    @State var code = ""
    
    let coordinatorNumberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 0
        return numberFormatter
    }()

    var body: some View {
        VStack {
            selectionView
            Divider()
            scriptGenerationView
        }
        .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
}


struct PickerText: View {
    let text: String
    var body: some View {
        VStack(spacing: 0) {
            Text(text)
        }
    }
}

extension ScreencapUtilityView {
    
    var selectionView: some View {
        VStack {
            Text("Selection")
                .modifier(TextTitleStyleModifier())
            Group {
                HStack {
                    EditableSignedNumericTextField(title: "X", numberFormatter: coordinatorNumberFormatter, number: $store.screencapState.content.selectionFrame.origin.x)
                    EditableSignedNumericTextField(title: "Y", numberFormatter: coordinatorNumberFormatter, number: $store.screencapState.content.selectionFrame.origin.y)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                HStack {
                    EditableSignedNumericTextField(title: "Width", numberFormatter: coordinatorNumberFormatter, number: $store.screencapState.content.selectionFrame.size.width)
                    EditableSignedNumericTextField(title: "Height", numberFormatter: coordinatorNumberFormatter, number: $store.screencapState.content.selectionFrame.size.height)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.leading, 20)
        }
    }
    
    var scriptGenerationView: some View {
        VStack {
            Text("Script")
                .modifier(TextTitleStyleModifier())
            VStack {
                Picker(selection: $store.screencapState.utility.scriptGenerationType, label: Text("Type:")) {
                    ForEach(ScreencapState.Utility.ScriptGenerationType.allCases, id: \.self) {
                        PickerText(text: $0.text)
                    }
                }
                .onReceive(store.$screencapState) { state in
                    let type = state.utility.scriptGenerationType
                    self.code = self.generateCode(for: type)
                }
                MacEditorTextView(text: $code, isEditable: false)
                .frame(maxHeight: 80)
                Button(action: {
                    NSPasteboard.general.declareTypes([.string], owner: nil)
                    NSPasteboard.general.setString(self.code, forType: .string)
                }, label: {
                    Text("Copy")
                })
                Spacer()
            }
            .padding(.leading, 20)
        }
    }
    
}

extension ScreencapUtilityView {
    
    private func generateCode(for type: ScreencapState.Utility.ScriptGenerationType) -> String {
        switch type {
        case .tapInTheCenterOfSelection:
            let rect = store.screencapState.content.selectionFrame.standardized
            let center = CGPoint(x: floor(rect.midX), y: floor(rect.midY))
            return "emulator.tap(\(center.x), \(center.y));"
        case .listPackages:
            return "emulator.listPackages();"
        case .openPackage:
            return "emulator.openPackage('com.android.browser');"
        }
    }
}

struct ScreencapUtilityView_Previews: PreviewProvider {
    static var previews: some View {
        ScreencapUtilityView()
            .environmentObject(ScreencapStore())
            .previewLayout(.fixed(width: 350, height: 450))
    }
}

//struct SelectableTextView: NSViewRepresentable {
//
//    private var text: String
//    private var selectable: Bool
//
//    init(_ text: String, selectable: Bool = true) {
//        self.text = text
//        self.selectable = selectable
//    }
//
//    func makeNSView(context: Context) -> NSScrollView {
//        let container = NSScrollView(frame: NSRect(x: 0, y: 0, width: 800, height: 800))
//        container.autoresizingMask = [.width, .height]
//
//        let textView = NSTextView()
//        textView.minSize = NSSize(width: 0, height: 0)
//        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
//        textView.isVerticallyResizable = true
////        textView.translatesAutoresizingMaskIntoConstraints = false
////        container.addSubview(textView)
////        NSLayoutConstraint.activate([
////            textView.topAnchor.constraint(equalTo: container.topAnchor),
////            textView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
////            textView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
////            textView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
////        ])
//        textView.isEditable = false
//        textView.textContainer?.containerSize = NSSize(width: container.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
//        textView.textContainer?.widthTracksTextView = true
//
//        container.documentView = textView
//
//        return container
//    }
//
//    func updateNSView(_ container: NSScrollView, context: Context) {
//        guard let textView = container.documentView as? NSTextView else {
//            assertionFailure()
//            return
//        }
//
//        textView.textStorage?.setAttributedString(NSAttributedString(string: text))
//        textView.isSelectable = selectable
//    }
//
//}

//struct SelectableTextView: NSViewRepresentable {
//
//    private var text: String
//    private var selectable: Bool
//
//    init(_ text: String, selectable: Bool = true) {
//        self.text = text
//        self.selectable = selectable
//    }
//
//    func makeNSView(context: Context) -> NSTextView {
//        let textView = NSTextView()
//        textView.isEditable = false
//        return textView
//    }
//
//    func updateNSView(_ textView: NSTextView, context: Context) {
//        textView.textStorage?.setAttributedString(NSAttributedString(string: text))
//        textView.isSelectable = selectable
//    }
//
//}
