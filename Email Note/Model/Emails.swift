//
//  Emails.swift
//  Email Note
//
//  Created by Blake Gordon on 12/11/18.
//  Copyright © 2018 Blake Gordon. All rights reserved.
//

import Foundation
import Alamofire

/// Data regarding how many emails the user is still able to send, emails they have sent, etc., and the sending of emails
class Emails {
    /// Array of dates that emails have been sent to see if user is still able to send emails (and when they can next)
    private static var sentDates: [Date] {
        get {
            var dates = UserDefaults.standard.array(forKey: "SentDates") as? [Date] ?? []
            if dates.count > 0 {
                while dates.count > 0 && dates[dates.count - 1].timeIntervalSinceNow < -86400 {
                    dates.removeLast()
                }
            }
            UserDefaults.standard.set(dates, forKey: "SentDates")
            return dates
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "SentDates")
        }
    }
    
    /// The number of emails that a user is able to send if they aren't a Pro user
    private static var emailLimit = 5
    
    /// A string of how much time is remaining before the user is able to send another email
    static var remainingTime: String {
        get {
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
    
    /// The number of emails that a non-Pro user is able to send
    static var remainingEmails: Int {
        get {
            return emailLimit - sentDates.count
        }
    }
    
    /// The subject line for any sent email that the user wants. Default is "Note to Self"
    static var subject: String {
        get{
            return UserDefaults.standard.string(forKey: "subject") ?? "Note to Self"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "subject")
        }
    }
    
    /// All of the emails that have been sent by the user
    static var sentEmails: [SentEmail] {
        get {
            do {
                guard let data = UserDefaults.standard.data(forKey: "sentEmails") else { return [] }
                let array = try JSONDecoder().decode([SentEmail].self, from: data)
                return array
            } catch {
                return []
            }
        }
        set {
            let sortedValue = newValue.sorted { $0.date > $1.date }
            do {
                try UserDefaults.standard.set(JSONEncoder().encode(sortedValue), forKey: "sentEmails")
                UserDefaults.standard.synchronize()
            } catch {
                print(error)
            }
        }
    }
}

// MARK: - Sending an email to the user
extension Emails {
    
    /// Record that an email has been sent
    static func sent() {
        sentDates.insert(Date(), at: 0)
    }
    
    /// Determine if an email can be sent based on their email limit, or if the user has purchased Pro
    static func canSend() -> Bool {
        return sentDates.count < emailLimit || User.purchasedPro
    }
    
    /// Utilizes an API to send an email to the user's specified email(s)
    /// - Parameters:
    ///   - note: The body of the email
    ///   - completionHandler: Result of sending the email
    ///   - success: Whether an email was sent to all specified addresses (if one or more fails, then
    /// this returns false)
    /// - Parameters:
    ///   - message: The message to display to the user for the email being sent (i.e. if there was a problem)
    ///   - hideProgress: Hide the progress bar that appears when sending an email from the UI
    ///   - setTimer: Specify a timer for the bottomView of the NoteViewController to hide
    static func sendEmail(note: String,
                          completionHandler: @escaping (_ success: Bool,
        _ message: String, _ hideProgress: Bool, _ setTimer: Bool) -> ()) {
        // Validate the email body string
        SecureMail.validate(note)
        
        var success = false
        var message = ""
        var hideProgress = false
        var setTimer = false
        var errorEmails = [String]()
        
        // Check to make sure the user can send an email
        if Emails.canSend() {
            User.validatedEmails { (invalidEmails) in
                // All specified emails need to be validated to send an email
                if invalidEmails.count > 0 {
                    message = "Please validate your email:\n\(invalidEmails.first ?? "")"
                    if invalidEmails.count > 1 {
                        message = "Please validate your emails"
                    }
                    hideProgress = true
                    completionHandler(success, message, hideProgress, setTimer)
                } else {
                    if note != "" {
                        // Loop through all of the user's emails and send an email to each one
                        for (index, email) in User.emails.enumerated() {
                            let emailBody  = note
                            let toEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
                            let url = SecureMail.url as URLConvertible
                            let key = SecureMail.apiKey
                            
                            // The API service expects the items below in a POST request to send the email
                            let parameters = [
                                "from": SecureMail.email,
                                "to": toEmail,
                                "subject": subject,
                                "text": emailBody
                            ]
                            
                            // Using the API, send a request to send the email
                            let req = Alamofire.request(url, method: .post, parameters: parameters).authenticate(user: SecureMail.username, password: key)
                            req.response { response in
                                if response.error != nil || response.response == nil {
                                    // Add an email if there was an error associated with the address
                                    errorEmails.append(email)
                                } else {
                                    let statusCode = response.response!.statusCode
                                    switch statusCode {
                                    case 200:
                                        // Sent! Success recorded later
                                        sentEmails.insert(SentEmail(to: toEmail, message: emailBody), at: 0)
                                        break
                                    default:
                                        // If it wasn't a success, then it's a problem
                                        errorEmails.append(email)
                                    }
                                }
                                
                                // If it's the last email address for all of the user's email addresses
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
                        // If no text was specified
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
            // The user isn't able to send an email right now
            message = "Please wait \(Emails.remainingTime) to send email,\nor upgrade to Pro!"
            hideProgress = true
            setTimer = true
            completionHandler(success, message, hideProgress, setTimer)
        }
    }
}
