//
//  PickUpController.swift
//  Uber Clone
//
//  Created by be RUPU on 21/1/21.
//  Copyright © 2021 be RUPU. All rights reserved.
//

import UIKit
import MapKit

//MARK: - Protocol(1)
protocol PickUpControllerDelegate: class {
    func didAcceptTrip(_ trip: Trip)
}

class PickUpcontroller: UIViewController {
    
    weak var delegate: PickUpControllerDelegate?
    private let mapView = MKMapView()
    let trip : Trip
    
    
    private lazy var circularProgressView: CircularProgressView = {
        let frame = CGRect(x: 0, y: 0, width: 360, height: 360)
        let cp = CircularProgressView(frame: frame)
        
        cp.addSubview(mapView)
        mapView.setDimensions(height: 268, width: 268)
        mapView.layer.cornerRadius = 268 / 2
        mapView.centerX(inView: cp)
        mapView.centerY(inView: cp, constant: 32)
        
        return cp
        
        
    }()

    private let cancelButton: UIButton = {
           let button = UIButton(type: .system)
           button.setImage(#imageLiteral(resourceName: "baseline_clear_white_36pt_2x").withRenderingMode(.alwaysOriginal), for: .normal)
           button.addTarget(self, action: #selector(handleDismissal), for: .touchUpInside)
           return button
       }()
    
    private let pickupLabel: UILabel = {
        let label = UILabel()
        label.text = "would you like to pick this passenger"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .white
        return label
    }()
    
    
     private let acceptTripButton: UIButton = {
           let button = UIButton(type: .system)
           button.addTarget(self, action: #selector(handleAcceptTrip), for: .touchUpInside)
           button.backgroundColor = .white
           button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
           button.setTitleColor(.black, for: .normal)
           button.setTitle("ACCEPT TRIP", for: .normal)
           return button
       }()
    
    init(trip: Trip) {
        self.trip = trip
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
  
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        configureMapView()
        self.perform(#selector(animateProgress), with: nil, afterDelay: 0.5  )
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @objc func handleAcceptTrip(){
        DriverService.shared.acceptTrip(trip: trip) { (error, ref) in
            //MARK: - Protocol(2) (1 is on the same class)
            self.delegate?.didAcceptTrip(self.trip)
        }
    }
    
    @objc func animateProgress() {
        circularProgressView.animatePulsatingLayer()
        circularProgressView.setProgressWithAnimation(duration: 7, value: 0) {
            DriverService.shared.updateTripState(trip: self.trip, state: .denied) { (err, ref) in
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    @objc func handleDismissal() {
        dismiss(animated: true, completion: nil)
    }
    
    func configureMapView(){
        
        //This will set region 1000meters beside pickupCoordinates
        let region = MKCoordinateRegion(center: trip.pickupCoordinates, latitudinalMeters: 1000, longitudinalMeters: 1000)
        
        mapView.setRegion(region, animated: false)
        
        mapView.addAnnotationAndSelect(forCoordinate: trip.pickupCoordinates)
    }
    
    func configureUI(){
        view.backgroundColor = .backgroundColor
        
        view.addSubview(cancelButton)
        cancelButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor,
                            paddingLeft: 16)
        
        view.addSubview(circularProgressView)
        circularProgressView.setDimensions(height: 360, width: 360)
        circularProgressView.anchor(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 32)
        circularProgressView.centerX(inView: view)
        
        view.addSubview(pickupLabel)
        pickupLabel.centerX(inView: view)
        pickupLabel.anchor(top: circularProgressView.bottomAnchor, paddingTop: 32)
        
        view.addSubview(acceptTripButton)
        acceptTripButton.anchor(top: pickupLabel.bottomAnchor, left: view.leftAnchor,
                                right: view.rightAnchor, paddingTop: 16, paddingLeft: 32,
                                paddingRight: 32, height: 50)
    }
    
    
}
