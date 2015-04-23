//
//  AddViewController.swift
//  cleanbn
//
//  Created by Daniel Rauber on 18.04.15.
//  Copyright (c) 2015 Daniel Rauber. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import MobileCoreServices

class AddViewController: UITableViewController, CLLocationManagerDelegate, MKMapViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var streetCell: UITableViewCell!
    @IBOutlet weak var serviceCell: UITableViewCell!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var photoButton: UIButton!
    
    let locationManager = CLLocationManager()
    var location: CLLocation? {
        didSet {
            locationUpdated()
        }
    }
    var service: Service? {
        didSet {
            updateService()
        }
    }
    var image: UIImage?
    var customLocationAnnotation: MKPointAnnotation?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancel:")
        self.navigationItem.leftBarButtonItem = cancelButton
        
        streetCell.textLabel?.text = ""
        
        sendButton.addTarget(self, action: "sendConcern:", forControlEvents: .TouchUpInside)
        sendButton.enabled = false
        
        photoButton.addTarget(self, action: "capturePhoto:", forControlEvents: .TouchUpInside)
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        mapView.delegate = self
        
        // add long press gesture to map
        let lpgr = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        lpgr.delegate = self
        mapView.addGestureRecognizer(lpgr)
        
        updateMap()
    }
    
    func handleLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state != UIGestureRecognizerState.Began {
            return
        }
        let coordinate = mapView.convertPoint(sender.locationInView(mapView), toCoordinateFromView: mapView)
        location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        if customLocationAnnotation == nil {
            customLocationAnnotation = MKPointAnnotation()
            customLocationAnnotation?.coordinate = coordinate
            mapView.addAnnotation(customLocationAnnotation)
        } else {
            customLocationAnnotation?.coordinate = coordinate
        }
    }
    
    func cancel(sender: AnyObject) {
        self.parentViewController?.dismissViewControllerAnimated(true, completion: {})
    }
    
    func sendConcern(sender: AnyObject) {
        sendButton.enabled = false
        if let service: Service = service, location = location {
            let concern = Concern()
            concern.service = service
            concern.location = location
            ApiHandler.sharedHandler.submitConcern(concern, completionHandler: { (response, data, error) -> Void in
                if error == nil {
                    self.parentViewController?.dismissViewControllerAnimated(true, completion: {})
                } else {
                    self.sendButton.enabled = true
                }
            })
        } else {
            // no service specified
            let alert = UIAlertView(title: "No Service specified", message: "Please specify a service to submit your concern.", delegate: nil, cancelButtonTitle: "Ok")
            alert.show()
        }
    }
    
    func capturePhoto(sender: AnyObject) {
        if UIImagePickerController.isSourceTypeAvailable(.Camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.mediaTypes = [kUTTypeImage]
            imagePicker.allowsEditing = false
            imagePicker.sourceType = .Camera
            
            self.presentViewController(imagePicker, animated: true, completion: {})
            
        }
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if customLocationAnnotation == nil {
            updateMap()
        }
    }
    
    func updateMap() {
        if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
            mapView.showsUserLocation = true
        }
    }
    
    func updateService() {
        if let service = service {
            serviceCell.detailTextLabel?.text = service.name
            sendButton.enabled = true
        } else {
            serviceCell.detailTextLabel?.text = "Unknown"
            sendButton.enabled = false
        }
    }
    
    func mapView(mapView: MKMapView!, didUpdateUserLocation userLocation: MKUserLocation!) {
        if customLocationAnnotation == nil {
            // if there is no custom location set, the new location is the user location
            location = userLocation.location
        }
    }
    
    func locationUpdated() {
        if let coord = location?.coordinate {
            let span = MKCoordinateSpanMake(0.005, 0.005)
            let region: MKCoordinateRegion = MKCoordinateRegionMake(coord, span)
            mapView.setRegion(region, animated: true)
            updateLocationName()
        }
    }
    
    func updateLocationName() {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
            if let placemark = placemarks[0] as? CLPlacemark {
                var street = "Unknown Street"
                if placemark.thoroughfare != nil {
                    street = "\(placemark.thoroughfare)"
                    
                    if placemark.subThoroughfare != nil {
                        street += " \(placemark.subThoroughfare)"
                    }
                }
                self.streetCell.textLabel?.text = street
            }
        })
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "setService" {
            (segue.destinationViewController as! ConcernTypeViewController).addController = self
        }
    }
    
    // MARK: - Image Controller
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        println("Got an Image: \(info)")
        if let image = info[NSString(string: "UIImagePickerControllerOriginalImage")] as? UIImage {
            // TODO: Resize Image
            // TODO: Display Image
            self.image = image
        }
        self.dismissViewControllerAnimated(true, completion: {})
    }
    
    // MARK: - TableView
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            tableView.deselectRowAtIndexPath(indexPath, animated: false)
        }
    }
    
}