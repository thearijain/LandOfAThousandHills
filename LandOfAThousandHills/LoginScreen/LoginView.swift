//
//  LoginView.swift
//  LandOfAThousandHills
//
//  Created by Komal Shrivastava on 5/21/21.
//

import Foundation
import UIKit
import AuthenticationServices

class LoginView: UIView {
    
    let appleButton : ASAuthorizationAppleIDButton = {
        let button = ASAuthorizationAppleIDButton(authorizationButtonType: .continue, authorizationButtonStyle: .white)
        return button

    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        sharedInit()
    }
    
    func sharedInit() {
        backgroundColor = .red
    }
    
    override func layoutSubviews() {
        addSubview(appleButton)
        setupAppleSignInButton()
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.window!
    }

    func setupAppleSignInButton() {
        appleButton.center = center
        appleButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            appleButton.heightAnchor.constraint(equalToConstant: 60),
            appleButton.widthAnchor.constraint(equalToConstant: 280),
            appleButton.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            appleButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -200)
        ])
    }
    
}
