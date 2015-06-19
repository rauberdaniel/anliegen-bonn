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
    @IBOutlet weak var serviceButton: UIButton!
    @IBOutlet weak var streetLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var photoButton: UIButton!
    @IBOutlet weak var descriptionField: UITextView!
    
    var viewCenter: CGPoint?
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
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        self.view.addGestureRecognizer(tapRecognizer)
        
        let swipeRecognizer = UISwipeGestureRecognizer(target: self, action: "dismissKeyboard")
        swipeRecognizer.direction = .Down
        descriptionField.addGestureRecognizer(swipeRecognizer)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardDidHide:", name: UIKeyboardWillHideNotification, object: nil)
        
        streetLabel.text = locationName
        
        sendButton.addTarget(self, action: "sendConcern:", forControlEvents: .TouchUpInside)
        
        descriptionField.delegate = self
        
        let middleButtonsEdgeInset = UIEdgeInsetsMake(70, 0, 0, 0)
        photoButton.addTarget(self, action: "attachPhoto:", forControlEvents: .TouchUpInside)
        photoButton.titleEdgeInsets = middleButtonsEdgeInset
        serviceButton.titleLabel?.numberOfLines = 2
        serviceButton.titleLabel?.lineBreakMode = .ByWordWrapping
        serviceButton.titleEdgeInsets = middleButtonsEdgeInset
        
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
            let concern = Concern(service: service, location: location, address: locationName, description: descriptionField.text, image: image)
            
            let confirmationAlert = UIAlertController(title: NSLocalizedString("submit.confirmation.title", comment: ""), message: NSLocalizedString("submit.confirmation.text", comment: ""), preferredStyle: .ActionSheet)
            let confirmationAction = UIAlertAction(title: NSLocalizedString("general.submit", comment: ""), style: .Default, handler: { (action) -> Void in
                ApiHandler.sharedHandler.submitConcern(concern, sender: self)
            })
            let cancelAction = UIAlertAction(title: NSLocalizedString("general.cancel", comment: ""), style: .Cancel, handler: { (action) -> Void in
                //self.sendButton.enabled = true
            })
            confirmationAlert.addAction(confirmationAction)
            confirmationAlert.addAction(cancelAction)
            presentViewController(confirmationAlert, animated: true, completion: nil)
        } else {
            // no service specified
            let missingCategoryAlert = UIAlertController(title: NSLocalizedString("service.notselected.title", comment: ""), message: NSLocalizedString("service.notselected.text", comment: ""), preferredStyle: .Alert)
            let closeAction = UIAlertAction(title: NSLocalizedString("general.ok", comment: ""), style: .Cancel, handler: nil)
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
        self.streetLabel.text = street
    }
    
    // MARK: - Service Management
    
    func updateService() {
        if let service = service {
            serviceButton.setTitle(service.name, forState: .Normal)
            //sendButton.enabled = true
        } else {
            serviceButton.setTitle(NSLocalizedString("general.service", comment: ""), forState: .Normal)
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
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        if let image = info[NSString(string: "UIImagePickerControllerOriginalImage")] as? UIImage {
            photoButton.setTitle(NSLocalizedString("photo.replace", comment: ""), forState: UIControlState.Normal)
            let smallImage = imageWithImage(image, scaledToMaxSize: CGSizeMake(2048, 2048))
            self.image = smallImage
        }
        self.dismissViewControllerAnimated(true, completion: {})
    }
    
    func attachPhoto(sender: AnyObject) {
        let alert = UIAlertController(title: NSLocalizedString("photo.source.title", comment: ""), message: NSLocalizedString("photo.source.text", comment: ""), preferredStyle: .ActionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.Camera) {
            let captureAction = UIAlertAction(title: NSLocalizedString("photo.source.camera", comment: ""), style: .Default) { (action) -> Void in
                self.selectPhoto(.Camera)
            }
            alert.addAction(captureAction)
        }
        if UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary) {
            let selectAction = UIAlertAction(title: NSLocalizedString("photo.source.library", comment: ""), style: .Default) { (action) -> Void in
                self.selectPhoto(.PhotoLibrary)
            }
            alert.addAction(selectAction)
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("general.cancel", comment: ""), style: .Cancel, handler: nil)
        alert.addAction(cancelAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func selectPhoto(sourceType: UIImagePickerControllerSourceType) {
        if UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.mediaTypes = [kUTTypeImage]
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
    
    func dismissKeyboard() {
        descriptionField.resignFirstResponder()
    }
    
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