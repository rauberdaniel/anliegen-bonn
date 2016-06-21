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
import Foundation

class AddViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UITextViewDelegate {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var serviceButton: UIButton!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var photoButton: UIButton!
    @IBOutlet weak var descriptionButton: UIButton!
    
    var viewCenter: CGPoint?
    let locationManager = CLLocationManager()
    var location: CLLocation?
    var service: Service? {
        didSet {
            updateService()
        }
    }
    var image: UIImage?
    var concernDescription: String?
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
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        self.view.addGestureRecognizer(tapRecognizer)
        
        /*
        let swipeRecognizer = UISwipeGestureRecognizer(target: self, action: "dismissKeyboard")
        swipeRecognizer.direction = .Down
        descriptionField.addGestureRecognizer(swipeRecognizer)
        descriptionField.delegate = self
        */
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AddViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AddViewController.keyboardDidHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
        
        locationButton.setTitle(locationName, forState: .Normal)
        
        sendButton.addTarget(self, action: #selector(AddViewController.sendConcern(_:)), forControlEvents: .TouchUpInside)
        
        let middleButtonsEdgeInset = UIEdgeInsetsMake(70, 0, 0, 0)
        photoButton.addTarget(self, action: #selector(AddViewController.attachPhoto(_:)), forControlEvents: .TouchUpInside)
        photoButton.titleEdgeInsets = middleButtonsEdgeInset
        serviceButton.titleLabel?.numberOfLines = 2
        serviceButton.titleLabel?.lineBreakMode = .ByWordWrapping
        serviceButton.titleEdgeInsets = middleButtonsEdgeInset
        locationButton.titleEdgeInsets = middleButtonsEdgeInset
        descriptionButton.titleEdgeInsets = middleButtonsEdgeInset
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        mapView.delegate = self
        updatePlacemark()
        updateMap()
    }
    
    override func viewWillAppear(animated: Bool) {
        updateMap()
    }
    
    // MARK: - Validation
    
    func showSettingsView() {
        self.performSegueWithIdentifier("showSettings", sender: self)
    }
    
    func checkSettings() -> Bool {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        if let mail = userDefaults.stringForKey("email") {
            if ValidationHandler.isValidEmail(mail) && userDefaults.boolForKey("termsAccepted") {
                return true
            }
        }
        return false
    }
    
    // MARK: - Submission
    
    func sendConcern(sender: AnyObject) {
        
        if let service: Service = service, location = location {
            if !checkSettings() {
                showSettingsView()
                return
            }
            let locationName = AddressManager.sharedManager.getAddressStringFromPlacemark(placemark, includeLocality: true)
            let concern = Concern(service: service, location: location, address: locationName, description: concernDescription, image: image)
            
            let confirmationAlert = UIAlertController(title: "submit.confirmation.title".localized, message: "submit.confirmation.text".localized, preferredStyle: .ActionSheet)
            let confirmationAction = UIAlertAction(title: "general.submit".localized, style: .Default, handler: { (action) -> Void in
                ApiHandler.sharedHandler.submitConcern(concern, sender: self)
            })
            let cancelAction = UIAlertAction(title: "general.cancel".localized, style: .Cancel, handler: { (action) -> Void in
                //self.sendButton.enabled = true
            })
            confirmationAlert.addAction(confirmationAction)
            confirmationAlert.addAction(cancelAction)
            presentViewController(confirmationAlert, animated: true, completion: nil)
        } else {
            // no service specified
            let missingCategoryAlert = UIAlertController(title: "service.notselected.title".localized, message: "service.notselected.text".localized, preferredStyle: .Alert)
            let closeAction = UIAlertAction(title: "general.ok".localized, style: .Cancel, handler: nil)
            missingCategoryAlert.addAction(closeAction)
            presentViewController(missingCategoryAlert, animated: true, completion: nil)
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
        if let location = location {
            geocoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
                if error == nil {
                    if let placemarks = placemarks {
                        self.placemark = placemarks[0]
                    }
                }
            })
        }
    }
    
    func updateLocationName() {
        let street = AddressManager.sharedManager.getAddressStringFromPlacemark(placemark, includeLocality: false)
        print("updateLocationName \(street)")
        self.locationButton.setTitle(street, forState: .Normal)
    }
    
    // MARK: - Service Management
    
    func updateService() {
        if let service = service {
            serviceButton.setTitle(service.name, forState: .Normal)
            //sendButton.enabled = true
        } else {
            serviceButton.setTitle("general.service".localized, forState: .Normal)
            //sendButton.enabled = false
        }
    }
    
    // MARK: - Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "setService" {
            (segue.destinationViewController as! ConcernTypeViewController).addController = self
        }
    }
    
    // MARK: - Image Controller
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let image = info[NSString(string: "UIImagePickerControllerOriginalImage") as String] as? UIImage {
            photoButton.setTitle("photo.replace".localized, forState: UIControlState.Normal)
            let smallImage = imageWithImage(image, scaledToMaxSize: CGSizeMake(2048, 2048))
            self.image = smallImage
        }
        self.dismissViewControllerAnimated(true, completion: {})
    }
    
    func attachPhoto(sender: AnyObject) {
        let alert = UIAlertController(title: "photo.source.title".localized, message: "photo.source.text".localized, preferredStyle: .ActionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.Camera) {
            let captureAction = UIAlertAction(title: "photo.source.camera".localized, style: .Default) { (action) -> Void in
                self.selectPhoto(.Camera)
            }
            alert.addAction(captureAction)
        }
        if UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary) {
            let selectAction = UIAlertAction(title: "photo.source.library".localized, style: .Default) { (action) -> Void in
                self.selectPhoto(.PhotoLibrary)
            }
            alert.addAction(selectAction)
        }
        let cancelAction = UIAlertAction(title: "general.cancel".localized, style: .Cancel, handler: nil)
        alert.addAction(cancelAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func selectPhoto(sourceType: UIImagePickerControllerSourceType) {
        if UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.mediaTypes = [kUTTypeImage as String]
            imagePicker.allowsEditing = false
            imagePicker.sourceType = sourceType
            
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
    
    // MARK: - Keyboard Handling
    
    /*
    func dismissKeyboard() {
        descriptionField.resignFirstResponder()
    }
    */
    
    func keyboardWillShow(notification: NSNotification) {
        if let userInfo = notification.userInfo as? Dictionary<NSString, AnyObject>, keyboardRect = userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            if viewCenter == nil {
                viewCenter = view.center
            }
            if let viewCenter = viewCenter {
                view.center = CGPointMake(view.center.x, viewCenter.y - keyboardRect.CGRectValue().height)
            }
        }
    }
    
    func keyboardDidHide(notification: NSNotification) {
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            if let viewCenter = self.viewCenter {
                self.view.center = viewCenter
            }
        })
    }
    
}