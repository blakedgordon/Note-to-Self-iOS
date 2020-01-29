//
//  SentEmailViewController.swift
//  Email Note
//
//  Created by Blake Gordon on 1/23/20.
//  Copyright © 2020 Blake Gordon. All rights reserved.
//

import UIKit

class SentEmailViewController: UIViewController {

    @IBOutlet weak var toEmailLabel: UILabel!
    @IBOutlet weak var messageLabel: UITextView!
    @IBOutlet weak var dateLabel: UILabel!
    
    var toEmailString: String = ""
    var messageString: String = ""
    var dateString: String = ""
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        toEmailLabel.text = toEmailString
        messageLabel.text = messageString
        dateLabel.text = dateString
    }
}
