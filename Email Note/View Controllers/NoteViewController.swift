//
//  NoteViewController.swift
//  Email Note
//
//  Created by Blake Gordon on 10/28/18.
//  Copyright © 2018 Blake Gordon. All rights reserved.
//

import UIKit

class NoteViewController: UIViewController, UIScrollViewDelegate, UITextViewDelegate {
    
    @IBOutlet var note: UITextView!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var sendingLabel: UILabel!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var sendingProgress: UIProgressView!
    
    @IBOutlet weak var viewHeight: NSLayoutConstraint!
    @IBOutlet var bottomConstraint: NSLayoutConstraint!
    
    var sending = false
    var showingBottomView = false
    var showBottomViewTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !User.isValidEmail(User.mainEmail) {
                self.emailAddress(self)
            } else {
                User.validatedEmails(completionHandler: { (emails) in
                    if emails.count > 0 {
                        var emailString = "email"
                        if emails.count > 1 {
                            emailString = "emails"
                        }
                        var message = "Please validate your \(emailString):"
                        for email in emails {
                            message.append(contentsOf: "\n\(email)")
                        }
                        self.presentDarkAlert(title: "Invalid \(emailString.capitalized)",
                            message: message,
                            actions: [UIAlertAction(title: "Ok", style: .default, handler: nil)],
                            darkMode: User.darkMode)
                    }
                })
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown),
                                               name: UIWindow.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appBecameActive),
                                               name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        darkMode(on: User.darkMode)
        note.becomeFirstResponder()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        bottomView(show: true, time: 5, completion: nil)
    }
    
    @objc func appBecameActive(notification: NSNotification) {
        darkMode(on: User.darkMode)
        note.becomeFirstResponder()
        bottomView(show: true, time: 5, completion: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.sendingLabel.text = "Swipe left or right to send a note"
    }
    
    @IBAction func sendEmail(_ sender: Any) {
        if !sending {
            self.sendingLabel.text = "Sending..."
            self.sendingProgress.isHidden = false
            self.sendingProgress.progress = 0
            
            self.sending = true
            
            self.bottomView(show: true, time: nil, completion: nil)
            
            self.sendingProgress.isHidden = false
            self.sendingProgress.setProgress(0.05, animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if self.sendingProgress.progress == 0.05 {
                    self.sendingProgress.setProgress(0.85, animated: true)
                }
            }
            Emails.sendEmail(note: self.note.text) { (success, message, hideProgress, setTimer) in
                if success {
                    self.note.text = ""
                }
                self.sendingProgress.setProgress(1, animated: true)
                self.sendingLabel.text = message
                self.sendingProgress.isHidden = hideProgress
                var timer: Timer?
                if setTimer {
                    timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                        if message.contains("Please wait") {
                            self.sendingLabel.text = "Please wait \(Emails.remainingTime) to send email,\nor upgrade to Pro!"
                        } else {
                            self.sendingLabel.text = message
                        }
                    }
                }
                self.sending = false
                self.bottomView(show: true, time: 10, completion: {
                    self.sendingProgress.isHidden = true
                    timer?.invalidate()
                })
            }
        }
    }
    
    func emailAddress(_ sender: Any) {
        let setUserEmail = UIAlertController(title: "Set Email",
                                             message: "Please enter your email to send notes to yourself",
                                             preferredStyle: .alert)
        setUserEmail.addTextField(configurationHandler: nil)
        setUserEmail.addAction(UIAlertAction(title: "Save", style: .default, handler: { action in
            let email = setUserEmail.textFields![0].text!.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !User.isValidEmail(email) {
                let noEmailText = UIAlertController(title: "Enter Email",
                                                    message: "Please enter a valid email address",
                                                    preferredStyle: .alert)
                noEmailText.addAction(UIAlertAction(title: "Ok", style: .default, handler: { action in
                    self.setDark(alert: setUserEmail, darkModeOn: User.darkMode)
                    self.present(setUserEmail, animated: true, completion: nil)
                }))
                
                self.setDark(alert: noEmailText, darkModeOn: User.darkMode)
                self.present(noEmailText, animated: true, completion: nil)
            } else {
                User.mainEmail = email
                self.sendingLabel.text = "Email set to:\n" + User.mainEmail
                self.bottomView(show: true, time: 5, completion: nil)
                
                User.validatedEmails(completionHandler: { (invalid) in
                    if invalid.contains(email) {
                        self.presentDarkAlert(title: "Verify Email",
                                              message: "An email has been sent to your address, please verify your email",
                                              actions: [UIAlertAction(title: "Ok", style: .default, handler: nil)],
                                              darkMode: User.darkMode)
                    }
                })
            }
        }))
        
        let textField = setUserEmail.textFields![0]
        textField.placeholder = "Email"
        textField.text = User.mainEmail
        textField.autocorrectionType = .default
        textField.textContentType = UITextContentType.emailAddress
        textField.keyboardType = UIKeyboardType.emailAddress
        textField.returnKeyType = UIReturnKeyType.done
        
        self.setDark(alert: setUserEmail, darkModeOn: User.darkMode)
        self.present(setUserEmail, animated: true, completion: nil)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrollViewHeight = scrollView.frame.size.height
        let scrollContentSizeHeight = scrollView.contentSize.height
        let scrollOffset = scrollView.contentOffset.y
        
        // If we're at the end of the scroll view
        if scrollOffset + scrollViewHeight > scrollContentSizeHeight {
            bottomView(show: true, time: 5, completion: nil)
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return !sending
    }
    
    func bottomView(show: Bool, time: TimeInterval?, completion: (() -> Void)?) {
        if showingBottomView != show {
            self.showingBottomView = show
            if show {
                self.sendingLabel.isHidden = false
            }
            self.sendingLabel.alpha = show ? 0 : 1
            self.settingsButton.alpha = show ? 0 : 1
            
            self.view.layoutIfNeeded()
            UIView.animate(withDuration: 0.5, animations: {
                self.viewHeight.constant = show ? 50 : 0
                self.sendingLabel.alpha = show ? 1 : 0
                self.settingsButton.alpha = show ? 1 : 0
                self.view.layoutIfNeeded()
            }, completion: { _ in
                if self.viewHeight.constant == 0 {
                    self.sendingLabel.isHidden = true
                    self.sendingProgress.isHidden = true
                    self.sendingLabel.text = "Swipe left or right to send a note"
                }
                
                if !(self.showBottomViewTimer?.isValid ?? false) {
                    completion?()
                }
            })
        }
        self.showBottomViewTimer?.invalidate()
        if let t = time {
            self.showBottomViewTimer = Timer.scheduledTimer(withTimeInterval: t, repeats: false, block: { (_) in
                self.bottomView(show: !show, time: nil, completion: completion)
            })
        }
    }
    
    @objc func keyboardWasShown(notification: NSNotification) {
        if let kbSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.size {
            if #available(iOS 11.0, *) {
                bottomConstraint.constant = kbSize.height - view.safeAreaInsets.bottom
            } else {
                // Fallback on earlier versions
                bottomConstraint.constant = kbSize.height
            }
        }
    }
    
    func darkMode(on: Bool) {
        self.view.backgroundColor = (on) ? UIColor.darkGray : UIColor.white
        self.bottomView.backgroundColor = (on) ? UIColor.black : UIColor.darkGray
        self.setNeedsStatusBarAppearanceUpdate()
        note.textColor = (on) ? UIColor.white : UIColor.black
        note.keyboardAppearance = (on) ? .dark : .light
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return (User.darkMode) ? .lightContent : .default
    }
}

