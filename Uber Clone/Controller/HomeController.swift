//
//  HomeController.swift
//  Uber Clone
//
//  Created by be RUPU on 25/11/20.
//  Copyright © 2020 be RUPU. All rights reserved.
//

import UIKit
import Firebase
import MapKit

private enum ActionButtonConfiguration {
    case showMenu
    case dissmissActionView
    
    //MARK: - this will first start with showMenu case
    init() {
        self = .showMenu
    }
}

   enum AnnotationType: String {
    case pickup
    case destination
   }

protocol HomeControllerDelegate: class {
    func handleMenuToggle()
}

enum RideActionViewConfiguration{
    case requestRide
    case tripAccepted
    case driverArrived
    case pickupPassenger
    case tripInProgress
    case endTrip
    
    init() {
        self = .requestRide
    }
}

enum ButtonAction: CustomStringConvertible{
    case requestRide
    case cancel
    case getDirections
    case pickup
    case dropOff
    
    
    //MARK: - This switch case will save a string on description variable for the selected option.
    var description: String{
        switch self {
        case .requestRide: return "CONFIRM UBERX"
        case .cancel: return "CANCEL RIDE"
        case .getDirections: return "GET DIRECTION"
        case .pickup: return "PICKUP PASSENGER"
        case .dropOff: return "DROP OFF PASSENGER"
        }
    }
    
    init() {
        self = .requestRide
    }
}



class HomeController : UIViewController {
        
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var whereToLabel: UILabel!
    @IBOutlet var locationInputView: UIView!
    @IBOutlet var startingLocationIndicatorView: UIView!
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var locationInputViewUserLabel: UILabel!
    
    @IBOutlet var startingLocationTexxtfield: UITextField!
    @IBOutlet var destinationTextField: UITextField!
   
    @IBOutlet var actionButton: UIButton!
    @IBOutlet var whereToLabelDot: UIView!
    @IBOutlet var rideActionView: UIView!
    @IBOutlet var uberXview: UIView!
    @IBOutlet var rideTitleLabel: UILabel!
    @IBOutlet var rideAddressLabel: UILabel!
    
    @IBOutlet var confirmUberXButton: UIButton!
    
    @IBOutlet var xCircle: UILabel!
    @IBOutlet var xLabel: UILabel!
    
    @IBOutlet var menuView: UIView!
    
    private let locationManger = LocationHandler.shared.locationManager
    
    private var searchResults = [MKPlacemark]()
    
    private var savedLocations = [MKPlacemark]()
    
    private var actionButtonConfig = ActionButtonConfiguration()
    
    private var route : MKRoute?
    
    private var selectedPlace : MKPlacemark?
    
    weak var delegate: HomeControllerDelegate?
    
    private var isExpanded = true
    
    
    var buttonAction = ButtonAction()
    var rideActionUser : User?
    
    var config = RideActionViewConfiguration() {
        didSet{
            configureUI(withConfig: config)
        }
    }
    

     var user: User? {
        didSet {
            locationInputViewUserLabel.text = user?.fullName
            if user?.accountType == .passenger {
                fetchDrivers()
                whereToLabel.alpha = 1
                observeCurrentTrip()
                configureSavedUserLocations()
            }else {
                whereToLabelDot.alpha = 0
                observeTrips()
            }
        }
    }
    
    private var trip: Trip? {
        didSet{
            guard let user = user else {return}
            
            if user.accountType == .driver {
                guard let trip = trip else { return }
                let controller = PickUpcontroller(trip: trip)
                //MARK: - Protocol(3)  (2 is on the PickUpController class)
                controller.delegate = self
                controller.modalPresentationStyle = .fullScreen
                self.present(controller, animated: true, completion: nil)
            }else {
                print("DEBUG: show ride action view for accepted trip")
            }

        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //MARK: - shadow settings.
        whereToLabel.layer.shadowOpacity = 0.55
        rideActionView.layer.shadowOpacity = 0.55
        rideActionView.frame.origin.y = view.frame.height
        
        uberXview.layer.cornerRadius = 30
        
        //MARK: - Remove TableView empty cell.
        tableView.tableFooterView = UIView()
        
        //MARK: - Hide tableview.
        tableView.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: view.frame.height - 200)
        
        navigationController?.isNavigationBarHidden = true
        checkUserISLoggedIn()
        enableLocationServices()
        fetchUserData()
        
        
//        signOut()
        
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        guard let trip = trip else {return}
    }
    
    
    
    
  
    
    //MARK: - Paasenger API
    
