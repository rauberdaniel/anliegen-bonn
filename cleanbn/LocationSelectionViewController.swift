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
        mapView.rotateEnabled = false
        
        // Add Settings Button
        let settingsIcon = UIImage(named: "SettingsIcon")
        let settingsButton = UIBarButtonItem(image: settingsIcon, style: .Plain, target: self, action: "showSettings:")
        self.navigationItem.leftBarButtonItem = settingsButton
        
        // Add Library Button
        let libraryButton = UIBarButtonItem(barButtonSystemItem: .Bookmarks, target: self, action: "showLibrary:")
        self.navigationItem.rightBarButtonItem = libraryButton
        
        // Add Gesture Recognizers
        let panRecognizer = UIPanGestureRecognizer(target: self, action: "handlePan:")
        panRecognizer.delegate = self
        panRecognizer.minimumNumberOfTouches = 1
        mapView.addGestureRecognizer(panRecognizer)
        
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: "handlePan:")
        pinchRecognizer.delegate = self
        mapView.addGestureRecognizer(pinchRecognizer)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: "handleTap:")
        mapView.addGestureRecognizer(tapRecognizer)
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        showRequestsOnMap()
        
        // Invalid Location Banner
        hideInvalidLocationBanner()
        
        // Disable UserLocation Button when UserLocation is denied
        userLocationButton.enabled = false
        if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
            // UserLocation is allowed
            userLocationButton.enabled = true
        }
        
        streetLabel.text = "general.locating".localized
        
        if location != nil {
            // location is already set
            customLocation = true
        } else {
            // set start location to Kennedybrücke
            customLocation = false
            
            // use UserLocation if available
            if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
                userLocationButton.selected = true
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
    
    override func viewDidAppear(animated: Bool) {
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
    
    func handleTap(sender: UIGestureRecognizer) {
        customLocation = true
        userLocationButton.selected = false
    }
    
    func handlePan(sender: UIGestureRecognizer) {
        customLocation = true
        userLocationButton.selected = false
        if sender.state == UIGestureRecognizerState.Began {
            //updateLocationName()
        }
        if sender.state == UIGestureRecognizerState.Ended {
            //updateLocationName()
        }
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    // MARK: - Navigation
    
    func showSettings(sender: AnyObject) {
        self.performSegueWithIdentifier("showSettings", sender: self)
    }
    
    func showLibrary(sender: AnyObject) {
        self.performSegueWithIdentifier("showLibrary", sender: self)
    }
    
    // MARK: - LocationManagerDelegate
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedWhenInUse || status == .AuthorizedAlways {
            // permission granted
            startMonitoringLocation()
            userLocationButton.enabled = true
        } else {
            userLocationButton.enabled = false
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations[0]
        userLocation = newLocation
        
        if !customLocation {
            // following user location
            if location == nil || userLocation?.distanceFromLocation(location!) > 5 {
                // only update location if it has changed at least 5 meters
                moveToLocation(newLocation)
            }
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("LocationManager :: DidFail")
        if error.code == CLError.Denied.rawValue {
            // Location Services are not allowed
            locationManager.stopUpdatingLocation()
            userLocationButton.enabled = false
            userLocationButton.selected = false
            print("LocationManager :: Denied")
        }
    }
    
    // MARK: - MapViewDelegate
    
    func mapView(mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        dragging++
        updateLocationName()
        // lift the blob
        UIView.animateWithDuration(0.2, delay: 0, options: UIViewAnimationOptions.BeginFromCurrentState, animations: { () -> Void in
            self.locationMarker.transform = CGAffineTransformMakeScale(1.2, 1.2)
            }, completion: nil)
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        dragging--
        let coord = mapView.convertPoint(CGPointMake(mapView.frame.width/2, mapView.frame.height/2+32), toCoordinateFromView: mapView)
        location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        // lower the blob
        UIView.animateWithDuration(0.2, delay: 0, options: UIViewAnimationOptions.BeginFromCurrentState, animations: { () -> Void in
            self.locationMarker.transform = CGAffineTransformIdentity
            }, completion: nil)
    }
    
    // MARK: - Map Controller
    
    @IBAction func locateUser(sender: UIButton) {
        if let userLocation = userLocation {
            sender.selected = true
            customLocation = false
            location = userLocation
            moveToLocation(userLocation)
        }
    }
    
    func startMonitoringLocation() {
        locationManager.desiredAccuracy = 10.0
        locationManager.startUpdatingLocation()
    }
    
    func moveToLocation(location: CLLocation) {
        let span = MKCoordinateSpanMake(0.0024, 0.0024)
        let region: MKCoordinateRegion = MKCoordinateRegionMake(location.coordinate, span)
        mapView.setRegion(region, animated: animateToNewLocation)
        animateToNewLocation = true
    }
    
    func concernStateOpen(concern: Concern) -> Bool {
        return concern.state == "open"
    }
    
    func showRequestsOnMap() {
        ApiHandler.sharedHandler.getConcerns { (concerns) -> Void in
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
        invalidLocationBanner.hidden = false
        self.view.layoutIfNeeded()
        
        self._invalidLoationBannerConstraint.constant = 0
        
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
    }
    
    func hideInvalidLocationBanner() {
        print("InvalidLocatioBanner :: hide")
        self.view.layoutIfNeeded()
        
        self._invalidLoationBannerConstraint.constant = -60
        
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            self.view.layoutIfNeeded()
        }) { (completion) -> Void in
            self.invalidLocationBanner.hidden = true
        }
    }
    
    // MARK: - Seagues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "nextStep" {
            if !ValidationHandler.isValidLocation(location) {
                let cancelAction = UIAlertAction(title: "general.cancel".localized, style: .Cancel, handler: nil)
                let alertTitle = "location.invalid.title".localized
                let alertText = "location.invalid.text".localized
                let alert = UIAlertController(title: alertTitle, message: alertText, preferredStyle: .Alert)
                alert.addAction(cancelAction)
                self.presentViewController(alert, animated: true, completion: nil)
                return
            }
            if let dest = segue.destinationViewController as? AddViewController {
                dest.location = location
                dest.locationName = streetLabel.text
            }
        }
    }
    
}
