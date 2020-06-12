//
//  OutlineView.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-4-30.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import Cocoa
import SwiftUI

struct OutlineView: NSViewRepresentable {
    
    func makeNSView(context: Context) -> NSOutlineView {
        let outlineView = NSOutlineView()
        
        return outlineView
    }
    
    func updateNSView(_ nsView: NSOutlineView, context: Context) {
        
    }
    
}

struct OutlineView_Previews: PreviewProvider {
    static var previews: some View {
        OutlineView()
    }
}
