//
//  GoogleSignInButton.swift
//  moledro
//
//  Created by Tyler Holewinski on 6/18/23.
//

import SwiftUI
import GoogleSignIn

struct GoogleSignInButton: UIViewRepresentable {
    @EnvironmentObject var viewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    
    private var button = GIDSignInButton()
    
    func makeUIView(context: Context) -> GIDSignInButton {
        button.colorScheme = colorScheme == .dark ? .dark : .light
        return button
    }
    
    func updateUIView(_ uiView: GIDSignInButton, context: Context) {
        button.colorScheme = colorScheme == .dark ? .dark : .light
    }
}
