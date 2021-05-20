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

fileprivate var currentNonce: String? // helps w network security

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
//            button.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
            button.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -200)
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
                fatalError("Callback recieved but no login request was there.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token.")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data.")
                return
            }
            
            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nonce)
            
            Auth.auth().signIn(with: credential) { (authDataResult, error) in
                if let error = error {
                    print("Error with signing in.")
                    self.outputErrorToUser(error.localizedDescription)
                }
                if let user = authDataResult?.user {
                     
                    self.database.child(user.uid).observeSingleEvent(of: .value, with: { snapshot in
                        guard (snapshot.value as? [String: Any]) != nil else {
                            // user doesn't exist
                            print("\n data does not exist, creating user \n ")
                            let object: [String: Any] = [
                                "name": "Ari Jain" as NSObject,
                                "email": user.email ?? "unknown",
                                "balance": 0
                            ]
                            self.database.child(user.uid).setValue(object)
                            return
                        }
                        // user exists
                        print("\n user exists \n")
                        return

                    })

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