    func observeCurrentTrip(){
        PassengerService.shared.observeCurrentTrip { trip in
            self.trip = trip
            guard let state = trip.state else { return }
            guard let driverUid = trip.driverUid else {return}
            
            switch state {
            case .requested:
                break
            case .denied:
                self.shouldPresentLoadingView(false)
                self.presentAlertController(withTitle: "Opps", message: "It's looks like we couldn't find you a drive.Please try again...")
                PassengerService.shared.deleteTrip { (err, ref) in
                    self.centerMapOnUserLocation()
                    self.configureActionButton(config: .showMenu)
                    self.whereToLabel.alpha = 1
                    self.whereToLabelDot.alpha = 1
                    self.removeAnnotationAndOverlay()
                }
            case .accepted:
                self.shouldPresentLoadingView(false, message: "")
                self.removeAnnotationAndOverlay()
                self.zoomForActiveTrip(withDriverUid: driverUid)
    
                Service.shared.fetchUserData(uid: driverUid) { (driver) in
                       self.animateRideActionView(shouldShow: true, config: .tripAccepted, user: driver)
                   }
            case .driverArrived:
                self.config = .driverArrived
            case .inProgress:
                self.config = .tripInProgress
            case .arrivedAtDestination:
                self.config = .endTrip
            case .completed:

                PassengerService.shared.deleteTrip { (error, ref) in

                    self.animateRideActionView(shouldShow: false)
                    self.centerMapOnUserLocation()
                    self.configureActionButton(config: .showMenu)
                    self.whereToLabel.alpha = 1
                    self.whereToLabelDot.alpha = 1
                    self.presentAlertController(withTitle: "Trip Completed",
                                                message: "We hope you enjoyed the trip")
                }
            }
        }
    }
    
    func startTrip(){
        guard let trip = self.trip else {return}
        DriverService.shared.updateTripState(trip: trip, state: .inProgress) { (err, ref) in
            self.config = .tripInProgress
            self.removeAnnotationAndOverlay()
            self.mapView.addAnnotationAndSelect(forCoordinate: trip.destinationCoordinates)
            
            let placemark = MKPlacemark(coordinate: trip.destinationCoordinates)
            let mapItem = MKMapItem(placemark: placemark)
            
            self.setCustomRegion(withType: .destination, coordinates: trip.destinationCoordinates)
            self.generatePolyline(toDestination: mapItem)
            
            self.mapView.zoomToFit(annotations: self.mapView.annotations)
        }
    }
    
   
    
      func fetchDrivers(){
       
            guard let location = locationManger?.location else {return}
            PassengerService.shared.fetchDrivers(location: location) { (driver) in

                guard let coordinate = driver.location?.coordinate else {return}
                let annotation = DriverAnnotation(uid: driver.uid, coordinate: coordinate)

                //MARK: - Preventing duplicate annotation.
                
                var driverVisiable: Bool {
                    return self.mapView.annotations.contains { (annotation) -> Bool in
                        guard let driverAnno = annotation as? DriverAnnotation else {return false}
                        if driverAnno.uid == driver.uid {
    //                        print("DEBUG: handle annotation position")
                            driverAnno.updateAnnotationPosition(withCoordinate: coordinate)
                            self.zoomForActiveTrip(withDriverUid: driver.uid)
                            return true
                        }
                        return false
                    }
                    
                }
                
                if !driverVisiable {
                 self.mapView.addAnnotation(annotation)
                }
        
            }
        }
    
    
    //MARK: - Drivers API
    
    
    func observeTrips(){
        DriverService.shared.observeTrips { trip in
            self.trip = trip
        }
    }
    
