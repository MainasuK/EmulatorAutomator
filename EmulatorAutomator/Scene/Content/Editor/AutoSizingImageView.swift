//
//  AutoSizingImageView.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-7-16.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Cocoa

// Ref: https://developer.apple.com/library/archive/samplecode/PictureSwiper/Introduction/Intro.html
final class AutoSizingImageView: NSImageView {
    
    override func setFrameSize(_ newSize: NSSize) {
        if let scrollView = enclosingScrollView {
            super.setFrameSize(scrollView.frame.size)
        } else {
            super.setFrameSize(newSize)
        }
    }
    
}
