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
import CoreGraphics

class AddViewController: UITableViewController, CLLocationManagerDelegate, MKMapViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var streetCell: UITableViewCell!
    @IBOutlet weak var serviceCell: UITableViewCell!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var photoButton: UIButton!
    @IBOutlet weak var photoCell: UITableViewCell!
    
    let locationManager = CLLocationManager()
    var location: CLLocation?
    var service: Service? {
        didSet {
            updateService()
        }
    }
    var image: UIImage?
    let customLocationAnnotation = MKPointAnnotation()
    var locationName: String?
    var placemark: CLPlacemark? {
        didSet {
            updateLocationName()
        }
    }
    
    // MARK: - Setup
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        //let cancelButton = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancel:")
        //self.navigationItem.leftBarButtonItem = cancelButton
        
        streetCell.textLabel?.text = locationName
        
        sendButton.addTarget(self, action: "sendConcern:", forControlEvents: .TouchUpInside)
        sendButton.enabled = false
        
        photoButton.addTarget(self, action: "capturePhoto:", forControlEvents: .TouchUpInside)
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        mapView.delegate = self
        updatePlacemark()
        updateMap()
    }
    
    override func viewWillAppear(animated: Bool) {
        updateMap()
        if let indexPath = tableView.indexPathForSelectedRow() {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
    }
    
    // MARK: - Submission
    
    func sendConcern(sender: AnyObject) {
        sendButton.enabled = false
        if let service: Service = service, location = location {
            let locationName = AddressManager.sharedManager.getAddressStringFromPlacemark(placemark, includeLocality: true)
            let concern = Concern(service: service, location: location, address: locationName, description: nil, image: image)
            
            ApiHandler.sharedHandler.submitConcern(concern, completionHandler: { (response, data, error) -> Void in
                if error != nil {
                    self.sendButton.enabled = true
                    let alert = UIAlertController(title: "Error", message: "Your concern could not be sent! Please enable network access to send your concern.", preferredStyle: .Alert)
                    let action = UIAlertAction(title: "Ok", style: .Cancel, handler: { (action) -> Void in
                        self.dismissViewControllerAnimated(true, completion: nil)
                    })
                    alert.addAction(action)
                    self.presentViewController(alert, animated: true, completion: nil)
                    return
                }
                let alert = UIAlertController(title: "Concern sent", message: "Your concern has been successfully transmitted", preferredStyle: UIAlertControllerStyle.Alert)
                let action = UIAlertAction(title: "Ok", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
                    self.dismissViewControllerAnimated(true, completion: nil)
                    self.navigationController?.popViewControllerAnimated(true)
                })
                alert.addAction(action)
                self.presentViewController(alert, animated: true, completion: nil)
            })
            
        } else {
            // no service specified
            let alert = UIAlertController(title: "No Service specified", message: "Please specify a service to submit your concern.", preferredStyle: UIAlertControllerStyle.Alert)
            let closeAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
                self.dismissViewControllerAnimated(true, completion: nil)
            })
            alert.addAction(closeAction)
        }
    }
    
    func cancel(sender: AnyObject) {
        self.parentViewController?.dismissViewControllerAnimated(true, completion: {})
    }
    
    // MARK: - Location Management
    
    func updateMap() {
        if let coord = location?.coordinate {
            let span = MKCoordinateSpanMake(0.004, 0.004)
            let region = MKCoordinateRegionMake(coord, span)
            if let mapView = mapView {
                mapView.setRegion(region, animated: false)
                mapView.addAnnotation(customLocationAnnotation)
            }
            customLocationAnnotation.coordinate = coord
        }
    }
    
    func updatePlacemark() {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
            if error == nil {
                if let placemark = placemarks[0] as? CLPlacemark {
                    self.placemark = placemark
                }
            }
        })
    }
    
    func updateLocationName() {
        let street = AddressManager.sharedManager.getAddressStringFromPlacemark(placemark, includeLocality: false)
        self.streetCell.textLabel?.text = street
        self.streetCell.setNeedsLayout()
    }
    
    // MARK: - Service Management
    
    func updateService() {
        if let service = service {
            serviceCell.detailTextLabel?.text = service.name
            sendButton.enabled = true
        } else {
            serviceCell.detailTextLabel?.text = "Unknown"
            sendButton.enabled = false
        }
    }
    
    // MARK: - Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "setService" {
            (segue.destinationViewController as! ConcernTypeViewController).addController = self
        }
    }
    
    // MARK: - Image Controller
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        if let image = info[NSString(string: "UIImagePickerControllerOriginalImage")] as? UIImage {
            photoButton.removeFromSuperview()
            let imageView = UIImageView(image: image)
            imageView.clipsToBounds = true
            imageView.contentMode = UIViewContentMode.ScaleAspectFit
            imageView.frame = CGRectMake(0, 0, photoCell.frame.width, photoCell.frame.height)
            photoCell.addSubview(imageView)
            //let cellHeight = photoCell.frame.width/image.size.width * image.size.height
            let smallImage = imageWithImage(image, scaledToMaxSize: CGSizeMake(2048, 2048))
            self.image = smallImage
        }
        self.dismissViewControllerAnimated(true, completion: {})
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
    
    func imageWithImage(image: UIImage, scaledToMaxSize maxSize: CGSize) -> UIImage {
        let targetAspectRatio = maxSize.height/maxSize.width
        let imageAspectRatio = image.size.height/image.size.width
        var width: CGFloat = maxSize.width
        var height: CGFloat = maxSize.height
        if imageAspectRatio > targetAspectRatio {
            // set height to 2048, width auto
            height = min(maxSize.height, image.size.height)
            width = height/image.size.height * image.size.width
        } else {
            // set width to 2048, height auto
            width = min(maxSize.width, image.size.width)
            height = width/image.size.width * image.size.height
        }
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), false, 1.0)
        image.drawInRect(CGRectMake(0, 0, width, height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    // MARK: - TableView
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
}