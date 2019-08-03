//
//  SettingsTableViewController.swift
//  Email Note
//
//  Created by Blake Gordon on 12/11/18.
//  Copyright © 2018 Blake Gordon. All rights reserved.
//

import UIKit
import MessageUI
import StoreKit
import SVProgressHUD

class SettingsTableViewController: UITableViewController, UITextFieldDelegate, MFMailComposeViewControllerDelegate {

    @IBOutlet weak var validateEmailButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var newEmailButton: UIButton!
    @IBOutlet weak var subjectTextField: UITextField!
    @IBOutlet weak var darkModeLabel: UILabel!
    @IBOutlet weak var darkModeSwitch: UISwitch!
    @IBOutlet weak var privacyLabel: UILabel!
    @IBOutlet weak var termsLabel: UILabel!
    @IBOutlet weak var contactLabel: UILabel!
    @IBOutlet weak var upgradeProButton: UIButton!
    @IBOutlet weak var restorePurchasesButton: UIButton!
    @IBOutlet weak var remainingEmailsLabel: UILabel!
    
    var timer: Timer? = nil
    let numberOfTotalSections = 5
    
    var productsAvailable: [SKProduct]?
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        if let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), User.isValidEmail(email) {
            User.mainEmail = email
            if let subject = subjectTextField.text, subject != "" {
                SecureMail.subject = subject
            }
            view.endEditing(true)
            dismiss(animated: true)
        } else {
            let alertTitle = "Enter Email"
            let alertMessage = "Please enter a valid email address"
            let alertAction = UIAlertAction(title: "Ok", style: .default)
            self.presentDarkAlert(title: alertTitle, message: alertMessage, actions: [alertAction], darkMode: User.darkMode)
        }
    }
    
    @IBAction func emailValueChanged(_ sender: Any) {
        if User.emailsValidated.keys.contains(emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? " ") {
            validateEmailButton.isEnabled = true
            self.validateEmailButton.isUserInteractionEnabled = false
            self.validateEmailButton.tintColor = UIColor.green
        } else {
            validateEmailButton.isEnabled = false
        }
    }
    
    @IBAction func validateEmail(_ sender: Any) {
        User.validateRequest(email: User.mainEmail)
        self.presentDarkAlert(title: "Request Sent", message: "Email validation request sent!",
                              actions: [UIAlertAction(title: "Ok", style: .default)], darkMode: User.darkMode)
    }
    
    @IBAction func darkSwitched(_ sender: UISwitch) {
        view.endEditing(true)
        User.darkMode = sender.isOn
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.75) {
            self.darkMode(on: User.darkMode)
        }
    }
    
    @IBAction func upgradeToProPressed(_ sender: Any) {
        SVProgressHUD.setDefaultMaskType(SVProgressHUDMaskType.clear)
        SVProgressHUD.show(withStatus: "Processing...")
        if NoteToSelfPro.proAvailable(products: productsAvailable) {
            NoteToSelfPro.store.buyProduct(
                NoteToSelfPro.getProduct(NoteToSelfPro.proProductKey, products: productsAvailable)!)
        } else {
            self.presentDarkAlert(title: "Unavailable",
                                  message: "Looks like we've hit a snag and we can't seem to purchase this. Please contact support.",
                                  actions: [UIAlertAction(title: "Ok", style: .default)],
                                  darkMode: User.darkMode)
            SVProgressHUD.dismiss()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 90) {
            if SVProgressHUD.isVisible() {
                SVProgressHUD.showError(withStatus: "Timeout Error")
            }
        }
    }
    
    @IBAction func restorePurchasesPressed(_ sender: Any) {
        SVProgressHUD.setDefaultMaskType(SVProgressHUDMaskType.clear)
        SVProgressHUD.show(withStatus: "Processing...")
        if productsAvailable?.count ?? 0 > 0 {
            NoteToSelfPro.store.restorePurchases()
        } else {
            self.presentDarkAlert(title: "Unavailable",
                                  message: "Looks like we've hit a snag and we can't seem to restore any purchases. Please contact support.",
                                  actions: [UIAlertAction(title: "Ok", style: .default)],
                                  darkMode: User.darkMode)
            SVProgressHUD.dismiss()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
            if SVProgressHUD.isVisible() {
                SVProgressHUD.showError(withStatus: "Timeout Error")
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailTextField.delegate = self
        subjectTextField.delegate = self
        
        NoteToSelfPro.validateReceipt()
        upgradeProButton.layer.cornerRadius = 4
        upgradeProButton.setTitle(NoteToSelfPro.proPriceLabel, for: .normal)
        upgradeProButton.updateConstraints()
        
        NotificationCenter.default.addObserver(self, selector: #selector(purchase),
                                               name: NSNotification.Name(rawValue: NoteToSelfPro.purchaseNotification), object: nil)
    }
    
    @objc func purchase(notification: NSNotification) {
        SVProgressHUD.dismiss()
        let result = notification.object as? String ?? ""
        if result == "success" {
            self.presentDarkAlert(title: "Purchased",
                                  message: "Thanks for purchasing Pro!",
                                  actions: [UIAlertAction(title: "Ok", style: .default)],
                                  darkMode: User.darkMode)
            self.tableView.reloadData()
            darkModeSwitch.isEnabled = true
        } else if result == "expired" {
            self.presentDarkAlert(title: "Expired",
                                  message: "Looks like your Pro subscription expired. Please renew your subscription by upgrading again.",
                                  actions: [UIAlertAction(title: "Ok", style: .default)],
                                  darkMode: User.darkMode)
        } else {
            self.presentDarkAlert(title: "Failure",
                                  message: "Looks like we've hit a snag and we can't seem to purchase this. Please check your network and App Store account.",
                                  actions: [UIAlertAction(title: "Ok", style: .default)],
                                  darkMode: User.darkMode)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        emailTextField.text = User.mainEmail
        subjectTextField.text = SecureMail.subject
        
        User.validatedEmails { (invalidEmails) in
            self.validateEmailButton.isEnabled = true
            if let mainEmail = self.emailTextField.text, !invalidEmails.contains(mainEmail) {
                self.validateEmailButton.isUserInteractionEnabled = false
                self.validateEmailButton.tintColor = UIColor.green
            }
        }
        
        NoteToSelfPro.store.requestProducts { (_, products) in
            self.productsAvailable = products
        }
        
        newEmailButton.isEnabled = User.purchasedPro
        darkModeSwitch.isEnabled = User.purchasedPro
        darkModeSwitch.isOn = (User.purchasedPro) ? User.darkMode : false
        if !User.purchasedPro {
            if Emails.remainingEmails > 0 {
                var emailText = (Emails.remainingEmails == 1) ? "email" : "emails"
                var remainingTime = (Emails.remainingTime == "00:00:00") ? "24 hours" : Emails.remainingTime
                remainingEmailsLabel.text = "Send \(Emails.remainingEmails) more \(emailText) for the next \(remainingTime)"
                if remainingTime != "24 hours" {
                    timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                        emailText = (Emails.remainingEmails == 1) ? "email" : "emails"
                        remainingTime = (Emails.remainingTime == "00:00:00") ? "24 hours" : Emails.remainingTime
                        self.remainingEmailsLabel.text = "Send \(Emails.remainingEmails) more \(emailText) for the next \(remainingTime)"
                    }
                }
            } else {
                remainingEmailsLabel.text = "Please wait \(Emails.remainingTime) to send another email"
                timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                    self.remainingEmailsLabel.text = "Please wait \(Emails.remainingTime) to send another email"
                }
            }
        }
        
        darkMode(on: User.darkMode)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        let sections = (User.purchasedPro) ? numberOfTotalSections - 1 : numberOfTotalSections
        return sections
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(tableView.headerView(forSection: indexPath.section)?.textLabel?.text as Any)
        if tableView.headerView(forSection: indexPath.section)?.textLabel?.text?.lowercased() == "support" {
            if indexPath.row == 0 {
                if let url = URL(string: "https://notetoselfapp.com#privacy"){
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            } else if indexPath.row == 1 {
                if let url = URL(string: "https://notetoselfapp.com/terms.html"){
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            } else if indexPath.row == 2 {
                sendEmailButtonTapped()
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    func darkMode(on: Bool) {
        self.view.backgroundColor = (on) ? UIColor.black : UIColor.groupTableViewBackground
        self.tableView.separatorColor = (on) ? UIColor.black : UIColor.lightGray
        self.navigationController?.navigationBar.barStyle = (on) ? .black : .default
        self.navigationController?.view.backgroundColor = (on) ? UIColor.black : UIColor.white
        emailTextField.textColor = (on) ? UIColor.white : UIColor.black
        subjectTextField.textColor = (on) ? UIColor.white : UIColor.black
        darkModeLabel.textColor = (on) ? UIColor.white : UIColor.black
        remainingEmailsLabel.textColor = (on) ? UIColor.white : UIColor.black
        privacyLabel.textColor = (on) ? UIColor.white : UIColor.black
        termsLabel.textColor = (on) ? UIColor.white : UIColor.black
        contactLabel.textColor = (on) ? UIColor.white : UIColor.black
        
        emailTextField.keyboardAppearance = (on) ? .dark : .light
        subjectTextField.keyboardAppearance = (on) ? .dark : .light
        
        for cell in self.tableView.visibleCells {
            cell.backgroundColor = (on) ? UIColor.darkGray : UIColor.white
        }
        for i in (0..<tableView.numberOfSections) {
            self.tableView.headerView(forSection: i)?.backgroundView?.backgroundColor = (on) ? UIColor.black :
                UIColor.groupTableViewBackground
            self.tableView.footerView(forSection: i)?.backgroundView?.backgroundColor = (on) ? UIColor.black :
                UIColor.groupTableViewBackground
        }
    }
    
    // FUNCTIONS BELOW RECIEVED FROM STACK OVERFLOW TO SEND AN EMAIL
    func sendEmailButtonTapped() {
        let mailComposeViewController = configuredMailComposeViewController()
        if MFMailComposeViewController.canSendMail() {
            self.present(mailComposeViewController, animated: true, completion: nil)
        }
    }
    
    func configuredMailComposeViewController() -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
        mailComposerVC.mailComposeDelegate = self
        
        mailComposerVC.setToRecipients(["Note to Self Support <support@notetoselfapp.com>"])
        
        return mailComposerVC
    }
    
    // MARK: MFMailComposeViewControllerDelegate
    
    func mailComposeController(_ controller: MFMailComposeViewController,
                                       didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
        
    }
    // END
}
