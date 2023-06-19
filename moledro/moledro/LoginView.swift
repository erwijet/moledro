//
//  LoginView.swift
//  moledro
//
//  Created by Tyler Holewinski on 6/11/23.
//

import SwiftUI
import GoogleSignIn
import FirebaseAuth

struct LoginView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    
    var body: some View {
        VStack {
            Spacer()
        
            Text("Welcome to Moledro Archives")
                .fontWeight(.bold)
                .font(.largeTitle)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            GoogleSignInButton()
                .padding()
                .onTapGesture {
                    viewModel.signIn()
                }
        }
    }
}
