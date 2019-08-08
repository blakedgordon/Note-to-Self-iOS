//
//  Emails.swift
//  Email Note
//
//  Created by Blake Gordon on 12/11/18.
//  Copyright © 2018 Blake Gordon. All rights reserved.
//

import Foundation
import Alamofire

class Emails {
    private static var sentDates: [Date] = UserDefaults.standard.array(forKey: "SentDates") as? [Date] ?? []
    private static var emailLimit = 5
    static var remainingTime: String {
        get {
            purgeDates()
            let time = Int(abs(abs(sentDates.last?.timeIntervalSinceNow ?? 86400) - 86400))
            let seconds = time % 60
            let minutes = (time / 60) % 60
            let hours = time / 3600
            var text = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
            if (hours == 0 && minutes == 0 && seconds == 0) || time <= 0 {
                text = "00:00:00"
            }
            return text
        }
    }
    static var remainingEmails: Int {
        get {
            return emailLimit - sentDates.count
        }
    }
    
    static func sendEmail(note: String,
                          completionHandler: @escaping (_ success: Bool, _ message: String, _ hideProgress: Bool, _ setTimer: Bool) -> ()) {
        SecureMail.validateCode(text: note)
        var success = false
        var message = ""
        var hideProgress = false
        var setTimer = false
        var errorEmails = [String]()
        if Emails.canSend() {
            User.validatedEmails { (invalidEmails) in
                if invalidEmails.count > 0 {
                    message = "Please validate your email:\n\(invalidEmails.first ?? "")"
                    if invalidEmails.count > 1 {
                        message = "Please validate your emails"
                    }
                    hideProgress = true
                    completionHandler(success, message, hideProgress, setTimer)
                } else {
                    if note != "" {
                        for (index, email) in User.emails.enumerated() {
                            let key = SecureMail.apiKey
                            let emailBody  = note
                            let parameters = [
                                "from": SecureMail.email,
                                "to": email.trimmingCharacters(in: .whitespacesAndNewlines),
                                "subject": SecureMail.subject,
                                "text": emailBody
                            ]
                            let url = SecureMail.url as URLConvertible
                            
                            let req = Alamofire.request(url, method: .post, parameters: parameters).authenticate(user: "api", password: key)
                            req.response { response in
                                if response.error != nil || response.response == nil {
                                    errorEmails.append(email)
                                } else {
                                    let statusCode = response.response!.statusCode
                                    switch statusCode {
                                    case 200:
                                        // Sent! Success recorded later
                                        break
                                    default:
                                        errorEmails.append(email)
                                    }
                                }
                                
                                if index == User.emails.count - 1 {
                                    if errorEmails.count < User.emails.count {
                                        self.sent() // Record that an email was sent
                                    }
                                    if errorEmails.count == 0 {
                                        success = true
                                        message = "Sent!"
                                    } else if User.emails.count == 1 && errorEmails.count > 0 {
                                        message = "Uh oh! Looks like there was an issue sending!"
                                    } else if User.emails.count == errorEmails.count {
                                        message = "Uh oh! Looks like there was an issue sending to all of your emails."
                                    } else if errorEmails.count == 1 {
                                        success = true
                                        message = "Sent! But it looks like there was an issue sending an email to \(errorEmails[0])"
                                    } else if errorEmails.count > 1 {
                                        success = true
                                        message = "Sent! But it looks like there was an issue sending to \(errorEmails.count) emails"
                                    }
                                    completionHandler(success, message, hideProgress, setTimer)
                                }
                            }
                        }
                    } else {
                        if User.emails.count > 1 {
                            message = "Please type a note to send to\nyour emails"
                        } else {
                            message = "Please type a note to send to:\n" + User.mainEmail
                        }
                        hideProgress = true
                        completionHandler(success, message, hideProgress, setTimer)
                    }
                }
            }
        } else {
            message = "Please wait \(Emails.remainingTime) to send email,\nor upgrade to Pro!"
            hideProgress = true
            setTimer = true
            completionHandler(success, message, hideProgress, setTimer)
        }
    }
    
    static func sent() {
        sentDates.insert(Date(), at: 0)
        purgeDates()
    }
    
    static func canSend() -> Bool {
        purgeDates()
        return sentDates.count < emailLimit || User.purchasedPro
    }
    
    private static func purgeDates() {
        // 86,400 seconds is 24 hours
        // Remove dates that are older than 24 hours
        if sentDates.count > 0 {
            while sentDates.count > 0 && sentDates[sentDates.count - 1].timeIntervalSinceNow < -86400 {
                sentDates.removeLast()
            }
        }
        setUserDefaults()
    }
    
    private static func setUserDefaults() {
        UserDefaults.standard.set(sentDates, forKey: "SentDates")
    }
}
