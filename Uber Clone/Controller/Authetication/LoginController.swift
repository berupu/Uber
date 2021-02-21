//
//  LoginController.swift
//  Uber Clone
//
//  Created by be RUPU on 21/11/20.
//  Copyright © 2020 be RUPU. All rights reserved.
//

import UIKit
import Firebase

class LoginController: UIViewController {
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var passwordTexxtField: UITextField!
    @IBOutlet var logIn: UIButton!
    
    //MARK: - Properties

    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = true

//        checkUserISLoggedIn()
//        signOut()
     
        
    }
    
    //status bar style.
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @IBAction func logInPressed(_ sender: Any) {
        
        guard  let email = emailTextField.text else { return }
        guard  let password = passwordTexxtField.text else { return }
        
        Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
            
            if let error = error {
                print("DEBUG: Failed log in \(error.localizedDescription)")
            }
            self.dismiss(animated: true, completion: nil)
            print("Succefully logged in")
        }
 
    }
  
}
