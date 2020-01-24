//
//  HistoryTableViewController.swift
//  Email Note
//
//  Created by Blake Gordon on 1/23/20.
//  Copyright © 2020 Blake Gordon. All rights reserved.
//

import UIKit

class HistoryTableViewController: UITableViewController {

    @IBAction func donePressed(_ sender: Any) {
        dismiss(animated: true)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Emails.sentEmails.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "sentCell", for: indexPath) as? SentEmailCell else {
            return UITableViewCell()
        }
        
        let email = Emails.sentEmails[indexPath.row]
        cell.populateCell(to: email.to, message: email.message, date: email.date)

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Deslect the row
        tableView.deselectRow(at: indexPath, animated: true)
        self.performSegue(withIdentifier: "showSentEmail", sender: indexPath)
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSentEmail" {
            if let destVC = segue.destination as? SentEmailViewController,
                let indexPath = sender as? IndexPath, let cell = tableView(self.tableView, cellForRowAt: indexPath)
                as? SentEmailCell {
                destVC.toEmailString = cell.toEmailLabel.text ?? ""
                destVC.messageString = cell.messageLabel.text ?? ""
                destVC.dateString = cell.dateLabel.text ?? ""
            }
        }
    }

}
