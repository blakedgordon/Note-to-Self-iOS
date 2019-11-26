//
//  User.swift
//  Email Note
//
//  Created by Blake Gordon on 12/11/18.
//  Copyright © 2018 Blake Gordon. All rights reserved.
//

import Foundation
import FirebaseAuth

class User {
    static var mainEmail: String {
        get {
            if let emails = UserDefaults.standard.array(forKey: "email") as? [String] {
                return emails.first ?? ""
            }
            return ""
        }
        set {
            self.emails[0] = newValue
        }
    }
    static var emails: [String] {
        get {
            let array = UserDefaults.standard.array(forKey: "email") as? [String] ?? [""]
            return (User.purchasedPro) ? Array(array.prefix(5)) : [self.mainEmail]
        }
        set {
            UserDefaults.standard.set(Array(newValue.prefix(5)), forKey: "email")
        }
    }
    
    static var purchasedPro: Bool {
        get {
            return (UserDefaults.standard.bool(forKey: NoteToSelfPro.proProductKey) &&
                (NoteToSelfPro.expireDate > Date() || NoteToSelfPro.expireDateCode > Date()))
        }
        set {
            UserDefaults.standard.set(newValue, forKey: NoteToSelfPro.proProductKey)
        }
    }
    
    static var darkMode: Bool {
        get {
            return (User.purchasedPro && UserDefaults.standard.bool(forKey: "darkMode"))
        }
        set {
            if UserDefaults.standard.bool(forKey: NoteToSelfPro.proProductKey) && User.purchasedPro {
                UserDefaults.standard.set(newValue, forKey: "darkMode")
            } else {
                UserDefaults.standard.set(false, forKey: "darkMode")
            }
        }
    }
    
    static var emailsValidated: [String: Bool] {
        get {
            return UserDefaults.standard.object(forKey: "validatedEmails") as? [String: Bool] ?? ["": false]
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "validatedEmails")
        }
    }
    
    static func isValidEmail(_ testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    
    static func isEmailValidated(_ emailRaw: String, completionHandler: @escaping (_ verified: Bool?, _ verificationSent: Bool?) -> ()) {
        let validSet = Set(self.emailsValidated.keys)
        let email = emailRaw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if containsCaseInsensitive(email, Array(validSet)) {
            completionHandler(true, nil)
            return
        }
        if !isValidEmail(email) {
            completionHandler(nil, nil)
            return
        }
        Auth.auth().fetchSignInMethods(forEmail: email) { (providers, error) in
            if let prov = providers, prov.count > 0 {
                Auth.auth().signIn(withEmail: email, password: email, completion: { (result, error) in
                    if let user = result?.user, user.isEmailVerified {
                        completionHandler(true, nil)
                        emailsValidated[email] = true
                    } else {
                        completionHandler(false, nil)
                    }
                    self.signOut()
                })
            } else {
                Auth.auth().createUser(withEmail: email, password: email, completion: { (result, error) in
                    result?.user.sendEmailVerification(completion: { (error) in
                        completionHandler(false, error == nil)
                    })
                    self.signOut()
                })
            }
        }
    }
    
    static func validateRequest(rawEmail: String) {
        let email = rawEmail.lowercased()
        Auth.auth().fetchSignInMethods(forEmail: email) { (providers, error) in
            if let prov = providers, prov.count > 0 {
                Auth.auth().signIn(withEmail: email, password: email, completion: { (result, error) in
                    result?.user.sendEmailVerification(completion: nil)
                    self.signOut()
                })
            } else {
                Auth.auth().createUser(withEmail: email, password: email, completion: { (result, error) in
                    result?.user.sendEmailVerification(completion: nil)
                    self.signOut()
                })
            }
        }
    }
    
    static func validatedEmails(completionHandler: @escaping ([String]) -> ()) {
        var invalidEmails = [String]()
        let emailsSet = Set(self.emails)
        let validSet = Set(self.emailsValidated.keys)
        if User.isSubsetCaseInsensitive(emailsSet, validSet) {
            completionHandler(invalidEmails)
            return
        }
        for (index, emailRaw) in self.emails.enumerated() {
            let email = emailRaw.lowercased()
            Auth.auth().fetchSignInMethods(forEmail: email) { (providers, error) in
                if let prov = providers, prov.count > 0 {
                    Auth.auth().signIn(withEmail: email, password: email, completion: { (result, error) in
                        invalidEmails = self.verified(verified: (result?.user.isEmailVerified ?? false),
                                                      email: email,
                                                      invalidEmails: invalidEmails)
                        if index == self.emails.count - 1 {
                            completionHandler(invalidEmails)
                        }
                    })
                } else {
                    Auth.auth().createUser(withEmail: email, password: email, completion: { (result, error) in
                        result?.user.sendEmailVerification(completion: nil)
                        invalidEmails = self.verified(verified: (result?.user.isEmailVerified ?? false),
                                                      email: email,
                                                      invalidEmails: invalidEmails)
                        if index == self.emails.count - 1 {
                            completionHandler(invalidEmails)
                        }
                    })
                }
            }
        }
    }
    
    private static func verified(verified: Bool, email: String, invalidEmails: [String]) -> [String] {
        var emailsVar = invalidEmails
        if !verified {
            emailsVar.append(email)
        } else {
            emailsValidated[email.lowercased()] = true
        }
        self.signOut()
        return emailsVar
    }
    
    private static func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Not signed in")
        }
    }
    
    static func containsCaseInsensitive(_ string: String, _ array: [String]) -> Bool {
        for a in array {
            if a.lowercased() == string.lowercased() {
                return true
            }
        }
        return false
    }
    
    static func isSubsetCaseInsensitive(_ array1: Set<String>, _ array2: Set<String>) -> Bool {
        var set1 = Set<String>()
        for s in array1 {
            set1.insert(s.lowercased())
        }
        var set2 = Set<String>()
        for s in array2 {
            set2.insert(s.lowercased())
        }
        
        return set1.isSubset(of: set2)
    }
}
