//
//  FiltersViewController.swift
//  Yelp
//
//  Created by Rohit Jhangiani on 5/13/15.
//  Copyright (c) 2015 5TECH. All rights reserved.
//

import UIKit

@objc protocol FiltersViewControllerDelegate {
    optional func filtersViewController
        (filtersViewController: FiltersViewController,
        didUpdateFilters filters: [String: AnyObject], sortMode: Int, deals: Bool)
}

class FiltersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SwitchCellDelegate {

    @IBOutlet weak var filtersTableView: UITableView!
    
    weak var delegate: FiltersViewControllerDelegate?
    var sectionTitles: [String] = ["Most Popular", "Distance", "Sort By", "Category"]
    var numberOfRowsInSection: [Int] = [1, DistanceFilters.count, SortFilters.count, FilterCategories.count]
    var isExpandedSection: [Bool] = [false, false, false, false]
    var isOfferingADeal: Bool = false
    var distanceFilterSelectedRow: Int = 0
    var distanceFilterSelectedId: FilterValue = FilterValue(id: DistanceFilters[0].id, value: DistanceFilters[0].value)
    var sortFilterSelectedRow: Int = 0
    var sortFilterSelectedId: FilterValue = FilterValue(id: SortFilters[0].id, value: SortFilters[0].value)
    var categoriesFilterSwitchStates: Dictionary<String, Bool> = Dictionary<String, Bool>()
    var categoriesFilterSelectedList: [String] = [String]()
    var categoryMappings: Dictionary<String, String> = Dictionary<String, String>()
    var defaults = NSUserDefaults.standardUserDefaults()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.filtersTableView.dataSource = self
        self.filtersTableView.delegate = self
        self.filtersTableView.rowHeight = UITableViewAutomaticDimension // use as per autolayout rules
        self.filtersTableView.estimatedRowHeight = 45 // for scroll bar & scroll height
        self.filtersTableView.registerNib(UINib(nibName: "SwitchCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "SwitchCell")
        
        self.initCategories()
        self.loadDefaultFilters()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        saveDefaultFilters()
    }
    
    // MARK: - Bar button items / Actions
    
    @IBAction func onCancelButton(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func onSearchButton(sender: AnyObject) {
        saveDefaultFilters()
        dismissViewControllerAnimated(true, completion: nil)
        var filters = [String: AnyObject]()
        for (categoryName, categoryValue) in self.categoriesFilterSwitchStates {
            if categoryValue && self.categoryMappings[categoryName] != nil {
                self.categoriesFilterSelectedList.append(self.categoryMappings[categoryName]!)
            }
        }
        
        filters["categories"] = categoriesFilterSelectedList
        var sortMode: Int = self.sortFilterSelectedId.id.toInt()!
        delegate?.filtersViewController?(self, didUpdateFilters: filters, sortMode: sortMode, deals: self.isOfferingADeal)
    }
    
    // MARK: - NSUserDefaults helpers
    
    func loadDefaultFilters() {
        if var isOfferingADealDefault = defaults.objectForKey(lastOfferingADealFilterKey) as? Bool {
            self.isOfferingADeal = isOfferingADealDefault
        }
        
        if var distanceFilterSelectedRowDefault = defaults.objectForKey(lastDistanceFilterKey) as? Int {
            self.distanceFilterSelectedRow = distanceFilterSelectedRowDefault
            self.distanceFilterSelectedId = DistanceFilters[self.distanceFilterSelectedRow]
        }
        
        if var sortFilterSelectedRowDefault = defaults.objectForKey(lastSortFilterKey) as? Int {
            self.sortFilterSelectedRow = sortFilterSelectedRowDefault
            self.sortFilterSelectedId = SortFilters[self.sortFilterSelectedRow]
        }
        
        if var categoriesFilterSwitchStatesDefault = defaults.objectForKey(lastCategoriesFilterKey) as? Dictionary<String, Bool> {
            self.categoriesFilterSwitchStates = categoriesFilterSwitchStatesDefault
        }
    }
    
    func saveDefaultFilters() {
        defaults.setObject(self.isOfferingADeal, forKey: lastOfferingADealFilterKey)
        defaults.setObject(self.distanceFilterSelectedRow, forKey: lastDistanceFilterKey)
        defaults.setObject(self.sortFilterSelectedRow, forKey: lastSortFilterKey)
        defaults.setObject(self.categoriesFilterSwitchStates, forKey: lastCategoriesFilterKey)
        defaults.synchronize()
    }
    
    func initCategories() {
        for index in 0 ..< FilterCategories.count {
            var categoryName = (FilterCategories[index] as Dictionary)["name"]!
            var categoryCode = (FilterCategories[index] as Dictionary)["code"]!
            self.categoryMappings[categoryName] = categoryCode
        }
    }
    
    // MARK: - Table View Delegate

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sectionTitles[section]
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.isExpandedSection[section] == false {
            if section == 3 {
                return 4 // 3 categories + See All row
            }
            else {
                return 1
            }
        }
        return self.numberOfRowsInSection[section]
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("SwitchCell") as! SwitchCell
            cell.switchLabel.text = "Offering a deal"
            cell.yelpSwitch.on = self.isOfferingADeal
            cell.yelpSwitch.addTarget(self, action: "didUpdateDealsSwitch:", forControlEvents: UIControlEvents.ValueChanged)
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCellWithIdentifier("DropdownCell") as! DropdownCell
            if indexPath.section == 1 {
                cell.dropDownLabel.text = DistanceFilters[indexPath.row].value
                if indexPath.row == 0 {
                    if self.isExpandedSection[indexPath.section] {
                        cell.dropDownLabel.text = DistanceFilters[0].value
                        if self.distanceFilterSelectedId.value == DistanceFilters[0].value {
                            cell.dropdownButton.setBackgroundImage(UIImage(named: "Selected"), forState: UIControlState.Normal)
                        } else {
                            cell.dropdownButton.setBackgroundImage(UIImage(named: "Unselected"), forState: UIControlState.Normal)
                        }
                    }
                    else {
                        cell.dropDownLabel.text = self.distanceFilterSelectedId.value
                        cell.dropdownButton.setBackgroundImage(UIImage(named: "Dropdown"), forState: UIControlState.Normal)
                    }
                } else {
                    if self.distanceFilterSelectedRow == indexPath.row {
                        cell.dropdownButton.setBackgroundImage(UIImage(named: "Selected"), forState: UIControlState.Normal)
                    } else {
                        cell.dropdownButton.setBackgroundImage(UIImage(named: "Unselected"), forState: UIControlState.Normal)
                    }
                    if self.isExpandedSection[1] == false {
                        cell.hidden = true
                    }
                  }
            return cell
            } else if indexPath.section == 2 {
                cell.dropDownLabel.text = SortFilters[indexPath.row].value
                if indexPath.row == 0 {
                    if self.isExpandedSection[indexPath.section] {
                        cell.dropDownLabel.text = SortFilters[0].value
                        if self.sortFilterSelectedId.value == SortFilters[0].value {
                            cell.dropdownButton.setBackgroundImage(UIImage(named: "Selected"), forState: UIControlState.Normal)
                        } else {
                            cell.dropdownButton.setBackgroundImage(UIImage(named: "Unselected"), forState: UIControlState.Normal)
                        }
                    }
                    else {
                        cell.dropDownLabel.text = self.sortFilterSelectedId.value
                        cell.dropdownButton.setBackgroundImage(UIImage(named: "Dropdown"), forState: UIControlState.Normal)
                    }
                } else {
                    if self.sortFilterSelectedRow == indexPath.row {
                        cell.dropdownButton.setBackgroundImage(UIImage(named: "Selected"), forState: UIControlState.Normal)
                    } else {
                        cell.dropdownButton.setBackgroundImage(UIImage(named: "Unselected"), forState: UIControlState.Normal)
                    }
                    if self.isExpandedSection[2] == false {
                        cell.hidden = true
                    }
                }
            return cell
            } else if indexPath.section == 3 {
                var defaultFont = UIFont.systemFontOfSize(14.0)
                let cell = tableView.dequeueReusableCellWithIdentifier("SwitchCell") as! SwitchCell
                cell.delegate = self
                if self.isExpandedSection[indexPath.section] {
                    var categoryName = (FilterCategories[indexPath.row] as Dictionary)["name"]
                    cell.switchLabel.text = categoryName
                    cell.switchLabel.font = defaultFont
                    cell.yelpSwitch.hidden = false
                    if self.categoriesFilterSwitchStates[categoryName!] != nil {
                        cell.yelpSwitch.on = self.categoriesFilterSwitchStates[categoryName!]!
                    }
                    else {
                        cell.yelpSwitch.on = false
                    }
                }
                else { // if not expanded
                    
                    if indexPath.row == 3 {
                        cell.switchLabel.text = "See All"
                        cell.switchLabel.font = UIFont.boldSystemFontOfSize(14.0)
                        cell.yelpSwitch.hidden = true
                        return cell
                    }
                    if indexPath.row >= 4 {
                        hideUnhideRow(indexPath.section, row: indexPath.row, hidden: true)
                     }
                    var categoryName = (FilterCategories[indexPath.row] as Dictionary)["name"]
                    cell.switchLabel.text = categoryName
                    defaultFont = cell.switchLabel.font
                    if self.categoriesFilterSwitchStates[categoryName!] != nil {
                        cell.yelpSwitch.on = self.categoriesFilterSwitchStates[categoryName!]!
                    }
                    else {
                        cell.yelpSwitch.on = false
                    }
                }
              return cell
            }
            return cell
        }
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var selectedSection: Int = indexPath.section
        var selectedRow: Int = indexPath.row
        var previousSelectedRow: Int = 0
        
        // sections & rows that dont need to be processed
        if selectedSection == 0 {
            self.filtersTableView.deselectRowAtIndexPath(indexPath, animated: true)
            return
        }
        
        if selectedSection == 3 && self.isExpandedSection[selectedSection] {
            self.filtersTableView.deselectRowAtIndexPath(indexPath, animated: true)
            return
        }
        
        if selectedSection == 3 && !self.isExpandedSection[selectedSection] && selectedRow != 3 { // except the see all row
            self.filtersTableView.deselectRowAtIndexPath(indexPath, animated: true)
            return
        }
        
        // if the first row of a section is selected, select the first value & set expanded = true
        if selectedSection > 0 {
            if selectedRow == 0 {
                if self.isExpandedSection[selectedSection] == false { // && if the section is not expanded
                    hideUnhideRows(selectedSection, hidden: false)
                    self.isExpandedSection[selectedSection] = true
                    var selectedCell: DropdownCell = self.filtersTableView.cellForRowAtIndexPath(NSIndexPath(forRow: selectedRow, inSection: selectedSection)) as! DropdownCell
                    
                    if selectedSection == 1 {
                        selectedCell.dropDownLabel.text = DistanceFilters[indexPath.row].value
                    } else if selectedSection == 2 {
                        selectedCell.dropDownLabel.text = SortFilters[indexPath.row].value
                    }
                }
                else { // && if the section is already expanded
                    if selectedSection == 1 {
                        previousSelectedRow = self.distanceFilterSelectedRow
                        self.distanceFilterSelectedRow = selectedRow
                        self.distanceFilterSelectedId = DistanceFilters[selectedRow]
                    } else if selectedSection == 2 {
                        previousSelectedRow = self.sortFilterSelectedRow
                        self.sortFilterSelectedRow = selectedRow
                        self.sortFilterSelectedId = SortFilters[selectedRow]
                    }
                
                    setSelectedUnselectedImages(previousSelectedRow, currentSelectedRow: selectedRow, currentSection: selectedSection)
                    hideUnhideRows(selectedSection, hidden: true)
                    self.isExpandedSection[selectedSection] = false
                }

            } else { // if selectedRow > 0
                if selectedSection == 1 {
                    self.isExpandedSection[selectedSection] = false
                    previousSelectedRow = self.distanceFilterSelectedRow
                    self.distanceFilterSelectedRow = selectedRow
                    self.distanceFilterSelectedId = DistanceFilters[selectedRow]
                    var selectedCell: DropdownCell = self.filtersTableView.cellForRowAtIndexPath(NSIndexPath(forRow: selectedRow, inSection: selectedSection)) as! DropdownCell
                    selectedCell.dropDownLabel.text = self.distanceFilterSelectedId.value
                    selectedCell.dropdownButton.setBackgroundImage(UIImage(named: "Dropdown"), forState: UIControlState.Normal)
                    setSelectedUnselectedImages(previousSelectedRow, currentSelectedRow: selectedRow, currentSection: selectedSection)
                    hideUnhideRows(selectedSection, hidden: true)
                    self.isExpandedSection[selectedSection] = false
                } else if selectedSection == 2 {
                    self.isExpandedSection[selectedSection] = false
                    previousSelectedRow = self.sortFilterSelectedRow
                    self.sortFilterSelectedRow = selectedRow
                    self.sortFilterSelectedId = SortFilters[selectedRow]
                    var selectedCell: DropdownCell = self.filtersTableView.cellForRowAtIndexPath(NSIndexPath(forRow: selectedRow, inSection: selectedSection)) as! DropdownCell
                    selectedCell.dropDownLabel.text = self.sortFilterSelectedId.value
                    selectedCell.dropdownButton.setBackgroundImage(UIImage(named: "Dropdown"), forState: UIControlState.Normal)
                    setSelectedUnselectedImages(previousSelectedRow, currentSelectedRow: selectedRow, currentSection: selectedSection)
                    hideUnhideRows(selectedSection, hidden: true)
                    self.isExpandedSection[selectedSection] = false
                }
                  else if selectedSection == 3 {
                    if self.isExpandedSection[selectedSection] {
                        return
                    }
                    if !self.isExpandedSection[selectedSection] {
                        if selectedRow != 3 {
                            return
                        }
                        self.isExpandedSection[selectedSection] = true
                    }
                }
            }
            
            self.filtersTableView.reloadData()
            self.filtersTableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
    }
    
    // MARK: - Misc. Helpers
    
    func hideUnhideRows(section: Int, hidden: Bool) {
        for index in 1 ..< (self.numberOfRowsInSection[section]) {
            filtersTableView.cellForRowAtIndexPath(NSIndexPath(forRow: index, inSection: section))?.hidden = hidden
        }
    }
    
    func hideUnhideRow(section: Int, row: Int, hidden: Bool) {
        filtersTableView.cellForRowAtIndexPath(NSIndexPath(forRow: row, inSection: section))?.hidden = hidden
    }
    
    func setSelectedUnselectedImages(previousSelectedRow: Int, currentSelectedRow: Int, currentSection: Int) {
        if previousSelectedRow != 0 {
            let  previousCell = self.filtersTableView.cellForRowAtIndexPath(NSIndexPath(forRow: previousSelectedRow, inSection: currentSection)) as! DropdownCell
            previousCell.dropdownButton.setBackgroundImage(UIImage(named: "Unselected"), forState: UIControlState.Normal)
        }
        
        if currentSelectedRow != 0 {
            let currentCell = self.filtersTableView.cellForRowAtIndexPath(NSIndexPath(forRow: currentSelectedRow, inSection: currentSection)) as! DropdownCell
            currentCell.dropdownButton.setBackgroundImage(UIImage(named: "Selected"), forState: UIControlState.Normal)
        }
    }
    
    @IBAction func didUpdateDealsSwitch(sender: AnyObject) {
        self.isOfferingADeal = (sender as! CustomSwitch).on
    }
    
    // MARK: - SwitchCellDelegate
    
    func switchCell(switchCell: SwitchCell, didChangeValue value: Bool) {
        var categoryName: String = switchCell.switchLabel.text!
        self.categoriesFilterSwitchStates[categoryName] = value
    }
}
