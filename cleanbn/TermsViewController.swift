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
        
        var url: URL?
        if type == "privacy" {
            title = "Datenschutzhinweise"
            url = URL(string: "https://anliegen.bonn.de/seiten/Datenschutzhinweise")
        }
        if type == "rules" {
            title = "Nutzungsregeln"
            url = URL(string: "https://anliegen.bonn.de/seiten/Regeln")
        }
        if let url = url {
            let request = URLRequest(url: url)
            webView.loadRequest(request)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - WebView Delegate
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if navigationType == .linkClicked {
            if let url = request.url {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
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
