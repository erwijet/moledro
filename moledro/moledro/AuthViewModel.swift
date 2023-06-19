//
//  AuthViewModel.swift
//  moledro
//
//  Created by Tyler Holewinski on 6/18/23.
//

import Foundation
import Firebase
import FirebaseAuth
import GoogleSignIn

class AuthViewModel: ObservableObject {
    enum SignInState {
        case signedIn
        case signedOut
    }
    
    @Published var didAttemptSessionRestore: Bool = false
    @Published var state: SignInState = .signedOut
    
    func signIn() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        guard let rootViewController = windowScene.windows.first?.rootViewController else { return }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [unowned self] res, err in
            authenticateUser(for: res?.user, with: err)
        }
    }
    
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        
        do {
            try Auth.auth().signOut()
            state = .signedOut
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func attemptSessionRestore() {
        if (didAttemptSessionRestore) { return }
        
        if GIDSignIn.sharedInstance.hasPreviousSignIn() {
            GIDSignIn.sharedInstance.restorePreviousSignIn { [unowned self] user, err in
                authenticateUser(for: user, with: err)
            }
        } else {
            didAttemptSessionRestore = true
        }
    }
    
    private func authenticateUser(for user: GIDGoogleUser?, with error: Error?) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        
        guard let accessToken = user?.accessToken, let idToken = user?.idToken else { return }
        
        let credential = GoogleAuthProvider.credential(withIDToken: idToken.tokenString, accessToken: accessToken.tokenString)
        
        Auth.auth().signIn(with: credential) { [unowned self] _, error in
            didAttemptSessionRestore = true
            
            if let error = error {
                print(error.localizedDescription)
            } else {
                self.state = .signedIn
            }
        }
    }
}
