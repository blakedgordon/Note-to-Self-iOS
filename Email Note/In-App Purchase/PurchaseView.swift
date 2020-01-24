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
    static func upgrade(_ view: UIViewController, productsAvailable: [SKProduct]?) {
        SVProgressHUD.setDefaultMaskType(SVProgressHUDMaskType.clear)
        SVProgressHUD.show(withStatus: "Processing...")
        if NoteToSelfPro.proAvailable(products: productsAvailable) {
            NoteToSelfPro.store.buyProduct(
                NoteToSelfPro.getProduct(NoteToSelfPro.proProductKey, products: productsAvailable)!)
        } else {
            view.presentAlert(title: "Unavailable",
                              message: "Looks like we've hit a snag and we can't seem to purchase this. Please contact support.",
                              actions: [UIAlertAction(title: "Ok", style: .default)])
            SVProgressHUD.dismiss()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 90) {
            if SVProgressHUD.isVisible() {
                SVProgressHUD.showError(withStatus: "Timeout Error")
            }
        }
    }
    
    static func purchase(_ view: UIViewController, notification: NSNotification) {
        SVProgressHUD.dismiss()
        let result = notification.object as? String ?? ""
        if result == "success" {
            if let v = view as? UpgradeViewController {
                v.dismiss(animated: true)
            }
            view.presentAlert(title: "Purchased",
                              message: "Thanks for purchasing Pro!",
                              actions: [UIAlertAction(title: "Ok", style: .default)])
        } else if result == "expired" {
            view.presentAlert(title: "Expired",
                              message: "Looks like your Pro subscription expired. Please renew your subscription by upgrading again.",
                              actions: [UIAlertAction(title: "Ok", style: .default)])
        } else {
            view.presentAlert(title: "Failure",
                              message: "Looks like we've hit a snag and we can't seem to purchase this. Please check your network and App Store account.",
                              actions: [UIAlertAction(title: "Ok", style: .default)])
        }
    }
}
