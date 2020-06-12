//
//  ScreencapContentView.swift
//  EmulatorAutomator
//
//  Created by MainasuK Cirno on 2020/3/12.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Cocoa
import SwiftUI
import AVFoundation

struct SelectionArea: Shape {
    
    var startLocation: CGPoint
    var transition: CGSize
    
    var selectionFrame: CGRect
    
    var imageFrame: CGRect
    var viewFrame: CGRect
    
    var imageSize: CGSize

    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        if startLocation == .zero && transition == .zero {
            if selectionFrame != .zero {
                // print("imageFrame: \(imageFrame), viewFrame: \(viewFrame)")
                // print("on image: \(selectionFrame)")
                let rect = SelectionArea.convertRectFromImageToView(rect: selectionFrame, viewFrame: viewFrame, imageFrame: imageFrame, imageSize: imageSize)
                // print("on view: \(rect)")
                path.addRect(rect)
            }
            return path
        } else {
            let rect = CGRect(origin: startLocation, size: transition)
            path.addRect(rect)
        }
        
        return path
    }
    
    static func convertRectFromViewToImage(rect: CGRect, viewFrame: CGRect, imageFrame: CGRect, imageSize: CGSize) -> CGRect {
        var rect = rect.standardized
        
        let translateOrigin = CGAffineTransform.identity.translatedBy(x: viewFrame.origin.x - imageFrame.origin.x, y: viewFrame.origin.y - imageFrame.origin.y)
        rect = rect.applying(translateOrigin)
        
        // scale size only without origin
        let scale = imageSize.width / imageFrame.width
        let scaleSize = CGAffineTransform.identity.scaledBy(x: scale, y: scale)
        rect = rect.applying(scaleSize)
        
        return rect
    }
    
    static func convertRectFromImageToView(rect: CGRect, viewFrame: CGRect, imageFrame: CGRect, imageSize: CGSize) -> CGRect {
        var rect = rect.standardized

        // scale size only without origin
        let scale = imageFrame.width / imageSize.width
        let scaleSize = CGAffineTransform.identity.scaledBy(x: scale, y: scale)
        rect = rect.applying(scaleSize)

        let translateOrigin = CGAffineTransform.identity.translatedBy(x: -(viewFrame.origin.x - imageFrame.origin.x), y: -(viewFrame.origin.y - imageFrame.origin.y))
        rect = rect.applying(translateOrigin)
        
        return rect
    }

}

struct ScreencapContentView: View {
    
    @EnvironmentObject var store: ScreencapStore
    
    @GestureState var dragStartLocation: CGPoint = .zero
    @GestureState var dragTransition: CGSize = .zero
    
    @State var imageFrame = CGRect.zero
    @State var viewFrame = CGRect.zero
    
       
    var body: some View {
        ZStack {
            Image(nsImage: self.store.screencapState.content.screencap)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.blue)
                .overlay(GeometryReader { geometry -> SelectionArea in
                    let viewFrame = geometry.frame(in: .global)
                    let imageFrame = AVMakeRect(aspectRatio: self.store.screencapState.content.screencap.size, insideRect: viewFrame)   // save Runloop
                    
                    DispatchQueue.main.async {
                        self.viewFrame = viewFrame
                        self.imageFrame = imageFrame
                    }
                    
                    return SelectionArea(
                        startLocation: self.dragStartLocation,
                        transition: self.dragTransition,
                        selectionFrame: self.store.screencapState.content.selectionFrame,
                        imageFrame: imageFrame,
                        viewFrame: viewFrame,
                        imageSize: self.store.screencapState.content.screencap.size
                    )
                })
        }
        .gesture(
            DragGesture()
                .updating(self.$dragStartLocation) { (value, state, transition) in
                    state = value.startLocation
                }
                .updating(self.$dragTransition) { (value, state, transition) in
                    state = value.translation
                }
                .onEnded { value in
                    let dragRectInView = CGRect(origin: value.startLocation, size: value.translation).standardized
                    let rect = SelectionArea.convertRectFromViewToImage(rect: dragRectInView, viewFrame: self.viewFrame, imageFrame: self.imageFrame, imageSize: self.store.screencapState.content.screencap.size)
                    self.store.screencapState.content.selectionFrame = CGRect(x: floor(rect.origin.x), y: floor(rect.origin.y), width: floor(rect.width), height: floor(rect.height))
                }
        )
        .gesture(TapGesture(count: 1)
            .onEnded { _ in
                self.store.screencapState.content.selectionFrame = .zero
            }
        )
    }   // end body
    
}
