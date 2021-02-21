//
//  User.swift
//  Uber Clone
//
//  Created by be RUPU on 2/12/20.
//  Copyright © 2020 be RUPU. All rights reserved.
//

import CoreLocation

enum AccountType: Int {
    case passenger
    case driver
}

struct User {
    let fullName : String
    let email : String
    var accountType : AccountType!
    var location: CLLocation?
    let uid: String
    var homeLocation: String?
    var workLocation: String?
    
    var firstInitial: String { return String(fullName.prefix(1)) } //first letter of FullName
    
    init(uid: String,dictionary : [String : Any]) {
        self.uid = uid
        self.fullName = dictionary["fullName"] as? String ?? ""
        self.email = dictionary["email"] as? String ?? ""
        
        if let home = dictionary["homeLocation"] as?  String {
            self.homeLocation = home
        }
        
        if let work = dictionary["workLocation"] as?  String {
            self.workLocation = work
        }
        
        if let index = dictionary["accountType"] as?  Int {
            self.accountType = AccountType(rawValue: index)
        }
    }
}