    func observeCancelTrip(trip: Trip){
        DriverService.shared.observeTripCancelled(trip: trip) {
           self.removeAnnotationAndOverlay()
           self.animateRideActionView(shouldShow: false)
           self.centerMapOnUserLocation()
           self.presentAlertController(withTitle: "oops!", message: "The passenger has decide to cancel this ride. Press OK to continue")
       }
    }
    
    
    //MARK: - Shared API
        
    func fetchUserData(){
           guard let currentUid = Auth.auth().currentUser?.uid else {return}
           Service.shared.fetchUserData(uid: currentUid) { user in
               self.user = user
           }
       }
    
    //MARK: - checking if user logged in or not
    
    func checkUserISLoggedIn(){
        if Auth.auth().currentUser?.uid == nil {
            print("DEBUG: user not logged in..")
            DispatchQueue.main.async {
                
                print("DEBUG: user not logged in Go to Log in Screen")
                let nav = UINavigationController(rootViewController: LoginController())
                self.present(nav, animated: true, completion: nil)

            }
        } else {
            
            print("DEBUG: user id is \(String(describing: Auth.auth().currentUser?.uid))")
            present(HomeController(), animated: true, completion: nil)
            configureUI()
        }
    }
    
    func signOut(){
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                           print("DEBUG: user not logged in Go to Log in Screen")
                           let nav = UINavigationController(rootViewController: LoginController())
                           self.present(nav, animated: true, completion: nil)
                       }
        }catch {
            print("Debug: error signing out")
        }
    }
    
    //MARK: - Helper Function
    
    fileprivate func configureActionButton(config: ActionButtonConfiguration){
        
        switch config {
        case .showMenu:
            self.actionButton.setImage(#imageLiteral(resourceName: "baseline_menu_black_36dp"), for: .normal)
            self.actionButtonConfig = .showMenu
            
        case .dissmissActionView:
            actionButton.setImage(#imageLiteral(resourceName: "baseline_arrow_back_black_36dp"), for: .normal)
            actionButtonConfig = .dissmissActionView
        }
    }
    
    func configureSavedUserLocations() {
        guard let user = user else { return }
        savedLocations.removeAll()

        if let homeLocation = user.homeLocation {
            geocodeAddressString(address: homeLocation)
        }

        if let workLocation = user.workLocation {
            geocodeAddressString(address: workLocation)
        }
    }
    
  //MARK: - Go to location with hand Written address.
    func geocodeAddressString(address: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { (placemarks, error) in
            guard let clPlacemark = placemarks?.first else { return }
            let placemark = MKPlacemark(placemark: clPlacemark)
            self.savedLocations.append(placemark)
            self.tableView.reloadData()
        }
    }

    
    
    func configureUI(){
        configureMapView()
        
        whereToLabel.alpha = 0
        
        if user?.accountType == .passenger {
         UIView.animate(withDuration: 2){
            self.whereToLabel.alpha = 1
            }
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(presentLocationInfutView))
        whereToLabel.addGestureRecognizer(tap)
        
        locationInputView.alpha = 0
        locationInputView.layer.shadowOffset = CGSize(width: 0.5, height: 0.5)
        locationInputView.layer.shadowOpacity = 0.55
        
        startingLocationIndicatorView.layer.cornerRadius = 3
        
    }
    
    func configureMapView(){
        
        mapView.userTrackingMode = .follow
        
       }
    
    
    @objc func presentLocationInfutView(){

        whereToLabel.alpha = 0
        whereToLabelDot.alpha = 0
        configureLocationInputView()
    }
    
        func configureLocationInputView(){
            
    //        locationInputView.alpha = 0
            UIView.animate(withDuration: 0.5, animations: {
                self.locationInputView.alpha = 1
                self.actionButton.alpha = 1
            }) { _ in
                
                UIView.animate(withDuration: 0.3, animations: {
                    self.tableView.frame.origin.y = self.locationInputView.frame.height + 1
                })
            }
        }
    
    @IBAction func confirmUberXPressed(_ sender: Any) {
        switch buttonAction {
        
        case .requestRide:
            uploadTrip()
        case .cancel:
            cancelTrip()
        case .getDirections:
            print("DEBUG: Handle get direction..")
        case .pickup:
            pickupPassenger()
        case .dropOff:
            dropOffPassenger()
       
        }
    }
  
    
    @IBAction func actionButtonPressed(_ sender: Any) {
        
        switch actionButtonConfig {
        case .showMenu:
            delegate?.handleMenuToggle()
            print("debug: menuuuuu....")
            
        case .dissmissActionView:
            
            removeAnnotationAndOverlay()
            mapView.showAnnotations(mapView.annotations, animated: true)
            
            if user?.accountType == .passenger {
            UIView.animate(withDuration: 0.3, animations: {
                self.whereToLabel.alpha = 1
                self.whereToLabelDot.alpha = 1
                self.actionButton.alpha = 1

                self.configureActionButton(config: .showMenu)
                
                self.animateRideActionView(shouldShow: false)
             })
            }
            

        }
    }
 
    
    
    @IBAction func locationInputViewBack(_ sender: Any) {

        dissmissLocationView { _ in
            UIView.animate(withDuration: 0.5, animations: {
                self.whereToLabel.alpha = 1
                self.whereToLabelDot.alpha = 1
            })
        }
    }
    
    //MARK: - This will dismiss the view and after diss completion block will call.
    func dissmissLocationView(completion: ((Bool) -> Void)? = nil){
        UIView.animate(withDuration: 0.3, animations: {
            self.locationInputView.alpha = 0
            self.tableView.frame.origin.y = self.view.frame.height
        }, completion: completion)
    }
    
    func animateRideActionView(shouldShow : Bool, title: String? = nil, address: String? = nil, destination: MKPlacemark? = nil,config: RideActionViewConfiguration? = nil, user: User? = nil){
        let yOrigin = shouldShow ? self.view.frame.height - 300 : self.view.frame.height
        
        
        UIView.animate(withDuration: 0.3) {
            self.rideActionView.frame.origin.y = yOrigin
        }
        
        rideTitleLabel.text = title
        rideAddressLabel.text = address
        
        if shouldShow {
            guard let config = config else {return}
            
            if let user = user {
                rideActionUser = user
            }
            self.config = config
        }
        
    }
    
}

extension HomeController: MKMapViewDelegate {
    
    //MARK: - Creating custom circulur region with 100 redius
    
    func setCustomRegion(withType type: AnnotationType, coordinates: CLLocationCoordinate2D){
        let region = CLCircularRegion(center: coordinates, radius: 25, identifier: type.rawValue)
        locationManger?.startMonitoring(for: region)
        print("DEBUG: did set region\(region)")
    }
    
    //MARK: - Zoom only for driver and passenger.
    
    func zoomForActiveTrip(withDriverUid uid: String){
        var annotations = [MKAnnotation]()
        
        self.mapView.annotations.forEach { (annotation) in
            //separeting accepted driver annotation
            if let anno = annotation as? DriverAnnotation {
                if anno.uid == uid{
                    annotations.append(anno)
                }
            }
            
            if let userAnno = annotation as? MKUserLocation{
                annotations.append(userAnno)
            }
        }
        //separating passenger annotation.
        self.mapView.zoomToFit(annotations: annotations)
        
    }
    
    
    
    //MARK: - User location will update when its get changed.
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        guard let user = self.user else {return}
        guard user.accountType == .driver else {return}
        guard let location = userLocation.location else {return}
        DriverService.shared.updateDriverLocation(location: location)
    }
    
    //MARK: - View custom annotation.
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if let annotaion = annotation as? DriverAnnotation {
            let view = MKAnnotationView(annotation: annotation, reuseIdentifier: "DriverAnnotation")
            view.image = #imageLiteral(resourceName: "icons8-car-56")
            return view
            
        }
        return nil
    }
    
    //MARK: - Map Polyline (part: 2) polyline customization
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let route = self.route {
            let polyline = route.polyline
            let lineRenderer = MKPolylineRenderer(overlay: polyline)
            lineRenderer.strokeColor = .blue
            lineRenderer.lineWidth = 5
//            lineRenderer.alpha = 1
            return lineRenderer
        }
        return MKOverlayRenderer()
    }
    
    
       func removeAnnotationAndOverlay(){
           //MARK: - Remove annotation
           mapView.annotations.forEach { (annotation) in
                 if let anno = annotation as? MKPointAnnotation {
                     mapView.removeAnnotation(anno)
                 }
             }
           
           //MARK: - Remove Polyline
           if mapView.overlays.count > 0 {
               mapView.removeOverlay(mapView.overlays[0])
           }
       }

}

