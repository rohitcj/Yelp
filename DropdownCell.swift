//
//  DropdownCell.swift
//  Yelp
//
//  Created by Rohit Jhangiani on 5/15/15.
//  Copyright (c) 2015 5TECH. All rights reserved.
//

import UIKit

class DropdownCell: UITableViewCell {

    @IBOutlet weak var dropDownLabel: UILabel!
    @IBOutlet weak var dropdownButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
