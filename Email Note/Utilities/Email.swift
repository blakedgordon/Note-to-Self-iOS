//
//  Email.swift
//  Email Note
//
//  Created by Blake Gordon on 1/23/20.
//  Copyright © 2020 Blake Gordon. All rights reserved.
//

import Foundation

class Email: Codable {
    var to: String
    var message: String
    var date: Date
    
    init(to: String, message: String, date: Date? = nil) {
        self.to = to
        self.message = message
        self.date = date ?? Date()
    }
}
