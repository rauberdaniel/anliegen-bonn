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
        setupView()
        
        mapView.delegate = self
        
        // Add Settings Button
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "⚙", style: UIBarButtonItemStyle.Plain, target: self, action: "showSettings:")
        
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
        
        streetLabel.text = "Lokalisiere…"
        userLocationButton.selected = true
        
        if location != nil {
            // location is already set
            customLocation = true
        } else {
            customLocation = false
        }
        startMonitoringLocation()
    }
    
    func setupView() {
        continueButton.layer.cornerRadius = 5
        continueButton.clipsToBounds = true
        continueButton.layer.borderWidth = 0.5
        continueButton.layer.borderColor = UIColor(white: 0.2, alpha: 0.4).CGColor
        
        streetView.layer.cornerRadius = continueButton.layer.cornerRadius
        streetView.clipsToBounds = true
        streetView.layer.borderWidth = continueButton.layer.borderWidth
        streetView.layer.borderColor = continueButton.layer.borderColor
    }
    
    func showSettings(sender: AnyObject) {
        self.performSegueWithIdentifier("showSettings", sender: self)
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
    
    func handleTap(sender: UIGestureRecognizer) {
        customLocation = true
        userLocationButton.selected = false
    }
    
    func updateLocationName() {
        if dragging > 0 {
            streetLabel.text = "Lokalisiere…"
        } else {
            println("Geocoder :: ReverseGeocodeLocation")
            geocoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
                if error != nil {
                    println("Geocoder :: Error :: \(error.localizedDescription)")
                    return
                }
                if (self.dragging > 0 || placemarks.count == 0) {
                    return
                }
                if let placemark = placemarks[0] as? CLPlacemark {
                    if placemark.thoroughfare == nil {
                        println("Geocoder :: ReturnedNil")
                        self.updateLocationName()
                        return
                    }
                    let street = AddressManager.sharedManager.getAddressStringFromPlacemark(placemark, includeLocality: false)
                    self.streetLabel.text = street
                }
            })
        }
    }
    
    // MARK: - GestureRecognizerDelegate
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    // MARK: - LocationManagerDelegate
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedWhenInUse || status == .AuthorizedAlways {
            // permission granted
        }
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        if let newLocation = locations[0] as? CLLocation {
            userLocation = newLocation
            
            if !customLocation {
                // following user location
                if location == nil || userLocation?.distanceFromLocation(location) > 5 {
                    // only update location if it has changed at least 5 meters
                    moveToLocation(newLocation)
                }
            }
        }
    }
    
    // MARK: - MapViewDelegate
    
    func mapView(mapView: MKMapView!, regionWillChangeAnimated animated: Bool) {
        dragging++
        updateLocationName()
        // lift the blob
        UIView.animateWithDuration(0.2, delay: 0, options: UIViewAnimationOptions.BeginFromCurrentState, animations: { () -> Void in
            self.locationMarker.transform = CGAffineTransformMakeScale(1.2, 1.2)
            }, completion: nil)
    }
    
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
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
        sender.selected = true
        customLocation = false
        location = userLocation
        if let location = location {
            moveToLocation(location)
        }
    }
    
    func startMonitoringLocation() {
        locationManager.desiredAccuracy = 10.0
        locationManager.startUpdatingLocation()
    }
    
    func moveToLocation(location: CLLocation) {
        let span = MKCoordinateSpanMake(0.007, 0.007)
        let region: MKCoordinateRegion = MKCoordinateRegionMake(location.coordinate, span)
        mapView.setRegion(region, animated: animateToNewLocation)
        animateToNewLocation = true
    }
    
    // MARK: - Seagues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "nextStep" {
            if location == nil {
                let alert = UIAlertController(title: "Kein Ort ausgewählt", message: "Bitte wähle den Ort deines Anliegens aus, um fortfahren zu können.", preferredStyle: UIAlertControllerStyle.Alert)
                let action = UIAlertAction(title: "Ok", style: .Cancel, handler: { (action) -> Void in
                    self.dismissViewControllerAnimated(true, completion: nil)
                })
                alert.addAction(action)
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
