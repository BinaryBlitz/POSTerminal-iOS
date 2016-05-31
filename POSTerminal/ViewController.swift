//
//  ViewController.swift
//  POSTerminal
//
//  Created by Dan Shevlyuk on 30/05/2016.
//  Copyright © 2016 BinaryBlitz. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class ViewController: UIViewController {

  @IBOutlet weak var output: UITextView!
  @IBOutlet weak var webView: UIWebView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    output.text = ""
    RedSocketManager.sharedInstance().setDelegate(self)
    RedSocketManager.sharedInstance().configureNetworkInterface("0.0.0.0", gateway: "0.0.0.0", netmask: "0.0.0.0", dns: nil)
  }
  
  @IBAction func getStuff() {
    ServerManager.sharedManager.manager.request(.GET, "http://yesno.wtf/api").responseJSON { (response) in
      switch response.result {
      case .Success(let resultvalue):
        let json = JSON(resultvalue)
        self.output.text = self.output.text.stringByAppendingString(String(json))
      case .Failure(let error):
        self.output.text = self.output.text.stringByAppendingString(String(error))
      }
    }
  }
}

extension ViewController: RedSocketManagerDelegate {
  func cableConnected(protocol: String!) {
    output.text = output.text.stringByAppendingString("cabel connected")
  }
  
  func cableDisconnected() {
    output.text = output.text.stringByAppendingString("cabel disconnected")
  }
}
