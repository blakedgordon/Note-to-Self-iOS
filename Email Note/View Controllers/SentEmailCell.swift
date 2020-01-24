//
//  SentEmailCell.swift
//  Email Note
//
//  Created by Blake Gordon on 1/23/20.
//  Copyright © 2020 Blake Gordon. All rights reserved.
//

import UIKit

class SentEmailCell: UITableViewCell {

    @IBOutlet weak var toEmailLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    func populateCell(to: String, message: String, date: Date) {
        toEmailLabel.text = to
        messageLabel.text = message
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        dateLabel.text = dateFormatter.string(from: date)
    }

}
