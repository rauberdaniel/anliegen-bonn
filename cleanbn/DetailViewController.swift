//
//  DetailViewController.swift
//  cleanbn
//
//  Created by Daniel Rauber on 17.04.15.
//  Copyright (c) 2015 Daniel Rauber. All rights reserved.
//

import UIKit
import MapKit

class DetailViewController: UITableViewController {

    @IBOutlet weak var detailDescriptionLabel: UILabel!


    var detailItem: Concern? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }

    func configureView() {
        // Update the user interface for the detail item.
        if let detail: Concern = self.detailItem {
            title = detail.title
            if let label = self.detailDescriptionLabel {
                label.text = detail.title
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table View
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 1 {
            return 60
        }
        return 200
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCellWithIdentifier("MapCell", forIndexPath: indexPath) as! UITableViewCell

            let map = cell.viewWithTag(2) as! MKMapView
            if let coord = detailItem?.location?.coordinate {
                let annotation = MKPointAnnotation()
                annotation.title = detailItem?.locationName
                annotation.coordinate = coord
                map.addAnnotation(annotation)
                let span = MKCoordinateSpanMake(0.005, 0.005)
                let region: MKCoordinateRegion = MKCoordinateRegionMake(coord, span)
                map.setRegion(region, animated: false)
            }
            
            return cell
        case 1:
            let cell = tableView.dequeueReusableCellWithIdentifier("DefaultCell", forIndexPath: indexPath) as! UITableViewCell
            
            cell.selectionStyle = .None
            if let address = detailItem?.locationName {
                cell.textLabel?.text = address
            }
            
            return cell
        case 2:
            let cell = tableView.dequeueReusableCellWithIdentifier("DescriptionCell", forIndexPath: indexPath) as! UITableViewCell
            
            if let desc = detailItem?.desc {
                let textView = cell.viewWithTag(2) as! UITextView
                textView.text = desc
            }
            
            return cell
        default:
            let cell = tableView.dequeueReusableCellWithIdentifier("DescriptionCell", forIndexPath: indexPath) as! UITableViewCell
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 1 {
            // Open Apple Maps
            var encodedAddress = detailItem?.locationName.stringByReplacingOccurrencesOfString(" ", withString: "+", options: .LiteralSearch, range: nil)
            encodedAddress = encodedAddress?.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())
            if let encodedAddress = encodedAddress {
                let url = NSURL(string: "https://maps.apple.com/?q=\(encodedAddress)")
                if let u = url {
                    UIApplication.sharedApplication().openURL(u)
                }
            }
        }
    }

}