extension HomeController: CLLocationManagerDelegate {
    
    //MARK: - Tells the delegate that a new region is being monitored.
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {

        if region.identifier == AnnotationType.pickup.rawValue {
            print("debug: did start monitoring pick up region\(region)")
        }
        
        if region.identifier == AnnotationType.destination.rawValue {
            print("debug: did start monitoring destination region\(region)")
        }
        
    }
    
    //MARK: - Tells the delegate that the user entered the 25 redius region
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        
        guard let trip = self.trip else {return}
        
        if region.identifier == AnnotationType.pickup.rawValue {
            DriverService.shared.updateTripState(trip: trip, state: .driverArrived) { (error, ref) in
                self.config = .pickupPassenger
            }
        }
        
        if region.identifier == AnnotationType.destination.rawValue {
            print("debug: did start monitoring destination region\(region)")
            
            DriverService.shared.updateTripState(trip: trip, state: .arrivedAtDestination) { (error, ref) in
                self.config = .endTrip
            }
        }
    }
    
    
    //MARK: - Asking User for their Location
    
    func enableLocationServices(){
        locationManger?.delegate = self
        
        switch CLLocationManager.authorizationStatus() {
        
        case .notDetermined:
           print("DEBUG: not determined")
            
           locationManger?.requestWhenInUseAuthorization()
        case .restricted, .denied:
            break
        case .authorizedAlways:
            print("DEBUG: Auth Always")
            locationManger?.startUpdatingLocation()
            locationManger?.desiredAccuracy = kCLLocationAccuracyBest
        case .authorizedWhenInUse:
            print("DEBUG: Auth when in use")
            
            locationManger?.requestAlwaysAuthorization()
        @unknown default:
            break
        }
    }
    

    
    //MARK: - If user denie the request
    
 
}

