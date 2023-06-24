//
//  ContentView.swift
//  moledro
//
//  Created by Tyler Holewinski on 6/11/23.
//

import GoogleSignIn
import SwiftUI

struct MainView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var currentTabIndex = 0
    
    var body: some View {
        if viewModel.didAttemptSessionRestore {
            switch viewModel.state {
            case .signedOut: LoginView()
            case .signedIn:
                TabView(selection: $currentTabIndex) {
                    TabItemView(systemName: "books.vertical", tag: 0, activeIdx: currentTabIndex) {
                        LibraryView()
                    }.name("Libraries")
                    
                    TabItemView(systemName: "barcode.viewfinder", tag: 1, activeIdx: currentTabIndex) {
                        ScannerView()
                    }.name("Scan")
                    
                    TabItemView(systemName: "gearshape", tag: 2, activeIdx: currentTabIndex) {
                        SettingsView()
                    }.name("Settings")
                    
                }
            }
        } else {
            ProgressView()
        }
    }
}

struct TabItemView<Content: View>: View {
    let systemName: String;
    let tag: Int;
    let activeIdx: Int;
    
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        content()
            .tabItem {
                Image(systemName: systemName).environment(\.symbolVariants, activeIdx == tag ? .fill : .none)
            }
            .tag(tag)
    }
    
    //
    
    @ViewBuilder func name(_ name: String) -> some View {
        content()
            .tabItem {
                Image(systemName: systemName).environment(\.symbolVariants, activeIdx == tag ? .fill : .none)
                Text(name)
            }
            .tag(tag)
    }
}
