//
//  SignUpController.swift
//  Uber Clone
//
//  Created by be RUPU on 25/11/20.
//  Copyright © 2020 be RUPU. All rights reserved.
//

import UIKit
import Firebase
import GeoFire

class SignUpController: UIViewController {
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var fullNameTextField: UITextField!
    @IBOutlet var accountTypeSegmentedControl: UISegmentedControl!
    
    private let location = LocationHandler.shared.locationManager.location
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.isNavigationBarHidden = true
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .lightContent
    }
    
    @IBAction func handleSignUp(_ sender: Any) {
        
        guard  let email = emailTextField.text else { return }
        guard  let password = passwordTextField.text else { return }
        guard let fullName = fullNameTextField.text else { return }
        let accountTypeIndex = accountTypeSegmentedControl.selectedSegmentIndex
        
        Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
            
            if let error = error {
                print("Failed to register user with error \(error)")
                return
            }
            
            
            guard let uid = result?.user.uid else { return }
            
            let values = ["email": email,
                          "fullName": fullName,
                          "accountType": accountTypeIndex] as [String : Any]
            
            if accountTypeIndex == 1 {
                
                
                let geofire = GeoFire(firebaseRef: REF_DRIVER_LOCATIONS)
                guard let location = self.location else { return }
                
                //MARK: - Geofire store that location to this refrenrence.

                geofire.setLocation(location, forKey: uid) { (error) in
                    self.uploadUserDataAndHomeController(uid: uid, values: values)
                }
            }
            self.uploadUserDataAndHomeController(uid: uid, values: values)
        }
    }
    
    func uploadUserDataAndHomeController(uid: String, values: [String : Any]) {
        
        Database.database().reference().child("users").child(uid).updateChildValues(values) { (error, ref) in
            
            print("successfully register user and saved data..")
            self.dismiss(animated: true, completion: nil)
            
        }
    }
}
