//
//  AlertDarkMode.swift
//  Email Note
//
//  Created by Blake Gordon on 12/12/18.
//  Copyright © 2018 Blake Gordon. All rights reserved.
//

import UIKit

extension UIViewController {
    func presentDarkAlert(title: String, message: String, actions: [UIAlertAction], darkMode: Bool) {
        let titleString = NSAttributedString(string: title, attributes:
            [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16),
             .foregroundColor: (darkMode) ? UIColor.white : UIColor.black])
        let messageString = NSAttributedString(string: message, attributes:
            [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14),
             .foregroundColor: (darkMode) ? UIColor.white : UIColor.black])
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.setValue(titleString, forKey: "attributedTitle")
        alert.setValue(messageString, forKey: "attributedMessage")
        
        for action in actions {
            alert.addAction(action)
        }
        
        self.setDark(alert: alert, darkModeOn: darkMode)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func setDark(alert: UIAlertController, darkModeOn: Bool) {
        // Change UIAlert to dark mode
        // found at: https://stackoverflow.com/questions/28500262/setting-background-color-for-uialertcontroller-in-swift
        if let subview = (alert.view.subviews.first?.subviews.first?.subviews.first), darkModeOn {
            subview.backgroundColor = UIColor(red: 25/255, green: 25/255, blue: 25/255, alpha: 1)
        }
    }
}
