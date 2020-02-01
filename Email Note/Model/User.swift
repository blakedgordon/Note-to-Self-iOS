//
//  User.swift
//  Email Note
//
//  Created by Blake Gordon on 12/11/18.
//  Copyright © 2018 Blake Gordon. All rights reserved.
//

import Foundation
import FirebaseAuth

/// All of the user's emails and settings
class User {
    /// The user's primary email address
    static var mainEmail: String {
        get {
            return (UserDefaults.standard.array(forKey: "email") as? [String])?.first ?? ""
        }
        set {
            self.emails[0] = newValue
        }
    }
    
    /// All of the emails that a user has set (up to 5)
    static var emails: [String] {
        get {
            let array = UserDefaults.standard.array(forKey: "email") as? [String] ?? [""]
            return (User.purchasedPro) ? Array(array.prefix(5)) : [self.mainEmail]
        }
        set {
            UserDefaults.standard.set(Array(newValue.prefix(5)), forKey: "email")
        }
    }
    
    /// If the user has purchased Pro
    static var purchasedPro: Bool {
        get {
            #if DEBUG
            return true
            #else
            return (UserDefaults.standard.bool(forKey: NoteToSelfPro.proProductKey) &&
                (NoteToSelfPro.expireDate > Date() || NoteToSelfPro.expireDateCode > Date()))
            #endif
        }
        set {
            UserDefaults.standard.set(newValue, forKey: NoteToSelfPro.proProductKey)
        }
    }
    
    /// If the user has specified to use Dark Mode
    static var darkMode: Bool {
        get {
            return (User.purchasedPro && UserDefaults.standard.bool(forKey: "darkMode"))
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "darkMode")
        }
    }
    
    /// An array of validated emails
    ///
    /// This is for caching emails that the device knows have already been validated, to reduce the need
    /// of polling Firebase for validated emails
    static var emailsValidated: [String] {
        get {
            if let validatedArray = UserDefaults.standard.object(forKey: "validatedEmails") as? [String] {
                return validatedArray
            }
            // At one point, pre-v1.3.1 this object was a [String: Bool] dict, but was apparent that it should just be
            // a string array, and has changed. This is to ensure backwards compatability.
            return Array((UserDefaults.standard.object(forKey: "validatedEmails") as? [String: Bool] ?? ["": false]).keys)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "validatedEmails")
        }
    }
}

// MARK: - Email Validation
extension User {
    /// Returns boolean for whether or not a string looks like an email address using regex
    /// - Parameter testStr: The string to verify whether or not it looks like an email address
    ///
    /// - Returns: Boolean if the string looks like an email address or not
    static func isValidEmail(_ testStr: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    
    /// An async function to determine if an email has been validated by the user. If the email has not been used before to request validation, then
    /// an email is sent to the user to verify their email address.
    /// - Parameters:
    ///   - email: String of the email to check if it has been validated or not
    ///   - completionHandler: A closure which is called with whether the email is verified, and if a new verification email was sent to the address
    ///   - verified: If true, the user has verified the email. `nil` indicates an invalid email string
    ///   - verificationSent: Whether or not a new verification email was sent to the user
    static func isEmailValidated(_ email: String, completionHandler: @escaping (_ verified: Bool?, _ verificationSent: Bool?) -> ()) {
        let formattedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // If the email is already in the emailsValidated array, then it's already
        // valid, and complete with verified set to true
        if Comparison.containsCaseInsensitive(formattedEmail, emailsValidated) {
            completionHandler(true, nil)
            return
        }
        
        // If the email isn't a valid email format, then set verified to nil
        if !isValidEmail(formattedEmail) {
            completionHandler(nil, nil)
            return
        }
        
        // Using Firebase, if the email has already been sent a verification email,
        // then sign in agian to see if it's verified, otherwise send the email to the newly
        // created account
        Auth.auth().fetchSignInMethods(forEmail: formattedEmail) { (providers, error) in
            if let prov = providers, prov.count > 0 {
                Auth.auth().signIn(withEmail: formattedEmail, password: formattedEmail, completion: { (result, error) in
                    if let user = result?.user, user.isEmailVerified {
                        completionHandler(true, nil)
                        emailsValidated.append(formattedEmail)
                    } else {
                        completionHandler(false, nil)
                    }
                    self.signOut()
                })
            } else {
                self.validateRequest(email: formattedEmail) { (error) in
                    completionHandler(false, error == nil)
                }
            }
        }
    }
    
    /// Sends an email verification to the user's given email
    /// - Parameters:
    ///   - email: Email to send the verification to
    ///   - completionHandler: Completion of the request and passes any error that may be the result of the request
    ///   - error: Any error that could be a result from an email verification
    static func validateRequest(email: String, completionHandler: @escaping (_ error: Error?) -> ()) {
        let formattedEmail = email.lowercased()
        Auth.auth().fetchSignInMethods(forEmail: formattedEmail) { (providers, error) in
            if let prov = providers, prov.count > 0 {
                Auth.auth().signIn(withEmail: formattedEmail, password: formattedEmail, completion: { (result, error) in
                    result?.user.sendEmailVerification { (error) in
                        completionHandler(error)
                    }
                    self.signOut()
                })
            } else {
                Auth.auth().createUser(withEmail: formattedEmail, password: formattedEmail, completion: { (result, error) in
                    result?.user.sendEmailVerification { (error) in
                        completionHandler(error)
                    }
                    self.signOut()
                })
            }
        }
    }
    
    /// This method goes through all of the user's emails to determine if they are validated or not. completionHandler contains an array of all
    /// the emails that aren't validated for the user's emails
    /// - Parameter completionHandler: Waits for all of the emails for the user to validate all of them to see if any are not validated
    /// - Parameter emailsNotValidated: An array of all the user's emails that are not validated
    static func validatedEmails(completionHandler: @escaping (_ emailsNotValidated: [String]) -> ()) {
        var invalidEmails = [String]()
        if Comparison.isSubsetCaseInsensitive(emails, emailsValidated) {
            completionHandler(invalidEmails)
            return
        }
        for (index, email) in emails.enumerated() {
            isEmailValidated(email) { validated, _ in
                if !(validated ?? false) {
                    invalidEmails.append(email)
                }
                
                /*
                 Necessary to check if this is the last item in the array, since calling
                 the completion handler after the for block doesn't work properly because
                 isEmailValidated is an asynchronous function
                */
                if index == emails.count - 1 {
                    completionHandler(invalidEmails)
                }
            }
        }
    }
    
    /// Signs  any signed in user out of Firebase Auth
    private static func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Not signed in")
        }
    }
}
