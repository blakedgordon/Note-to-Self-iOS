//
//  PurchaseView.swift
//  Email Note
//
//  Created by Blake Gordon on 11/26/19.
//  Copyright © 2019 Blake Gordon. All rights reserved.
//

import UIKit
import StoreKit
import SVProgressHUD

struct PurchaseView {
    /// Present a HUD on the given view for a user while attempting to process purchase
    /// - Parameters:
    ///   - view: View to present the HUD on
    ///   - productsAvailable: Products desired to purchase
    static func upgrade(_ view: UIViewController, productsAvailable: [SKProduct]?) {
        // Set the SVProgressHUD and present it
        SVProgressHUD.setDefaultMaskType(SVProgressHUDMaskType.clear)
        SVProgressHUD.show(withStatus: "Processing...")
        
        // If Pro is available, then purchase the products. Otherwise there is an error with StoreKit
        // and present an error to the user
        if NoteToSelfPro.proAvailable(products: productsAvailable) {
            NoteToSelfPro.store.buyProduct(
                NoteToSelfPro.getProduct(NoteToSelfPro.proProductKey, products: productsAvailable)!)
        } else {
            view.presentAlert(title: "Unavailable",
                              message: "Looks like we've hit a snag and we can't seem to purchase this. Please contact support.",
                              actions: [UIAlertAction(title: "Ok", style: .default)])
            SVProgressHUD.dismiss()
        }
        
        // Timeout if it takes too long
        DispatchQueue.main.asyncAfter(deadline: .now() + 90) {
            if SVProgressHUD.isVisible() {
                SVProgressHUD.showError(withStatus: "Timeout Error")
            }
        }
    }
    
    /// Presents an alert of the result of a purchase on a given view controller
    /// - Parameters:
    ///   - view: View to present the alert on
    ///   - notification: NSNotification that contains the result of the purchase. This will be a string, either "success", "expired", or any other text
    static func purchase(_ view: UIViewController, notification: NSNotification) {
        // Dismiss any progress HUD
        SVProgressHUD.dismiss()
        
        // Get the result of the purchase. Present the corresponding alert
        let result = notification.object as? String ?? ""
        var title = "Failure"
        var message = "Looks like we've hit a snag and we can't seem to purchase this. Please check your network and App Store account."
        if result == "success" {
            // Dismiss the Upgrade View Controller if that is the presented view
            if let v = view as? UpgradeViewController {
                v.dismiss(animated: true)
            }
            
            title = "Purchased"
            message = "Thanks for purchasing Pro!"
        } else if result == "expired" {
            title = "Expired"
            message = "Looks like your Pro subscription expired. Please renew your subscription by upgrading again."
        }
        view.presentAlert(title: title, message: message, actions: [UIAlertAction(title: "Ok", style: .default)])
    }
}
