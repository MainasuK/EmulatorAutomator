//
//  MainWindowView.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-4-21.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import SwiftUI

struct MainWindowView: View {
    
    var body: some View {
        VStack {
            Text("Hello, World!")
        }
        .frame(
            minWidth: 960, idealWidth: 1920, maxWidth: .infinity,
            minHeight: 540, idealHeight: 1080, maxHeight: .infinity,
            alignment: .center
        )
        //.background(Color.red)
    }
    
}

struct MainWindowView_Previews: PreviewProvider {
    static var previews: some View {
        MainWindowView()
    }
}
