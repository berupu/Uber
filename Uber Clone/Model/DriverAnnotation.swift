//
//  DriverAnnotation.swift
//  Uber Clone
//
//  Created by be RUPU on 4/12/20.
//  Copyright © 2020 be RUPU. All rights reserved.
//

import MapKit

class DriverAnnotation : NSObject, MKAnnotation {
    
    dynamic var coordinate: CLLocationCoordinate2D
    var uid : String
    
    
    init(uid : String, coordinate: CLLocationCoordinate2D) {
        self.uid = uid
        self.coordinate = coordinate
    }
    
    func updateAnnotationPosition(withCoordinate coordinate: CLLocationCoordinate2D){
        UIView.animate(withDuration: 0.2){
            self.coordinate = coordinate
        }
    }
}
