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
    
    @IBAction func descriptionTab(_ sender: Any) {
        let alertController = UIAlertController(title: "concern.description".localized, message: "concern.description.message".localized, preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "general.ok".localized, style: .default) { (_) in
            self.concernDescription = alertController.textFields?[0].text
        }
        
        alertController.addTextField { (textfield) in
            textfield.placeholder = "concern.description".localized
            textfield.text = self.concernDescription
        }
        
        alertController.addAction(confirmAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
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
        
        // TODO comment this back in
        //NotificationCenter.default.addObserver(self, selector: #selector(AddViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AddViewController.keyboardDidHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        locationButton.setTitle(locationName, for: UIControlState())
        
        sendButton.addTarget(self, action: #selector(AddViewController.sendConcern(_:)), for: .touchUpInside)
        
        let middleButtonsEdgeInset = UIEdgeInsetsMake(70, 0, 0, 0)
        photoButton.addTarget(self, action: #selector(AddViewController.attachPhoto(_:)), for: .touchUpInside)
        photoButton.titleEdgeInsets = middleButtonsEdgeInset
        serviceButton.titleLabel?.numberOfLines = 2
        serviceButton.titleLabel?.lineBreakMode = .byWordWrapping
        serviceButton.titleEdgeInsets = middleButtonsEdgeInset
        locationButton.titleEdgeInsets = middleButtonsEdgeInset
        descriptionButton.titleEdgeInsets = middleButtonsEdgeInset
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        mapView.delegate = self
        updatePlacemark()
        updateMap()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        updateMap()
    }
    
    // MARK: - Validation
    
    func showSettingsView() {
        self.performSegue(withIdentifier: "showSettings", sender: self)
    }
    
    func checkSettings() -> Bool {
        let userDefaults = UserDefaults.standard
        if let mail = userDefaults.string(forKey: "email") {
            if ValidationHandler.isValidEmail(mail) && userDefaults.bool(forKey: "termsAccepted") {
                return true
            }
        }
        return false
    }
    
    // MARK: - Submission
    
    @objc func sendConcern(_ sender: AnyObject) {
        
        if let service: Service = service, let location = location {
            if !checkSettings() {
                showSettingsView()
                return
            }
            let locationName = AddressManager.sharedManager.getAddressStringFromPlacemark(placemark, includeLocality: true)
            let concern = Concern(service: service, location: location, address: locationName, description: concernDescription, image: image)
            
            let confirmationAlert = UIAlertController(title: "submit.confirmation.title".localized, message: "submit.confirmation.text".localized, preferredStyle: .actionSheet)
            let confirmationAction = UIAlertAction(title: "general.submit".localized, style: .default, handler: { (action) -> Void in
                ApiHandler.sharedHandler.submitConcern(concern, sender: self)
            })
            let cancelAction = UIAlertAction(title: "general.cancel".localized, style: .cancel, handler: { (action) -> Void in
                //self.sendButton.enabled = true
            })
            confirmationAlert.addAction(confirmationAction)
            confirmationAlert.addAction(cancelAction)
            present(confirmationAlert, animated: true, completion: nil)
        } else {
            // no service specified
            let missingCategoryAlert = UIAlertController(title: "service.notselected.title".localized, message: "service.notselected.text".localized, preferredStyle: .alert)
            let closeAction = UIAlertAction(title: "general.ok".localized, style: .cancel, handler: nil)
            missingCategoryAlert.addAction(closeAction)
            present(missingCategoryAlert, animated: true, completion: nil)
        }
    }
    
    func cancel(_ sender: AnyObject) {
        self.parent?.dismiss(animated: true, completion: {})
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
        self.locationButton.setTitle(street, for: UIControlState())
    }
    
    // MARK: - Service Management
    
    func updateService() {
        if let service = service {
            serviceButton.setTitle(service.name, for: UIControlState())
            //sendButton.enabled = true
        } else {
            serviceButton.setTitle("general.service".localized, for: UIControlState())
            //sendButton.enabled = false
        }
    }
    
    // MARK: - Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "setService" {
            (segue.destination as! ConcernTypeViewController).addController = self
        }
    }
    
    // MARK: - Image Controller
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[NSString(string: "UIImagePickerControllerOriginalImage") as String] as? UIImage {
            photoButton.setTitle("photo.replace".localized, for: UIControlState())
            let smallImage = imageWithImage(image, scaledToMaxSize: CGSize(width: 2048, height: 2048))
            self.image = smallImage
        }
        self.dismiss(animated: true, completion: {})
    }
    
    @objc func attachPhoto(_ sender: AnyObject) {
        let alert = UIAlertController(title: "photo.source.title".localized, message: "photo.source.text".localized, preferredStyle: .actionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let captureAction = UIAlertAction(title: "photo.source.camera".localized, style: .default) { (action) -> Void in
                self.selectPhoto(.camera)
            }
            alert.addAction(captureAction)
        }
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let selectAction = UIAlertAction(title: "photo.source.library".localized, style: .default) { (action) -> Void in
                self.selectPhoto(.photoLibrary)
            }
            alert.addAction(selectAction)
        }
        let cancelAction = UIAlertAction(title: "general.cancel".localized, style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    func selectPhoto(_ sourceType: UIImagePickerControllerSourceType) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.mediaTypes = [kUTTypeImage as String]
            imagePicker.allowsEditing = false
            imagePicker.sourceType = sourceType
            
            self.present(imagePicker, animated: true, completion: {})
        }
    }
    
    func imageWithImage(_ image: UIImage, scaledToMaxSize maxSize: CGSize) -> UIImage {
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
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 1.0)
        image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    // MARK: - Keyboard Handling
    
    /*
    func dismissKeyboard() {
        descriptionField.resignFirstResponder()
    }
    */
    
    /*
     TODO: Fix this and comment it back in
    func keyboardWillShow(_ notification: Notification) {
        if let userInfo = notification.userInfo as? Dictionary<NSString, AnyObject>, let keyboardRect = userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            if viewCenter == nil {
                viewCenter = view.center
            }
            if let viewCenter = viewCenter {
                view.center = CGPoint(x: view.center.x, y: viewCenter.y - keyboardRect.CGRectValue.height)
            }
        }
    }
 */
    
    @objc func keyboardDidHide(_ notification: Notification) {
        UIView.animate(withDuration: 0.2, animations: { () -> Void in
            if let viewCenter = self.viewCenter {
                self.view.center = viewCenter
            }
        })
    }
    
}
