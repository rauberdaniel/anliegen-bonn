//
//  TermsViewController.swift
//  cleanbn
//
//  Created by Daniel Rauber on 23.05.15.
//  Copyright (c) 2015 Daniel Rauber. All rights reserved.
//

import UIKit

class TermsViewController: UIViewController, UIWebViewDelegate {
    @IBOutlet weak var webView: UIWebView!
    
    var type: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.delegate = self
        
        var url: NSURL?
        if type == "privacy" {
            title = "Datenschutzhinweise"
            url = NSURL(string: "http://anliegen.bonn.de/seiten/datenschutzhinweise")
        }
        if type == "rules" {
            title = "Nutzungsregeln"
            url = NSURL(string: "http://anliegen.bonn.de/seiten/regeln")
        }
        if let url = url {
            let request = NSURLRequest(URL: url)
            webView.loadRequest(request)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - WebView Delegate
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if navigationType == .LinkClicked {
            if let url = request.URL {
                UIApplication.sharedApplication().openURL(url)
                return false
            }
        }
        return true
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
