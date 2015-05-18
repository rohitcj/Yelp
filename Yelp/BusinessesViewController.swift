//
//  BusinessesViewController.swift
//  Yelp
//
//  Created by Rohit Jhangiani on 5/6/15.
//  Copyright (c) 2015 5TECH. All rights reserved.
//

import UIKit

class BusinessesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchControllerDelegate, FiltersViewControllerDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewActivityIndicator: UIActivityIndicatorView!
    
    var businesses: [Business]!
    var offset: Int = 0
    var yelpClient: YelpClient!
    var searchBar: UISearchBar!
    var searchFilters: Dictionary<String, String> = [:]
    var searchTerm: String = String()
    let defaultSearchTerm: String = "Restaurants"
    var defaults = NSUserDefaults.standardUserDefaults()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension // use as per autolayout rules
        tableView.estimatedRowHeight = 120 // for scroll bar & scroll height
        self.navigationItem.titleView = searchBarTitleView()
        
        // footer
        var tableFooterView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        var footerActivityIndicator: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        footerActivityIndicator.startAnimating()
        footerActivityIndicator.center = tableFooterView.center
        tableFooterView.addSubview(footerActivityIndicator)
        self.tableView.tableFooterView = tableFooterView
        
        loadDefaults()
        loadBusinesses(false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        saveDefaultSearchTerm()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if businesses != nil {
            return businesses!.count
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("BusinessCell", forIndexPath: indexPath) as! BusinessCell
        cell.business = businesses[indexPath.row]
        
        // load more
        if indexPath.row == businesses.count - 1 {
            loadBusinesses(true)
        }
        return cell
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }

    func searchBarTitleView() -> UIView {
        var containerViewWidth: CGFloat = 0.9 * self.view.frame.size.width
        var containerViewHeight: CGFloat = self.navigationController!.navigationBar.frame.size.height
        var searchBarWidth: CGFloat = UIScreen.mainScreen().bounds.width * 0.9
        var searchBarHeight: CGFloat = containerViewHeight
        var containerView =  UIView(frame: CGRectMake(0, 0, containerViewWidth, containerViewHeight))
        containerView.backgroundColor = UIColor.clearColor()
        containerView.autoresizingMask = UIViewAutoresizing.FlexibleWidth
        searchBar = UISearchBar(frame:CGRectMake(0.0, 0.0,searchBarWidth, searchBarHeight))
        searchBar.delegate = self
        searchBar.backgroundColor = UIColor.clearColor()
        searchBar.tintColor = UIColor.whiteColor()
        searchBar.autoresizingMask = UIViewAutoresizing.FlexibleWidth
        searchBar.placeholder = "E.g. tacos, Max's"
        searchBar.searchBarStyle = UISearchBarStyle.Minimal
        searchBar.setSearchFieldBackgroundImage(createImage(UIColor.whiteColor(), size: CGSize(width: 1, height: searchBar.frame.size.height * 0.6)), forState: UIControlState.Normal)
        containerView.addSubview(searchBar)
        return containerView
    }

    func createImage(color: UIColor, size: CGSize) -> UIImage {
        var rect = CGRectMake(0.0, 0.0, size.width, size.height)
        UIGraphicsBeginImageContext(rect.size)
        var context: CGContextRef = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextFillRect(context, rect)
        var image:UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    /*
    // MARK: - UISearchBarDelegate 
    */
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        //println("In searchBar textDidChange")
        searchBar.showsCancelButton = true;
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        //println("In searchBarSearchButtonClicked")
        self.searchTerm = searchBar.text
        searchBar.showsCancelButton = false
        searchBar.resignFirstResponder()
        processSearch(self.searchTerm, isSubsequentReload: false)
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        //println("In searchBarCancelButtonClicked")
        stopSearch()
    }
    
    // MARK: - Search Helpers
    
    func stopSearch() {
        searchBar.showsCancelButton = false
        searchBar.resignFirstResponder()
        self.resignFirstResponder()
    }
    
    func processSearch(searchTerm: String, filters: [String: AnyObject]?, sortMode: Int?, deals: Bool?, isSubsequentReload: Bool) {
        tableViewActivityIndicator.startAnimating()
        
        if !isSubsequentReload {
            self.offset = 0
        }
        
        var yelpSortMode: YelpSortMode?
        if var sortMode = sortMode {
            yelpSortMode = YelpSortMode(rawValue: sortMode)
        }
        
        var categories: [String]?
        if var filters = filters {
            categories = filters["categories"] as! [String]?
        }
        if self.searchTerm.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).isEmpty {
            self.searchTerm = defaultSearchTerm
        }
        //println("Search Term: \(searchTerm), Sort Mode: \(sortMode?.description), Categories: \(categories), Deals: \(deals)")
        
        var searchParameters : [String: AnyObject] = ["term": self.searchTerm, "limit": 20, "offset": self.offset]
        Business.searchWithParameters(searchParameters, term: self.searchTerm, sort: yelpSortMode, categories: categories, deals: deals) {
            (businesses: [Business]!, error: NSError!) ->
            Void in
            if error != nil {
                println("Error: \(error.description)")
                self.tableViewActivityIndicator.stopAnimating()
            }
            if let businesses = businesses {
                if businesses.count == 0 {
                    println("No businesses returned")
                    self.tableViewActivityIndicator.stopAnimating()
                }
            }
            if isSubsequentReload {
                for index in 0 ..< businesses.count {
                    self.businesses.append(businesses[index])
                    self.stopSearch()
                }
            }
            else {
                self.businesses = businesses
            }
            self.tableView.reloadData()
        
            if !isSubsequentReload {
                self.tableView.scrollRectToVisible(CGRectMake(0, 0, 1, 1), animated: true)
                // or self.tableView.scrollToNearestSelectedRowAtScrollPosition(UITableViewScrollPosition.Top, animated: true)
                // or self.tableView.scrollToRowAtIndexPath(NSIndexPath(index: 0), atScrollPosition: UITableViewScrollPosition.Top, animated: true)
            }
            self.offset += self.businesses.count
        }
        tableViewActivityIndicator.stopAnimating()
    }
    
    func processSearch(searchText: String, isSubsequentReload: Bool) {
        self.processSearch(searchText, filters: nil, sortMode: nil, deals: nil, isSubsequentReload: isSubsequentReload)
    }
    
    // MARK: - Misc. Helpers
    
    func loadBusinesses(isSubsequentReload: Bool) {
        self.processSearch(self.searchTerm, isSubsequentReload: isSubsequentReload)
    }
    
    func loadDefaults() {
        if var searchTermDefault = defaults.objectForKey(lastSearchTermKey) as? String {
            self.searchTerm = searchTermDefault
            self.searchBar.text = self.searchTerm
        }
    }
    
    func saveDefaultSearchTerm() {
        if !self.searchTerm.isEmpty {
            defaults.setObject(self.searchTerm, forKey: lastSearchTermKey)
            defaults.synchronize()
        }
    }

    // MARK: - FiltersViewControllerDelegate
    
    func filtersViewController(filtersViewController: FiltersViewController, didUpdateFilters filters: [String : AnyObject], sortMode: Int, deals: Bool) {
        self.searchTerm = searchBar.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        processSearch(self.searchTerm, filters: filters, sortMode: sortMode, deals: deals, isSubsequentReload: false)
    }
    
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let navigationController = segue.destinationViewController as! UINavigationController
        let filtersViewController = navigationController.topViewController as! FiltersViewController
        filtersViewController.delegate = self
    }
}
