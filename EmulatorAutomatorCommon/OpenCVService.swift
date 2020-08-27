//
//  OpenCVService.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-6-14.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Foundation
import OpenCVBridge
import CommonOSLog

public final class OpenCVService {
    public init() { }
}

extension OpenCVService {
    
    public func match(image: NSImage, target targetImage: NSImage, options: FLANNOptions = FLANNOptions()) -> FeatureMatchingResult {
        guard image.isValid && targetImage.isValid, image.size != .zero, targetImage.size != .zero else {
            return FeatureMatchingResult()
        }
        
        let detector = CVBSURF(hessianThreshold: options.minHessian)
        
        let object = CVBMat(nsImage: targetImage)
        let objectKeypointsDescriptor = CVBMat()
        let objectKeypoints = detector.detectAndCompute(object, mask: nil, descriptors: objectKeypointsDescriptor)
        
        let scene = CVBMat(nsImage: image)
        let sceneKeypointsDescriptor = CVBMat()
        let sceneKeypoints = detector.detectAndCompute(scene, mask: nil, descriptors: sceneKeypointsDescriptor)
        
        let matcher = CVBDescriptorMatcher(descriptorMatcherType: .FLANNBASED)
        let knnMatches = matcher.knnMatch(objectKeypointsDescriptor, descriptor2: sceneKeypointsDescriptor, k: 2)
        
        // Filter matches using the Lowe's ratio test
        let ratioThresh = options.ratioThresh
        var goodMatches: [CVBDMatch] = []
        for i in knnMatches.indices {
            if knnMatches[i][0].distance < Float(ratioThresh) * knnMatches[i][1].distance {
                goodMatches.append(knnMatches[i][0])
            }
        }
        
        guard goodMatches.count >= 4 else {
            let result = FeatureMatchingResult(goodMatchCount: goodMatches.count, determinant: 0, score: 0, rectangle: nil)
            return result
        }
        
        // Localize the object
        var objectPoints: [CGPoint] = []
        var scenePoints: [CGPoint] = []
        for i in goodMatches.indices {
            objectPoints.append(objectKeypoints[Int(goodMatches[i].queryIdx)].pt)
            scenePoints.append(sceneKeypoints[Int(goodMatches[i].trainIdx)].pt)
        }
        let H = CVBCalib3D.findHomography2f(objectPoints.map { NSValue(point: $0) },
                                            dst: scenePoints.map { NSValue(point: $0) },
                                            method: .RANSAC)
        let determinant = H.empty() ? 0.0 : CVBCore.determinant(H)
        
        let score: CGFloat = CGFloat(goodMatches.count) / CGFloat(objectKeypoints.count)
        
        let objectRect: [CGPoint] = [
            CGPoint.zero,
            CGPoint(x: Int(object.cols()), y: 0),
            CGPoint(x: Int(object.cols()), y: Int(object.rows())),
            CGPoint(x: 0, y: Int(object.rows())),
        ]
        
        let objectRectValue = objectRect.map { NSValue(point: $0) }
        let objectRectInScene: [CGPoint] = {
            guard !H.empty() else {
                return Array(repeating: CGPoint.zero, count: 4)
            }
            
            return CVBCore.perspectiveTransform2f(objectRectValue, m: H).map { $0.pointValue }
        }()
        let rectangle = Rectangle(topLeft: objectRectInScene[0],
                                  topRight: objectRectInScene[1],
                                  bottomLeft: objectRectInScene[2],
                                  bottomRight: objectRectInScene[3])
        
        // Draw preview image
        let previewImage = CVBMat()
        CVBFeatures2D.drawMatches(object, keypoints1: objectKeypoints, img2: scene, keypoints2: sceneKeypoints, matches: goodMatches, outImg: previewImage)
        let objectRectInPreview: [CGPoint] = objectRectInScene.map { CGPoint(x: $0.x + CGFloat(object.cols()), y: $0.y) }
        // RGB red color -> BGR blue color
        CVBimgproc.line(previewImage, pt1: objectRectInPreview[0], pt2: objectRectInPreview[1], color: .red, thickness: 4)
        CVBimgproc.line(previewImage, pt1: objectRectInPreview[1], pt2: objectRectInPreview[2], color: .red, thickness: 4)
        CVBimgproc.line(previewImage, pt1: objectRectInPreview[2], pt2: objectRectInPreview[3], color: .red, thickness: 4)
        CVBimgproc.line(previewImage, pt1: objectRectInPreview[3], pt2: objectRectInPreview[0], color: .red, thickness: 4)
        let previewCGImage = previewImage.imageRef().takeRetainedValue()
        let result = FeatureMatchingResult(goodMatchCount: goodMatches.count,
                                           determinant: determinant,
                                           score: score,
                                           rectangle: rectangle,
                                           previewImage: NSImage(cgImage: previewCGImage, size: .zero))
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, String(describing: result))
        return result
    }
        
}

extension OpenCVService {
    public struct FLANNOptions {
        public var enabled = true
        public var minHessian = 400.0
        public var ratioThresh = 0.6       // Lowe's ratio 0.4 ~ 0.6
        
        public init(enabled: Bool = true, minHessian: Double = 400.0, ratioThresh: Double = 0.8) {
            self.enabled = enabled
            self.minHessian = minHessian
            self.ratioThresh = ratioThresh
        }
    }
    
    public struct FeatureMatchingResult: Identifiable {
        public let id = UUID()
        public let goodMatchCount: Int
        public let determinant: Double
        public let score: CGFloat
        public let rectangle: Rectangle?
        public let previewImage: NSImage?
        
        public init() {
            self.init(goodMatchCount: 0, determinant: 0, score: 0)
        }
        
        public init(goodMatchCount: Int, determinant: Double, score: CGFloat, rectangle: Rectangle? = nil, previewImage: NSImage? = nil) {
            self.goodMatchCount = goodMatchCount
            self.determinant = determinant
            self.score = score
            self.rectangle = rectangle
            self.previewImage = previewImage
        }
    }
}

public struct Rectangle {
    public var topLeft: CGPoint
    public var topRight: CGPoint
    public var bottomLeft: CGPoint
    public var bottomRight: CGPoint
}
