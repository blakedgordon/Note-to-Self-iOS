//
//  AboutTableViewController.swift
//  Email Note
//
//  Created by Blake Gordon on 8/11/19.
//  Copyright © 2019 Blake Gordon. All rights reserved.
//

import UIKit

class AboutTableViewController: UITableViewController {

    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var versionDescriptionLabel: UILabel!
    @IBOutlet weak var buildLabel: UILabel!
    @IBOutlet weak var buildDescriptionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let versionNumber = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
            let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            versionLabel.text = versionNumber
            buildLabel.text = buildNumber
        }
    }

}
