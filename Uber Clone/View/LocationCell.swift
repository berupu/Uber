//
//  LocationCell.swift
//  Uber Clone
//
//  Created by be RUPU on 9/12/20.
//  Copyright © 2020 be RUPU. All rights reserved.
//

import UIKit
import MapKit

class LocationCell : UITableViewCell {

    @IBOutlet var titleLabel: UILabel!
    
    @IBOutlet var addressLabel: UILabel!
    

    var placemark: MKPlacemark?{
             didSet {
                titleLabel.text = placemark?.name
                addressLabel.text = placemark?.subtitle
             }
         }
}
