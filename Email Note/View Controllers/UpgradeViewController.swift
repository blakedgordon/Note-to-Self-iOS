//
//  UpgradeViewController.swift
//  Email Note
//
//  Created by Blake Gordon on 11/26/19.
//  Copyright © 2019 Blake Gordon. All rights reserved.
//

import UIKit
import StoreKit
import SVProgressHUD

class UpgradeViewController: UIViewController {

    @IBOutlet weak var proImage: UIImageView!
    @IBOutlet weak var subscriptionLabel: UILabel!
    @IBOutlet weak var freeTrialLabel: UILabel!
    @IBOutlet weak var subscribeButton: UIButton!
    
    var productsAvailable: [SKProduct]?
    
    @IBAction func upgradeToProPressed(_ sender: Any) {
        PurchaseView.upgrade(self, productsAvailable: productsAvailable)
    }
    
    @IBAction func cancelPressed(_ sender: Any) {
        dismiss(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        proImage.layer.cornerRadius = 7
        
        subscriptionLabel.text = NoteToSelfPro.proPriceLabel
        
        freeTrialLabel.isHidden = !(NoteToSelfPro.proTrialExists ?? false)
        freeTrialLabel.text = NoteToSelfPro.proTrialString
        
        subscribeButton.layer.cornerRadius = 5
        subscribeButton.updateConstraints()
        
        NotificationCenter.default.addObserver(self, selector: #selector(purchase),
        name: NSNotification.Name(rawValue: NoteToSelfPro.purchaseNotification), object: nil)
    }
    
    @objc func purchase(notification: NSNotification) {
        PurchaseView.purchase(self, notification: notification)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NoteToSelfPro.store.requestProducts { (_, products) in
            self.productsAvailable = products
        }
    }

}
