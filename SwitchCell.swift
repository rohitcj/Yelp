//
//  SwitchCell.swift
//  Yelp
//
//  Created by Rohit Jhangiani on 5/15/15.
//  Copyright (c) 2015 5TECH. All rights reserved.
//

import UIKit

@objc protocol SwitchCellDelegate {
    optional func switchCell(switchCell: SwitchCell, didChangeValue value: Bool)
}

class SwitchCell: UITableViewCell {

    @IBOutlet weak var switchLabel: UILabel!
    @IBOutlet var yelpSwitch: CustomSwitch!
    weak var delegate: SwitchCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        yelpSwitch = CustomSwitch(frame: CGRectMake(240, 20, 70, 32))
        yelpSwitch.thumbImage = UIImage(named: "Yelp")
        yelpSwitch.shadowColor = UIColor.lightGrayColor()
        yelpSwitch.thumbTintColor = UIColor.lightGrayColor()
        yelpSwitch.thumbImageView.tintColor = UIColor.lightGrayColor()
        yelpSwitch.onLabel.textColor = UIColor.whiteColor()
        yelpSwitch.onLabel.text = "ON"
        yelpSwitch.offLabel.text = "OFF"
        yelpSwitch.onTintColor = UIColor.magentaColor()
        yelpSwitch.onThumbTintColor = UIColor.lightGrayColor()
        yelpSwitch.center.y = self.center.y
        yelpSwitch.center.x = self.center.x - 25
        yelpSwitch.sizeToFit()
        yelpSwitch.addTarget(self, action: "switchValueChanged", forControlEvents: UIControlEvents.ValueChanged)
        self.addSubview(yelpSwitch)
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func switchValueChanged() {
        delegate?.switchCell?(self, didChangeValue: self.yelpSwitch.on)
    }
}
