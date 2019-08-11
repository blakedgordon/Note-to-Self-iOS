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
        
        self.darkMode(on: User.darkMode)
    }
    
    func darkMode(on: Bool) {
        self.view.backgroundColor = (on) ? .black : .groupTableViewBackground
        self.tableView.separatorColor = (on) ? .black : .lightGray
        self.navigationController?.navigationBar.barStyle = (on) ? .black : .default
        self.navigationController?.view.backgroundColor = (on) ? .black : .white
        self.navigationController?.navigationBar.titleTextAttributes =
            (on) ? [.foregroundColor: UIColor.white] : [.foregroundColor: UIColor.black]
        versionDescriptionLabel.textColor = (on) ? .white : .black
        buildDescriptionLabel.textColor = (on) ? .white : .black
        versionLabel.textColor = (on) ? .lightGray : .gray
        buildLabel.textColor = (on) ? .lightGray : .gray
        
        tableView.separatorColor = (on) ? UIColor(red: 60/255, green: 60/255, blue: 60/255, alpha: 1) : UITableView().separatorColor
        for i in (0..<tableView.numberOfSections) {
            self.tableView.headerView(forSection: i)?.backgroundView?.backgroundColor = (on) ? .black :
                .groupTableViewBackground
            self.tableView.footerView(forSection: i)?.backgroundView?.backgroundColor = (on) ? .black :
                .groupTableViewBackground
            for row in 0..<tableView.numberOfRows(inSection: i) {
                if let cell = tableView.cellForRow(at: IndexPath(row: row, section: i)) {
                    cell.backgroundColor = (on) ? UIColor(red: 35/255, green: 35/255, blue: 35/255, alpha: 1) : .white
                }
            }
        }
    }

}