extension HomeController : UITableViewDelegate, UITableViewDataSource {
    
 
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Saved Locations" : "Results"
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
        return section == 0 ? savedLocations.count  : searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationCell", for: indexPath) as! LocationCell
        
        if indexPath.section == 0 {
           cell.placemark = savedLocations[indexPath.row]
        }
        
        if indexPath.section == 1 {
            cell.placemark = searchResults[indexPath.row]
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let selectedPlacemark = indexPath.section == 0 ? savedLocations[indexPath.row] : searchResults[indexPath.row]
        selectedPlace = selectedPlacemark
        
        configureActionButton(config: .dissmissActionView)
        
        let destination = MKMapItem(placemark: selectedPlacemark)
        generatePolyline(toDestination: destination)
        
        //MARK: - this will first run dissmissLocationView function and the closure will execute.
        dissmissLocationView { _ in
            
            //MARK: - Add Annotation
//            let annotation = MKPointAnnotation()
//            annotation.coordinate = selectedPlacemark.coordinate
//            self.mapView.addAnnotation(annotation)
//            self.mapView.selectAnnotation(annotation, animated: true) //annotation animation
            self.mapView.addAnnotationAndSelect(forCoordinate: selectedPlacemark.coordinate)
            
            //MARK: - Zoom into selected location
            
            let annotations = self.mapView.annotations.filter({ !$0.isKind(of: DriverAnnotation.self )})
            
            //filtering through all the annotations in mapView except Driver annotation then Zoom into them.
            //there should be two annotations : user and selected location.
            
//            self.mapView.showAnnotations(annotations, animated: true)
            //instead
            self.zoomToFit(annotations: annotations)
            
            //for RideActionView
            let title = selectedPlacemark.name
            let address = selectedPlacemark.address
            
            self.animateRideActionView(shouldShow: true, title: title, address: address,config: .requestRide)
   
        }
    }
}

