//
//  LocationSelectionViewController.swift
//  cleanbn
//
//  Created by Daniel Rauber on 23.04.15.
//  Copyright (c) 2015 Daniel Rauber. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class LocationSelectionViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UIGestureRecognizerDelegate {
    @IBOutlet weak var _invalidLoationBannerConstraint: NSLayoutConstraint!
    @IBOutlet weak var invalidLocationBanner: UIVisualEffectView!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var locationMarker: UIImageView!
    @IBOutlet weak var userLocationButton: UIButton!
    @IBOutlet weak var streetLabel: UILabel!
    @IBOutlet weak var streetView: UIVisualEffectView!
    
    let locationManager = CLLocationManager()
    let geocoder = CLGeocoder()
    var customLocation = false
    var location: CLLocation? {
        didSet {
            updateLocationName()
        }
    }
    var userLocation: CLLocation?
    var dragging = 0
    var animateToNewLocation: Bool = false // initially false, true after first location
    
    override func viewDidLoad() {
        mapView.delegate = self
        mapView.isRotateEnabled = false
        
        // Add Settings Button
        let settingsIcon = UIImage(named: "SettingsIcon")
        let settingsButton = UIBarButtonItem(image: settingsIcon, style: .plain, target: self, action: #selector(LocationSelectionViewController.showSettings(_:)))
        self.navigationItem.leftBarButtonItem = settingsButton
        
        // Add Library Button
        let libraryButton = UIBarButtonItem(barButtonSystemItem: .bookmarks, target: self, action: #selector(LocationSelectionViewController.showLibrary(_:)))
        self.navigationItem.rightBarButtonItem = libraryButton
        
        // Add Gesture Recognizers
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(LocationSelectionViewController.handlePan(_:)))
        panRecognizer.delegate = self
        panRecognizer.minimumNumberOfTouches = 1
        mapView.addGestureRecognizer(panRecognizer)
        
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(LocationSelectionViewController.handlePan(_:)))
        pinchRecognizer.delegate = self
        mapView.addGestureRecognizer(pinchRecognizer)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(LocationSelectionViewController.handleTap(_:)))
        mapView.addGestureRecognizer(tapRecognizer)
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        showRequestsOnMap()
        
        // Invalid Location Banner
        hideInvalidLocationBanner()
        
        // Disable UserLocation Button when UserLocation is denied
        userLocationButton.isEnabled = false
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            // UserLocation is allowed
            userLocationButton.isEnabled = true
        }
        
        streetLabel.text = "general.locating".localized
        
        if location != nil {
            // location is already set
            customLocation = true
        } else {
            // set start location to Kennedybrücke
            customLocation = false
            
            // use UserLocation if available
            if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
                userLocationButton.isSelected = true
                startMonitoringLocation()
            } else {
                // Reverse Geocode start location
                let startCenter = CLLocation(latitude: 50.7387291883506, longitude: 7.11030880026633)
                let span = MKCoordinateSpanMake(0.0096, 0.0096)
                let region: MKCoordinateRegion = MKCoordinateRegionMake(startCenter.coordinate, span)
                mapView.setRegion(region, animated: animateToNewLocation)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //_invalidLoationBannerConstraint.constant = 20
    }
    
    func updateLocationName() {
        if dragging > 0 {
            streetLabel.text = "general.locating".localized
        } else {
            if !ValidationHandler.isValidLocation(location) {
                print("Geocoder :: Invalid Location")
                showInvalidLocationBanner()
            } else {
                hideInvalidLocationBanner()
            }
            print("Geocoder :: ReverseGeocodeLocation")
            
            
            geocoder.reverseGeocodeLocation(location!, completionHandler: { (placemarks, error) -> Void in
                if let error = error {
                    print("Geocoder :: Error :: \(error.localizedDescription)")
                    return
                }
                if (self.dragging > 0) {
                    return
                }
                if let placemarks = placemarks {
                    if (placemarks.count == 0) {
                        return
                    }
                    if placemarks[0].thoroughfare == nil {
                        print("Geocoder :: ReturnedNil")
                        self.streetLabel.text = "location.unknown.title".localized
                        //self.updateLocationName()
                        return
                    }
                    let street = AddressManager.sharedManager.getAddressStringFromPlacemark(placemarks[0], includeLocality: false)
                    print("Geocoder :: Returned :: \(street)")
                    self.streetLabel.text = street
                }
            })
        }
    }
    
    // MARK: - Gesture Handling
    
    @objc func handleTap(_ sender: UIGestureRecognizer) {
        customLocation = true
        userLocationButton.isSelected = false
    }
    
    @objc func handlePan(_ sender: UIGestureRecognizer) {
        customLocation = true
        userLocationButton.isSelected = false
        if sender.state == UIGestureRecognizerState.began {
            //updateLocationName()
        }
        if sender.state == UIGestureRecognizerState.ended {
            //updateLocationName()
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    // MARK: - Navigation
    
    @objc func showSettings(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "showSettings", sender: self)
    }
    
    @objc func showLibrary(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "showLibrary", sender: self)
    }
    
    // MARK: - LocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            // permission granted
            startMonitoringLocation()
            userLocationButton.isEnabled = true
        } else {
            userLocationButton.isEnabled = false
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations[0]
        userLocation = newLocation
        
        if !customLocation {
            // following user location
            if location == nil || userLocation?.distance(from: location!) > 5 {
                // only update location if it has changed at least 5 meters
                moveToLocation(newLocation)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager :: DidFail")
        print("\(error)")
        /*
        if error.code == CLError.Code.denied.rawValue {
            // Location Services are not allowed
            locationManager.stopUpdatingLocation()
            userLocationButton.isEnabled = false
            userLocationButton.isSelected = false
            print("LocationManager :: Denied")
        }
 */
    }
    
    // MARK: - MapViewDelegate
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        dragging += 1
        updateLocationName()
        // lift the blob
        UIView.animate(withDuration: 0.2, delay: 0, options: UIViewAnimationOptions.beginFromCurrentState, animations: { () -> Void in
            self.locationMarker.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            }, completion: nil)
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        dragging -= 1
        let coord = mapView.convert(CGPoint(x: mapView.frame.width/2, y: mapView.frame.height/2+32), toCoordinateFrom: mapView)
        location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        // lower the blob
        UIView.animate(withDuration: 0.2, delay: 0, options: UIViewAnimationOptions.beginFromCurrentState, animations: { () -> Void in
            self.locationMarker.transform = CGAffineTransform.identity
            }, completion: nil)
    }
    
    // MARK: - Map Controller
    
    @IBAction func locateUser(_ sender: UIButton) {
        if let userLocation = userLocation {
            sender.isSelected = true
            customLocation = false
            location = userLocation
            moveToLocation(userLocation)
        }
    }
    
    func startMonitoringLocation() {
        locationManager.desiredAccuracy = 10.0
        locationManager.startUpdatingLocation()
    }
    
    func moveToLocation(_ location: CLLocation) {
        let span = MKCoordinateSpanMake(0.0024, 0.0024)
        let region: MKCoordinateRegion = MKCoordinateRegionMake(location.coordinate, span)
        mapView.setRegion(region, animated: animateToNewLocation)
        animateToNewLocation = true
    }
    
    func concernStateOpen(_ concern: Concern) -> Bool {
        return concern.state == "open"
    }
    
    func showRequestsOnMap() {
        ApiHandler.sharedHandler.getConcerns { (concerns, error) -> Void in
            for concern in concerns.filter(self.concernStateOpen) {
                if let coordinate = concern.location?.coordinate {
                    let pin = MKPointAnnotation()
                    pin.coordinate = coordinate
                    pin.title = concern.service.name
                    pin.subtitle = concern.desc
                    self.mapView.addAnnotation(pin)
                }
            }
        }
    }
    
    // MARK: - Banner
    
    func showInvalidLocationBanner() {
        print("InvalidLocatioBanner :: show")
        invalidLocationBanner.isHidden = false
        self.view.layoutIfNeeded()
        
        self._invalidLoationBannerConstraint.constant = 0
        
        UIView.animate(withDuration: 0.2, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
    }
    
    func hideInvalidLocationBanner() {
        print("InvalidLocatioBanner :: hide")
        self.view.layoutIfNeeded()
        
        self._invalidLoationBannerConstraint.constant = -60
        
        UIView.animate(withDuration: 0.2, animations: { () -> Void in
            self.view.layoutIfNeeded()
        }, completion: { (completion) -> Void in
            self.invalidLocationBanner.isHidden = true
        }) 
    }
    
    // MARK: - Seagues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "nextStep" {
            if !ValidationHandler.isValidLocation(location) {
                let cancelAction = UIAlertAction(title: "general.cancel".localized, style: .cancel, handler: nil)
                let alertTitle = "location.invalid.title".localized
                let alertText = "location.invalid.text".localized
                let alert = UIAlertController(title: alertTitle, message: alertText, preferredStyle: .alert)
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                return
            }
            if let dest = segue.destination as? AddViewController {
                dest.location = location
                dest.locationName = streetLabel.text
            }
        }
    }
    
}
