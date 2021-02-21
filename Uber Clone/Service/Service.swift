//
//  Service.swift
//  Uber Clone
//
//  Created by be RUPU on 1/12/20.
//  Copyright © 2020 be RUPU. All rights reserved.
//

import Firebase
import CoreLocation
import GeoFire

//MARK: - DatebaseRefs

let DB_REF = Database.database().reference()
let REF_USERS = DB_REF.child("users")
let REF_DRIVER_LOCATIONS = DB_REF.child("driver-locations")
let REF_TRIPS = DB_REF.child("trips")

//MARK: - Driver Service

struct DriverService{
    static let shared = DriverService()
    
    //MARK: - Getting back Trip details from firebase trip section.
       func observeTrips(completion: @escaping(Trip) -> Void){
           
           REF_TRIPS.observe(.childAdded) { (snapshot) in
               guard let dictionary = snapshot.value as? [String: Any] else {return}
               let uid = snapshot.key  // passenger uid
               let trip = Trip(passengerUid: uid, dictionary: dictionary)
               completion(trip)
           }
       }
    
    func observeTripCancelled(trip: Trip, completion: @escaping() -> Void) {
                
        //MARK: - observing trip if it removed or not.
        REF_TRIPS.child(trip.passengerUid).observeSingleEvent(of: .childRemoved) { _ in
            completion()
        }
    }
    
    func acceptTrip(trip: Trip, completion: @escaping(Error?, DatabaseReference) -> Void  ){
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let values = ["driverUid": uid,
                      "state": TripState.accepted.rawValue ] as [String : Any]
        
        //MARK: - Updating trip.passengerUid with the new values.
        
        REF_TRIPS.child(trip.passengerUid).updateChildValues(values, withCompletionBlock: completion)
        
    }
    
    func updateTripState(trip: Trip, state: TripState, completion: @escaping(Error?, DatabaseReference) -> Void){
    REF_TRIPS.child(trip.passengerUid).child("state").setValue(state.rawValue, withCompletionBlock: completion)
    
    if state == .completed {
        REF_TRIPS.child(trip.passengerUid).removeAllObservers()
       }
    }
    
    func updateDriverLocation(location: CLLocation){
           guard let uid = Auth.auth().currentUser?.uid else {return}
           
           //MARK: - Everytime this will change the driver location on the firebase when it get changed
           let geofire = GeoFire(firebaseRef: REF_DRIVER_LOCATIONS)
           GeoFire.setValue(location, forKey: uid)
    }
       
    
}

//MARK: - Passenger Service

struct PassengerService {
    static let shared = PassengerService()
    
    func fetchDrivers(location: CLLocation, completion : @escaping(User) -> Void) {
        
        let geofire = GeoFire(firebaseRef: REF_DRIVER_LOCATIONS)
        REF_DRIVER_LOCATIONS.observe(.value) { (snapshoot) in
            
            //MARK: - Geofire will fetch this Location within this radius and will give back this uid & location.
            geofire.query(at: location, withRadius: 50).observe(.keyEntered, with: { (uid, location) in

                Service.shared.fetchUserData(uid: uid) { (user) in
                    var driver = user
                    driver.location = location
                    completion(driver)
                }
                
            })

        }
    }
    
    
    func uploadTrip(_ pickupCoordinates: CLLocationCoordinate2D,_ destinationCoordinates: CLLocationCoordinate2D, completion: @escaping (Error?, DatabaseReference) -> Void ){
         
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let pickupArray = [pickupCoordinates.latitude, pickupCoordinates.longitude]
        let destinationArray = [destinationCoordinates.latitude, destinationCoordinates.longitude]
        
        let values = ["pickupCoordinates": pickupArray,
                      "destinationCoordinates": destinationArray,
                      "state": TripState.requested.rawValue] as [String : Any]
        
        REF_TRIPS.child(uid).updateChildValues(values, withCompletionBlock: completion)
    
    }
    
    func observeCurrentTrip(completion: @escaping(Trip) -> Void){
           guard let uid = Auth.auth().currentUser?.uid else {return}

           REF_TRIPS.child(uid).observe(.value) { (snapshot) in
               guard let dictionary = snapshot.value as? [String: Any] else {return}
               let uid = snapshot.key
               let trip = Trip(passengerUid: uid, dictionary: dictionary)
               completion(trip)
           }
       }
    
    func deleteTrip(completion: @escaping(Error?, DatabaseReference) -> Void){
        
        guard let uid = Auth.auth().currentUser?.uid else {return}
        //MARK: - Remove item from Firebase.
        REF_TRIPS.child(uid).removeValue(completionBlock: completion)
     
    }
    
    func saveLocation(locationString: String, type: LocationType, completion: @escaping (Error?, DatabaseReference) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let key: String = type == .home ? "homeLocation" : "workLocation"
        REF_USERS.child(uid).child(key).setValue(locationString, withCompletionBlock: completion)
    }
    
}


//MARK: -  Shared Service

struct Service {
    
    //static variable can be access from anywhere.
    static let shared = Service()
    let currentUid = Auth.auth().currentUser?.uid
    
    //MARK: - Escaping: Transfer value to another controller with @escaping
    
    //MARK: - Escaping method can be called with a given data and with that data this will give you a completion with the expected data.
    
    func fetchUserData(uid: String, completion: @escaping(User) -> Void){
        
        //MARK: - Fetching user data only once and then stop.
                
        REF_USERS.child(uid).observeSingleEvent(of: .value) { (snapshot) in
            
            guard let dictionary = snapshot.value as? [String : Any] else { return }
            let uid = snapshot.key
            let user = User(uid: uid, dictionary: dictionary)
            completion(user)
            
        }
    }
   
}


