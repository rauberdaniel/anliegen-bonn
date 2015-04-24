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
    @IBOutlet weak var streetView: UIView!
    
    let locationManager = CLLocationManager()
    var customLocation = false
    var location: CLLocation? {
        didSet {
            updateLocationName()
        }
    }
    var dragging: Bool = false
    var animateAutoLocation: Bool = false
    
    override func viewDidLoad() {
        setupView()
        
        mapView.delegate = self
        
        let panRecognizer = UIPanGestureRecognizer(target: self, action: "didPan:")
        panRecognizer.delegate = self
        panRecognizer.minimumNumberOfTouches = 1
        mapView.addGestureRecognizer(panRecognizer)
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }
    
    override func viewDidAppear(animated: Bool) {
        if location == nil {
            determineLocation()
        }
    }
    
    func setupView() {
        continueButton.layer.cornerRadius = 6
        continueButton.clipsToBounds = true
        continueButton.layer.borderWidth = 0.5
        continueButton.layer.borderColor = UIColor(white: 0.8, alpha: 1).CGColor
        
        streetView.layer.cornerRadius = continueButton.layer.cornerRadius
        streetView.clipsToBounds = true
        streetView.layer.borderWidth = continueButton.layer.borderWidth
        streetView.layer.borderColor = continueButton.layer.borderColor
    }
    
    func didPan(sender: UIPanGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.Began {
            dragging = true
            updateLocationName()
        }
        if sender.state == UIGestureRecognizerState.Ended {
            dragging = false
            let coord = mapView.convertPoint(CGPointMake(mapView.frame.width/2, mapView.frame.height/2), toCoordinateFromView: mapView)
            location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        }
    }
    
    func updateLocationName() {
        if dragging {
            streetLabel.text = "Searching…"
        } else {
            streetLabel.text = "Searching…"
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
                if error != nil {
                    return
                }
                if let placemark = placemarks[0] as? CLPlacemark {
                    var street = "Unknown Street"
                    if placemark.thoroughfare != nil {
                        street = "\(placemark.thoroughfare)"
                        
                        if placemark.subThoroughfare != nil {
                            street += " \(placemark.subThoroughfare)"
                        }
                    }
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
        if !customLocation {
            if let newLocation = locations[0] as? CLLocation {
                location = newLocation
                locationUpdatedAutomatically()
                manager.stopUpdatingLocation()
            }
        }
    }
    
    // MARK: - MapViewDelegate
    
    func mapView(mapView: MKMapView!, regionWillChangeAnimated animated: Bool) {
        UIView.animateWithDuration(0.2, delay: 0, options: UIViewAnimationOptions.BeginFromCurrentState, animations: { () -> Void in
            self.locationMarker.transform = CGAffineTransformMakeScale(1.2, 1.2)
        }, completion: nil)
    }
    
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        UIView.animateWithDuration(0.2, delay: 0, options: UIViewAnimationOptions.BeginFromCurrentState, animations: { () -> Void in
            self.locationMarker.transform = CGAffineTransformIdentity
        }, completion: nil)
    }
    
    // MARK: - Map Controller
    

    @IBAction func locateUser(sender: UIButton) {
        animateAutoLocation = true
        determineLocation()
    }
    
    func determineLocation() {
        locationManager.desiredAccuracy = 10.0
        locationManager.startUpdatingLocation()
    }
    
    func locationUpdatedAutomatically() {
        if let coordinate = location?.coordinate {
            let span = MKCoordinateSpanMake(0.007, 0.007)
            let region: MKCoordinateRegion = MKCoordinateRegionMake(coordinate, span)
            mapView.setRegion(region, animated: animateAutoLocation)
            mapView.setCenterCoordinate(coordinate, animated: animateAutoLocation)
            animateAutoLocation = false
        }
    }
    
    // MARK: - Seagues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "nextStep" {
            if let dest = segue.destinationViewController as? AddViewController {
                dest.location = location
            }
        }
    }
    
}
