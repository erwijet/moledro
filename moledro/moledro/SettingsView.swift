//
//  SettingsView.swift
//  moledro
//
//  Created by Tyler Holewinski on 6/11/23.
//

import SwiftUI
import GoogleSignIn

struct SettingsView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    
    private let user = GIDSignIn.sharedInstance.currentUser
    
    var body: some View {
        NavigationView {
            Form {
                Section("My Account") {
                    NavigationLink(destination: AccountView()) {
                        
                        HStack {
                            AsyncImage(url: user?.profile?.imageURL(withDimension: 64)).clipShape(Circle()).padding(.trailing)
                            
                            VStack(alignment: .leading) {
                                Text(user?.profile?.name ?? "")
                                    .fontWeight(.bold)
                                
                                
                                Text(user?.profile?.email ?? "")
                                    .fontWeight(.light)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct AccountView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    
    private let user = GIDSignIn.sharedInstance.currentUser
    
    var body: some View {
        Form {
            Section {
                LabeledContent("Name", value: user?.profile?.name ?? "")
                LabeledContent("Email", value: user?.profile?.email ?? "")
            }
            
            
            Button("Sign Out") {
                viewModel.signOut()
            }
        }
        .navigationTitle("My Account")
    }
}
