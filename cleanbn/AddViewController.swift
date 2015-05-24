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

class AddViewController: UITableViewController, CLLocationManagerDelegate, MKMapViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UITextViewDelegate {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var streetCell: UITableViewCell!
    @IBOutlet weak var serviceCell: UITableViewCell!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var photoButton: UIButton!
    @IBOutlet weak var photoCell: UITableViewCell!
    @IBOutlet weak var descriptionField: UITextView!
    
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
        tableView.keyboardDismissMode = UIScrollViewKeyboardDismissMode.OnDrag
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardDidHide:", name: UIKeyboardDidHideNotification, object: nil)
        
        streetCell.textLabel?.text = locationName
        
        sendButton.addTarget(self, action: "sendConcern:", forControlEvents: .TouchUpInside)
        sendButton.enabled = false
        
        descriptionField.delegate = self
        
        photoButton.addTarget(self, action: "attachPhoto:", forControlEvents: .TouchUpInside)
        
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
    
    // MARK: - Validation
    
    func showSettingsView() {
        self.performSegueWithIdentifier("showSettings", sender: self)
    }
    
    func checkSettings() -> Bool {
        if let mail = NSUserDefaults.standardUserDefaults().objectForKey("email") as? String {
            if ValidationHandler.isValidEmail(mail) {
                return true
            }
        }
        return false
    }
    
    // MARK: - Submission
    
    func sendConcern(sender: AnyObject) {
        sendButton.enabled = false
        
        if !checkSettings() {
            showSettingsView()
            sendButton.enabled = true
            return
        }
        
        if let service: Service = service, location = location {
            let locationName = AddressManager.sharedManager.getAddressStringFromPlacemark(placemark, includeLocality: true)
            let concern = Concern(service: service, location: location, address: locationName, description: descriptionField.text, image: image)
            
            let confirmationAlert = UIAlertController(title: "Anliegen senden?", message: "Möchtest du dein Anliegen übermitteln? Die angegebenen Daten werden somit öffentlich.", preferredStyle: .ActionSheet)
            let confirmationAction = UIAlertAction(title: "Senden", style: .Default, handler: { (action) -> Void in
                ApiHandler.sharedHandler.submitConcern(concern, sender: self)
            })
            let cancelAction = UIAlertAction(title: "Abbrechen", style: .Cancel, handler: { (action) -> Void in
                self.sendButton.enabled = true
            })
            confirmationAlert.addAction(confirmationAction)
            confirmationAlert.addAction(cancelAction)
            presentViewController(confirmationAlert, animated: true, completion: nil)
        } else {
            // no service specified
            // should not happen as sendButton would be disabled
            let missingCategoryAlert = UIAlertController(title: "Keine Kategorie ausgewählt", message: "Bitte wähle eine Kategorie aus, um dein Anliegen einzureichen.", preferredStyle: .Alert)
            let closeAction = UIAlertAction(title: "Ok", style: .Cancel, handler: nil)
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
            photoButton.setTitle("1 Foto ausgewählt", forState: UIControlState.Normal)
            let smallImage = imageWithImage(image, scaledToMaxSize: CGSizeMake(2048, 2048))
            self.image = smallImage
        }
        self.dismissViewControllerAnimated(true, completion: {})
    }
    
    func attachPhoto(sender: AnyObject) {
        let alert = UIAlertController(title: "Foto auswählen", message: "Aus welcher Quelle möchtest du ein Foto hinzufügen?", preferredStyle: UIAlertControllerStyle.ActionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.Camera) {
            let captureAction = UIAlertAction(title: "Kamera", style: .Default) { (action) -> Void in
                self.selectPhoto(.Camera)
            }
            alert.addAction(captureAction)
        }
        if UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary) {
            let selectAction = UIAlertAction(title: "Bibliothek", style: .Default) { (action) -> Void in
                self.selectPhoto(.PhotoLibrary)
            }
            alert.addAction(selectAction)
        }
        let cancelAction = UIAlertAction(title: "Abbrechen", style: .Cancel, handler: nil)
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
    
    // MARK: - TableView
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    // MARK: - Keyboard Handling
    
    func keyboardWillShow(notification: NSNotification) {
        if let userInfo = notification.userInfo as? Dictionary<NSString, AnyObject>, keyboardRect = userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            tableView.contentInset.bottom =  keyboardRect.CGRectValue().height
            if let cell = descriptionField.superview?.superview as? UITableViewCell, indexPath = tableView.indexPathForCell(cell) {
                tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Top, animated: true)
            }
        }
    }
    
    func keyboardDidHide(notification: NSNotification) {
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            self.tableView.contentInset.bottom = 0
        })
    }
    
    
}