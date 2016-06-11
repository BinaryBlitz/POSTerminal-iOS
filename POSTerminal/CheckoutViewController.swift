//
//  CheckoutViewController.swift
//  POSTerminal
//
//  Created by Dan Shevlyuk on 11/06/2016.
//  Copyright © 2016 BinaryBlitz. All rights reserved.
//

import UIKit

class CheckoutViewController: UIViewController {
  
  @IBOutlet weak var priceTitleLabel: UILabel!
  @IBOutlet weak var priceLabel: UILabel!
  
  @IBOutlet weak var paymentTypeSwitch: UISegmentedControl!

  override func viewDidLoad() {
    super.viewDidLoad()
    
    priceTitleLabel.textColor = UIColor.h5Color()
    priceTitleLabel.font = UIFont.boldSystemFontOfSize(18)
    priceLabel.textColor = UIColor.h4Color()
    priceLabel.font = UIFont.boldSystemFontOfSize(20)
    priceLabel.text = "\(OrderManager.currentOrder.totalPrice.format()) р."
    
    paymentTypeSwitch.tintColor = UIColor.elementsAndH1Color()
    let font = UIFont.boldSystemFontOfSize(17)
    let textAttributes = [NSFontAttributeName: font]
    paymentTypeSwitch.setTitleTextAttributes(textAttributes, forState: .Normal)
    
    paymentTypeSwitch.addTarget(self, action: #selector(changePaymentMethod(_:)), forControlEvents: .ValueChanged)
  }
  
  //MARK: - Actions
  
  func changePaymentMethod(segmentedControl: UISegmentedControl) {
    segmentedControl.userInteractionEnabled = false
    
    var currentController: UIViewController?
    var viewControllerToPresent: UIViewController?
    
    switch segmentedControl.selectedSegmentIndex {
    case 0:
      viewControllerToPresent = storyboard?.instantiateViewControllerWithIdentifier("CardPayment") as! CardPaymentViewController
      for child in childViewControllers {
        if let content = child as? CashPaymentViewController {
          currentController = content
          break
        }
      }
    case 1:
      viewControllerToPresent = storyboard?.instantiateViewControllerWithIdentifier("CashPayment") as! CashPaymentViewController
      for child in childViewControllers {
        if let content = child as? CardPaymentViewController {
          currentController = content
          break
        }
      }
    default:
      return
    }
    
    guard let current = currentController, toPresent = viewControllerToPresent else { return }
    
    current.willMoveToParentViewController(nil)
    addChildViewController(toPresent)
    
    let duration = 0.2
    toPresent.view.frame = current.view.frame
    
    transitionFromViewController(current,
      toViewController: toPresent,
      duration: duration,
      options: UIViewAnimationOptions.TransitionCrossDissolve,
      animations: nil) { (finished) -> Void in
        if finished {
          current.removeFromParentViewController()
          toPresent.didMoveToParentViewController(self)
          segmentedControl.userInteractionEnabled = true
        }
    }
  }
}