extension HomeController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let query = destinationTextField.text else { return false }
        
        searchBy(naturalLanguageQuery: query) { (results) in
            self.searchResults = results
            self.tableView.reloadData()
//            print("DEBUG: quesry \(results)")
        }
        
        return true
    }
    
    //MARK: - Escaping completion.
    
    func searchBy(naturalLanguageQuery : String, completion: @escaping ([MKPlacemark]) -> Void) {
        
        var results = [MKPlacemark]()
        
        //MARK: - Search nearby coffe shop/restuarent etc.. or local serach based on your local area.
        
        let request = MKLocalSearch.Request()
        request.region = mapView.region
        request.naturalLanguageQuery = naturalLanguageQuery
        
        let search = MKLocalSearch(request: request)
        search.start { (response, error) in
            
            guard let response = response else { return }
            
            response.mapItems.forEach { item in
                results.append(item.placemark)
            }
            
            completion(results)
        }
    }
    
    
    //MARK: - Map Polyline (part: 1)
    
    func generatePolyline(toDestination destination: MKMapItem){

        let request = MKDirections.Request()
        request.source = MKMapItem.forCurrentLocation()       //starting point
        request.destination = destination                    //destination point
//        request.requestsAlternateRoutes = true
        request.transportType = .automobile
        
        let directionRequest = MKDirections(request: request)

        directionRequest.calculate { (response, error) in
            
            
            guard let response = response else {return}
            
            self.route = response.routes[0]               //route array with start and end point
                        
            guard let polyline = self.self.route?.polyline else {return}
            self.mapView.addOverlay(polyline)
            
            
           }
    }
    
    //MARK: - Zoom in to specific annotations in mapView.
    
    func zoomToFit(annotations: [MKAnnotation]){
        var zoomRect = MKMapRect.null
        
        annotations.forEach { (annotation) in
            let annotationPoint = MKMapPoint(annotation.coordinate)
            let pointRect = MKMapRect(x: annotationPoint.x, y: annotationPoint.y, width: 0.01, height: 0.01)
            zoomRect = zoomRect.union(pointRect)
        }
        
        let insets = UIEdgeInsets(top: 120, left: 120, bottom: 280, right: 120)
        mapView.setVisibleMapRect(zoomRect,edgePadding: insets, animated: true)
        
    }
    //MARK: - Zoom out
    func centerMapOnUserLocation(){
        guard let coordinate = locationManger?.location?.coordinate else {return}
        let region = MKCoordinateRegion(center: coordinate,
                                        latitudinalMeters: 2000,
                                        longitudinalMeters: 2000)
        mapView.setRegion(region, animated: true)
    }
}

extension HomeController {
    
