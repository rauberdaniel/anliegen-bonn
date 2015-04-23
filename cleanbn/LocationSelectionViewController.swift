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

class LocationSelectionViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var locationMarker: UIImageView!
    
    let locationManager = CLLocationManager()
    var customLocation = false
    var location: CLLocation?
    
    override func viewDidLoad() {
        setupView()
        
        mapView.delegate = self
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }
    
    override func viewDidAppear(animated: Bool) {
        determineLocation()
    }
    
    func setupView() {
        continueButton.layer.cornerRadius = 6
        continueButton.clipsToBounds = true
        continueButton.layer.shadowColor = UIColor.blackColor().CGColor
        continueButton.layer.shadowOpacity = 0.3
        continueButton.layer.shadowRadius = 4.0
        continueButton.layer.shadowOffset = CGSizeMake(0, 1)
        continueButton.layer.masksToBounds = false
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
        
        let coord = mapView.convertPoint(CGPointMake(mapView.frame.width/2, mapView.frame.height/2), toCoordinateFromView: mapView)
        location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        
    }
    
    // MARK: - Map Controller
    
    func determineLocation() {
        locationManager.desiredAccuracy = 10.0
        locationManager.startUpdatingLocation()
    }
    
    func locationUpdatedAutomatically() {
        if let coordinate = location?.coordinate {
            let span = MKCoordinateSpanMake(0.007, 0.007)
            let region: MKCoordinateRegion = MKCoordinateRegionMake(coordinate, span)
            mapView.setRegion(region, animated: true)
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
