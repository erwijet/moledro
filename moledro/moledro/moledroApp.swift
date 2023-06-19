//
//  moledroApp.swift
//  moledro
//
//  Created by Tyler Holewinski on 6/11/23.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn

extension moledroApp {
    private func setupAuth() {
        FirebaseApp.configure()
    }
}

@main
struct moledroApp: App {
    @StateObject var viewModel = AuthViewModel()
    
    init() {
        setupAuth()
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(viewModel)
                .onAppear {
                    viewModel.attemptSessionRestore()
                }
        }
    }
}
