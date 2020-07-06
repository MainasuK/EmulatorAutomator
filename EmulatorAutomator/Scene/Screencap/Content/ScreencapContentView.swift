//
//  ScreencapContentView.swift
//  EmulatorAutomator
//
//  Created by MainasuK Cirno on 2020/3/12.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Cocoa
import SwiftUI
import Combine
import AVFoundation
import EmulatorAutomatorCommon

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

final class ScreencapContentViewModel: ObservableObject {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    // screencap from ADB
    let screencap = CurrentValueSubject<NSImage, Never>(NSImage())
    var screencapSubscription: AnyCancellable?
    
    let selectionFrame = CurrentValueSubject<CGRect, Never>(.zero)
    var selectionFrameSubscription: AnyCancellable?
    
    // output
    // image of selection region from the screencap
    let targetImage = CurrentValueSubject<NSImage, Never>(NSImage())
    var targetImageSubscription: AnyCancellable?
    
    let featureMatchingResult = CurrentValueSubject<OpenCVService.FeatureMatchingResult, Never>(.init())
    var featureMatchingResultSubscription: AnyCancellable?
    
    init() {
        Publishers.CombineLatest(screencap.eraseToAnyPublisher(), selectionFrame.eraseToAnyPublisher())
            .map { screencap, selectionFrame in
                guard screencap.isValid, screencap.size != .zero, selectionFrame != .zero else {
                    return NSImage()
                }

                let cropRect = selectionFrame.standardized.intersection(CGRect(x: 0, y: 0, width: screencap.size.width, height: screencap.size.height))
                
                guard let cgImage = screencap.cgImage(forProposedRect: nil, context: nil, hints: nil),
                let croppedImage = cgImage.cropping(to: cropRect) else {
                    return NSImage()
                }
                
                return NSImage(cgImage: croppedImage, size: cropRect.size)
            }
            .assign(to: \.value, on: targetImage)
            .store(in: &disposeBag)
                
        Publishers.CombineLatest(screencap.eraseToAnyPublisher(), targetImage.eraseToAnyPublisher())
            .handleEvents(receiveOutput: { _ in
                // reset
                self.featureMatchingResult.value = .init()
            })
            .map { screencap, target -> AnyPublisher<OpenCVService.FeatureMatchingResult, Never> in
                Future<OpenCVService.FeatureMatchingResult, Never> { promise in
                    DispatchQueue.global().async {
                        let result = OpenCVService().match(image: screencap, target: target)
                        promise(.success(result))
                    }
                }.eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .assign(to: \.value, on: featureMatchingResult)
            .store(in: &disposeBag)
    }
    
}

struct ScreencapContentView: View {
    
    @EnvironmentObject var store: ScreencapStore
    @ObservedObject var viewModel = ScreencapContentViewModel()
    
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
                // .background(Color.blue)
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
                    let selectionFrame = CGRect(x: floor(rect.origin.x), y: floor(rect.origin.y), width: floor(rect.width), height: floor(rect.height))
                    self.store.dispatch(.makeSelectionOfScreencap(rect: selectionFrame))
                }
        )
        .gesture(TapGesture(count: 1)
            .onEnded { _ in
                self.store.dispatch(.resetSelectionOfScreencap)
            }
        )
        .onAppear {
            // subscribe store
            self.viewModel.screencapSubscription = self.store.screencapState.content.screencapPublisher
                .assign(to: \.value, on: self.viewModel.screencap)
            self.viewModel.selectionFrameSubscription = self.store.screencapState.content.selectionFramePublisher
                .assign(to: \.value, on: self.viewModel.selectionFrame)
            
            // use dispatcher update source
            self.viewModel.targetImageSubscription = self.viewModel.targetImage
                .sink(receiveValue: { image in
                    self.store.dispatch(.setScreenshotCroppedImage(image: image))
                })
            self.viewModel.featureMatchingResultSubscription = self.viewModel.featureMatchingResult
                .sink(receiveValue: { result in
                    self.store.dispatch(.setPreviewResult(result: result))
                })
        }
    }   // end body
    
}
