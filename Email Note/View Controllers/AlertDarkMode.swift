//
//  AlertDarkMode.swift
//  Email Note
//
//  Created by Blake Gordon on 12/12/18.
//  Copyright © 2018 Blake Gordon. All rights reserved.
//

import UIKit

extension UIViewController {
    func presentAlert(title: String, message: String, actions: [UIAlertAction]) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        for action in actions {
            alert.addAction(action)
        }
        self.present(alert, animated: true, completion: nil)
    }
}
