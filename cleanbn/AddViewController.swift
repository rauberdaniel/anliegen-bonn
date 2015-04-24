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
        updateLocationName()
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
            let concern = Concern()
            concern.service = service
            concern.location = location
            concern.locationName = locationName
            concern.image = image
            ApiHandler.sharedHandler.submitConcern(concern, completionHandler: { (response, data, error) -> Void in
                let res = NSString(data: data, encoding: NSUTF8StringEncoding)
                if error == nil {
                    //self.parentViewController?.dismissViewControllerAnimated(true, completion: {})
                    let alert = UIAlertController(title: "Concern sent", message: "Your concern has been successfully transmitted", preferredStyle: UIAlertControllerStyle.Alert)
                    let action = UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                        self.dismissViewControllerAnimated(true, completion: nil)
                        self.navigationController?.popViewControllerAnimated(true)
                    })
                    alert.addAction(action)
                    self.presentViewController(alert, animated: true, completion: nil)
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
    
    func cancel(sender: AnyObject) {
        self.parentViewController?.dismissViewControllerAnimated(true, completion: {})
    }
    
    func imageWithImage(image: UIImage, scaledToWidth width: CGFloat) -> UIImage {
        let aspectRatio = image.size.height/image.size.width
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, width*aspectRatio), false, 1.0)
        image.drawInRect(CGRectMake(0, 0, width, width*aspectRatio))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
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
    
    func updateService() {
        if let service = service {
            serviceCell.detailTextLabel?.text = service.name
            sendButton.enabled = true
        } else {
            serviceCell.detailTextLabel?.text = "Unknown"
            sendButton.enabled = false
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
                self.streetCell.setNeedsLayout()
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
        if let image = info[NSString(string: "UIImagePickerControllerOriginalImage")] as? UIImage {
            // TODO: Resize Image
            // TODO: Display Image
            photoButton.removeFromSuperview()
            let imageView = UIImageView(image: image)
            imageView.clipsToBounds = true
            imageView.contentMode = UIViewContentMode.ScaleAspectFit
            imageView.frame = CGRectMake(0, 0, photoCell.frame.width, photoCell.frame.height)
            photoCell.addSubview(imageView)
            //let cellHeight = photoCell.frame.width/image.size.width * image.size.height
            let smallImage = imageWithImage(image, scaledToWidth: 600)
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
    
    // MARK: - TableView
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    // MARK: - AlertView

}