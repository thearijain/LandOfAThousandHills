//
//  ViewController.swift
//  LandOfAThousandHills
//
//  Created by Ari Jain on 5/18/21.
//

import UIKit
import AuthenticationServices
import FirebaseAuth
import FirebaseDatabase

//MARK: some of this stuff might go into a view class instead
class LoginViewController: UIViewController {
    
    let database = Database.database().reference()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = .red
        
        setupAppleSignInButton()
    }
}

extension LoginViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }

}

fileprivate var currentNonce: String? // helps w network security

extension LoginViewController {
    func setupAppleSignInButton() {
        let button = ASAuthorizationAppleIDButton(authorizationButtonType: .continue, authorizationButtonStyle: .white)
        button.addTarget(self, action: #selector(signInButtonTapped), for: .touchUpInside)
        button.center = view.center
        view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 60),
            button.widthAnchor.constraint(equalToConstant: 280),
            button.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        ])
    }

    
    @objc func signInButtonTapped() {
        performSignIn()
    }

    func performSignIn() {
        let request = createAppleIDRequest()
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        
        authorizationController.performRequests()
            
    }
    
    func createAppleIDRequest() -> ASAuthorizationAppleIDRequest {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let nonce = randomNonceString()
        request.nonce = sha256(nonce)
        currentNonce = nonce
                
        return request
    }
    
}


extension LoginViewController: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("callback recieved but no login request was there")

            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("unable to serialize token string from data")
                return
            }
            
            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nonce)
            
            Auth.auth().signIn(with: credential) { (authDataResult, error) in
                if let error = error {
                    print("shit it didn't work")
                    self.outputErrorToUser(error.localizedDescription)
                }
                if let user = authDataResult?.user {
                    print("nice, account created and signed in")
                    print("email ", user.email ?? "unknown")
                    print("id ", user.uid)
                    
//                    self.nextScreen() where we move on past the login screen

                }
            }
        }
    }
    
    // for funsies
    func outputErrorToUser(_ error: String) {
        let alertController = UIAlertController(title: "Banned account.", message: error, preferredStyle: .alert)

        let defaultAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
        alertController.addAction(defaultAction)

        self.present(alertController, animated: true, completion: nil)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // need to look at when sign in with apple fails
    }

}