    func uploadTrip() {
        guard let pickupCoordinates = locationManger?.location?.coordinate else {return}
        guard let destinationCoordinates = selectedPlace?.coordinate else{return}
        
        shouldPresentLoadingView(true, message: "Finding your a ride..")
        
        PassengerService.shared.uploadTrip(pickupCoordinates, destinationCoordinates) { (error, ref) in
            if let error = error {
                print("DEBUG: uploadTrip error \(error)")
            }
            
            UIView.animate(withDuration: 0.3) {
                self.rideActionView.frame.origin.y = self.view.frame.height
            }
            
        }
    }
    
    
    func cancelTrip(){
        PassengerService.shared.deleteTrip { (error, ref) in
            if let error = error {
                return
            }
            
            self.centerMapOnUserLocation()
            self.animateRideActionView(shouldShow: false)
            self.removeAnnotationAndOverlay()
            
            self.actionButton.setImage(#imageLiteral(resourceName: "baseline_menu_black_36dp"), for: .normal)
            self.actionButtonConfig = .showMenu
            self.whereToLabel.alpha = 1
            self.whereToLabelDot.alpha = 1
        }
    }
    
    func pickupPassenger(){
        startTrip()
    }
    
    func dropOffPassenger(){
        guard let trip = trip else {return}
        
        DriverService.shared.updateTripState(trip: trip, state: .completed) { (err, ref) in
            self.removeAnnotationAndOverlay()
            self.centerMapOnUserLocation()
            self.animateRideActionView(shouldShow: false)
        }
    }
    
}

//MARK: - Protocol(4) (3 is on the same class)

extension HomeController: PickUpControllerDelegate {
    
    func didAcceptTrip(_ trip: Trip) {
        self.trip = trip
        
        
        self.mapView.addAnnotationAndSelect(forCoordinate: trip.pickupCoordinates)
        
        setCustomRegion(withType: .pickup, coordinates: trip.pickupCoordinates)
        
        let placemark = MKPlacemark(coordinate: trip.pickupCoordinates)
        let mapItem = MKMapItem(placemark: placemark)
        generatePolyline(toDestination: mapItem)
        
        mapView.zoomToFit(annotations: mapView.annotations)
        
        observeCancelTrip(trip: trip)
            
        self.dismiss(animated: true){
            //After dismiss it will show the confirmUberX view.
            Service.shared.fetchUserData(uid: trip.passengerUid) { (passenger) in
                self.animateRideActionView(shouldShow: true, config: .tripAccepted, user: passenger)
            }
        }
    }
    
    
    func configureUI(withConfig config: RideActionViewConfiguration){
        
        switch config {
            
        case .requestRide:
            
            buttonAction = .requestRide
            confirmUberXButton.setTitle(buttonAction.description, for: .normal)
            
        case .tripAccepted:
            
            guard let rideActionUser = rideActionUser else {return}
            if rideActionUser.accountType == .passenger {
                rideTitleLabel.text = "En Route To Passenger"
                buttonAction = .getDirections
                confirmUberXButton.setTitle(buttonAction.description, for: .normal)
            } else {
                buttonAction = .cancel
                confirmUberXButton.setTitle(buttonAction.description, for: .normal)
                rideTitleLabel.text = "Driver En Route"
            }
            xCircle.text = String(user?.fullName.first ?? "X")
            xLabel.text = user?.fullName
            
        case .driverArrived:
            guard let rideActionUser = rideActionUser else {return}
            
            if rideActionUser.accountType == .driver {
                rideTitleLabel.text = "Driver has arrived"
                rideAddressLabel.text = "Please meet driver at pickup location"
            }

            
        case .pickupPassenger:
            
            rideTitleLabel.text = "Arrived At Passenger Location"
            buttonAction = .pickup
            confirmUberXButton.setTitle(buttonAction.description, for: .normal)
            
        case .tripInProgress:
            
            guard let rideActionUser = rideActionUser else {return}
            
            if rideActionUser.accountType == .driver {
                confirmUberXButton.setTitle("TRIP IN PROGRESS", for: .normal)
                confirmUberXButton.isEnabled = false
            } else {
                buttonAction = .getDirections
                confirmUberXButton.setTitle(buttonAction.description, for: .normal)
            }
            rideTitleLabel.text = "EN Route To Destination"
            
        case .endTrip:
            
           guard let rideActionUser = rideActionUser else {return}
           
           if rideActionUser.accountType == .driver {
               confirmUberXButton.setTitle("ARRIVED AT DESTINATION", for: .normal)
               confirmUberXButton.isEnabled = false
           } else {
               buttonAction = .dropOff
               confirmUberXButton.setTitle(buttonAction.description, for: .normal)
           }
            
            rideTitleLabel.text = "Arrived at Destination"
        }
    }
}

