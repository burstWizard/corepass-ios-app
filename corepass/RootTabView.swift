//
//  RootTabView.swift
//  corepass
//
//  Created by Hari Shankar on 9/4/25.
//

import SwiftUI

enum AppTab : Hashable {
    case Profile
    case NewPass
    case MyPasses
    case TestView
}

struct RootTabView : View {
    @State private var selected : AppTab = .MyPasses
    
    var body : some View {
        
        TabView(selection: $selected) {
            Tab("My Passes", systemImage: "list.bullet.rectangle", value: AppTab.MyPasses) {
                MyPassesView()
                    .toolbarBackground(Color(.white), for: .tabBar)
                    .toolbarBackground(.visible, for: .tabBar)
                    
            }
            
            Tab("New Pass", systemImage: "plus.square", value: AppTab.NewPass) {
                NewPassView()
                    .toolbarBackground(Color(.white), for: .tabBar)
                    .toolbarBackground(.visible, for: .tabBar)
            }
            
            Tab("Account", systemImage: "person.crop.circle.fill", value: AppTab.Profile) {
                AccountView()
                    .toolbarBackground(Color(.white), for: .tabBar)
                    .toolbarBackground(.visible, for: .tabBar)
            }
            
            
        }
        .tint(.black)
        
        
    }
    
}

#Preview {
    RootTabView()
}
