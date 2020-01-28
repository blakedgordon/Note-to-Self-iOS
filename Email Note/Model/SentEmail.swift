//
//  SentEmail.swift
//  Email Note
//
//  Created by Blake Gordon on 1/23/20.
//  Copyright © 2020 Blake Gordon. All rights reserved.
//

import Foundation

/// An email that has been sent by the user so that the user can view a history
/// of all their emails
class SentEmail: Codable {
    /// Who the email was sent to
    var to: String
    
    /// What was in the email
    var message: String
    
    /// When the email was sent
    var date: Date
    
    /// Initialize a sent email
    /// - Parameters:
    ///   - to: Who the email was sent to
    ///   - message: What the email said
    ///   - date: The date the email was sent
    init(to: String, message: String, date: Date? = nil) {
        self.to = to
        self.message = message
        self.date = date ?? Date()
    }
}
