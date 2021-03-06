//
//  LeadersViewController.swift
//  DayTrades
//
//  Created by Jason Wells on 7/12/15.
//  Copyright (c) 2015 Jason Wells. All rights reserved.
//

import Foundation

class LeadersViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    let headerHeight: CGFloat = 20
    let cellHeight: CGFloat = 44
    let cellIdentifier: String = "AccountCell"
    let numberFormatter: NSNumberFormatter = NSNumberFormatter()
    
    var accounts: Array<Account> = Array()
    var animated: Set<Account> = Set()

    override func viewDidLoad() {
        super.viewDidLoad()
        if let backgroundImage: UIImage = UIImage(named: "background-3.jpg") {
            view.backgroundColor = UIColor(patternImage: backgroundImage)
        }
        
        let accountCell = UINib(nibName: cellIdentifier, bundle: nil)
        tableView.registerNib(accountCell, forCellReuseIdentifier: cellIdentifier)
        
        segmentedControl.backgroundColor = UIColor.translucentColor()
        
        fetchAccounts(15, skip: 0, block: { (objects: [AnyObject]?, error: NSError?) -> Void in
            if let accounts: Array<Account> = objects as? Array<Account> {
                self.accounts = accounts
                self.tableView.reloadData()
            }
            self.enableInfiniteScroll()
        })
    }
    
    override func viewWillAppear(animated: Bool) {
        tableView.reloadData()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowAccountSegue" {
            let indexPath: NSIndexPath = tableView.indexPathForSelectedRow!
            if indexPath.row < accounts.count {
                let accountViewController: AccountViewController = segue.destinationViewController as! AccountViewController
                accountViewController.account = accounts[indexPath.row]
            }
        }
    }
    
    func refreshView() {
        tableView.reloadData()
    }
    
    func fetchAccounts(limit: Int, skip: Int, block: ([AnyObject]?, NSError?) -> Void) {
        let selectedIndex: Int = segmentedControl.selectedSegmentIndex
        if selectedIndex == 0 {
            ParseClient.fetchAccountsSortedByValue(limit, skip: skip, block: { (objects: [AnyObject]?, error: NSError?) -> Void in
                if self.segmentedControl.selectedSegmentIndex == selectedIndex {
                    block(objects, error)
                }
            })
        }
        else if selectedIndex == 1 {
            ParseClient.fetchAccountsSortedByWinners(limit, skip: skip, block: { (objects: [AnyObject]?, error: NSError?) -> Void in
                if self.segmentedControl.selectedSegmentIndex == selectedIndex {
                    block(objects, error)
                }
            })
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return accounts.count
        }
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: AccountCell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! AccountCell
        cell.resetView()
        
        if indexPath.section == 0 && indexPath.row < accounts.count {
            let account: Account = accounts[indexPath.row]
            switch indexPath.row {
            case 0:
                if segmentedControl.selectedSegmentIndex == 1 {
                    cell.awardImageView.image = UIImage(named: "ribbon-1.png")?.tintedWithBlueColor()
                }
                else {
                    cell.awardImageView.image = UIImage(named: "trophy-1.png")?.tintedWithGoldColor()
                }
            case 1:
                if segmentedControl.selectedSegmentIndex == 1 {
                    cell.awardImageView.image = UIImage(named: "ribbon-2.png")?.tintedWithRedColor()
                }
                else {
                    cell.awardImageView.image = UIImage(named: "trophy-2.png")?.tintedWithSilverColor()
                }
            case 2:
                if segmentedControl.selectedSegmentIndex == 1 {
                    cell.awardImageView.image = UIImage(named: "ribbon-3.png")?.tintedWithWhiteColor()
                }
                else {
                    cell.awardImageView.image = UIImage(named: "trophy-3.png")?.tintedWithBronzeColor()
                }
            default:
                cell.awardImageView.image = nil
            }
            cell.nameLabel.text = account.user.username
            cell.valueLabel.text = numberFormatter.currencyFromNumber(account.value)
            cell.picksBarView.total = account.winners + account.losers
            cell.picksBarView.value = account.winners
            if animated.contains(account) {
                cell.picksBarView.animate(0)
            }
            else {
                animated.insert(account)
                cell.picksBarView.animate(1.0)
            }
        }
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 1 {
            return max(1 + tableView.frame.size.height - headerHeight - (CGFloat(accounts.count) * cellHeight), 0)
        }
        return cellHeight
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Top Traders"
        }
        return nil
    }
    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerView: UITableViewHeaderFooterView = view as? UITableViewHeaderFooterView {
            headerView.contentView.backgroundColor = UIColor.darkGrayColor()
            headerView.textLabel?.textColor = UIColor.whiteColor()
            headerView.textLabel?.font = UIFont.boldSystemFontOfSize(15)
        }
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section > 0 {
            cell.userInteractionEnabled = false
        }
        else {
            cell.userInteractionEnabled = true
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 && indexPath.row < accounts.count {
            performSegueWithIdentifier("ShowAccountSegue", sender: nil)
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let y: CGFloat = tableView.contentSize.height - tableView.bounds.size.height + tableView.infiniteScrollingView.frame.size.height + 1
        if tableView.contentOffset.y >= y {
            tableView.contentOffset = CGPointMake(0, y)
        }
    }
    
    func enableInfiniteScroll() {
        tableView.addInfiniteScrollingWithActionHandler { () -> Void in
            let skip: Int = self.accounts.count
            self.fetchAccounts(10, skip: skip, block: { (objects: [AnyObject]?, error: NSError?) -> Void in
                if let accounts: Array<Account> = objects as? Array<Account> {
                    if accounts.count > 0 {
                        self.accounts += objects as! Array<Account>
                        self.tableView.reloadData()
                    }
                }
                self.tableView.infiniteScrollingView.stopAnimating()
            })
        }
        tableView.infiniteScrollingView.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.White
        tableView.infiniteScrollingView.backgroundColor = UIColor.translucentColor()
    }
    
    @IBAction func onValueChanged(sender: AnyObject) {
        accounts.removeAll()
        animated.removeAll()
        tableView.reloadData()
        fetchAccounts(15, skip: 0, block: { (objects: [AnyObject]?, error: NSError?) -> Void in
            if let accounts: Array<Account> = objects as? Array<Account> {
                self.accounts = accounts
                self.tableView.scrollRectToVisible(CGRectMake(0, 0, 1, 1), animated:false)
                self.tableView.reloadData()
            }
        })
    }
    
}