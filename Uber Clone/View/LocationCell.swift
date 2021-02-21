//
//  LocationCell.swift
//  Uber Clone
//
//  Created by be RUPU on 9/12/20.
//  Copyright © 2020 be RUPU. All rights reserved.
//

import UIKit
import MapKit

class LocationCell : UITableViewCell{

    @IBOutlet var titleLabel: UILabel!
    
    @IBOutlet var addressLabel: UILabel!
    

    var placemark: MKPlacemark?{
             didSet {
                titleLabel.text = placemark?.name
                addressLabel.text = placemark?.address
             }
         }
}


extension MKPlacemark {
    
    var address: String? {
        guard  let subThoroughfare = subThoroughfare else {return nil}
        guard  let thoroughfare = thoroughfare else {return nil}
        guard  let locality = locality else {return nil}
        guard  let adminArea = administrativeArea else {return nil}
        
        return "\(subThoroughfare) \(thoroughfare), \(locality), \(adminArea)"
    }
}
