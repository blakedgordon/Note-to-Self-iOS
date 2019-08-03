//
//  EmailCell.swift
//  Email Note
//
//  Created by Blake Gordon on 7/15/19.
//  Copyright © 2019 Blake Gordon. All rights reserved.
//

import UIKit

class EmailCell: UITableViewCell {
    
    @IBOutlet var clearButton: UIButton!
    
    static func populateCell(firstCell: Bool, cell: EmailCell) -> EmailCell{
        cell.clearButton.isHidden = firstCell
        
        return cell
    }
}
