//
//  PickViewController.swift
//  DayTrades
//
//  Created by Jason Wells on 7/12/15.
//  Copyright (c) 2015 Jason Wells. All rights reserved.
//

import Foundation

@objc protocol PickViewControllerDelegate {
    func updateNextPick(pick: Pick?)
}

class PickViewController: UIViewController, UISearchBarDelegate {
    
    @IBOutlet weak var detailsView: UIView!
    @IBOutlet weak var securityView: UIView!
    @IBOutlet weak var detailsLabel: UILabel!
    @IBOutlet weak var dayOfTradeLabel: UILabel!
    @IBOutlet weak var symbolLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var disclaimerLabel: UILabel!
    @IBOutlet weak var confirmButton: UIButton!
    
    let disabledSymbols: NSArray = NSBundle.mainBundle().objectForInfoDictionaryKey("Disabled symbols") as! NSArray
    let dateFormatter: NSDateFormatter = NSDateFormatter()
    let numberFormatter: NSNumberFormatter = NSNumberFormatter()
    
    var delegate: PickViewControllerDelegate?
    var account: Account?
    var quote: Quote?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let backgroundImage: UIImage = UIImage(named: "background-2.jpg") {
            view.backgroundColor = UIColor(patternImage: backgroundImage)
        }
        detailsView.backgroundColor = UIColor.translucentColor()
        securityView.backgroundColor = UIColor.translucentColor()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        refreshView()
    }
    
    func refreshView() {
        let dayOfTrade: String = MarketHelper.nextDayOfTrade()
        let text: String? = dateFormatter.fullTextFromDayOfTrade(dayOfTrade)
        if let quote: Quote = quote {
            disclaimerLabel.text = "The listed security will be purchased for the full value of your account at the opening price and sold at market close on \(text!)."
            symbolLabel.text = quote.symbol
            nameLabel.text = quote.name
            priceLabel.text = numberFormatter.priceFromNumber(NSNumber(double: quote.price))
            detailsView.hidden = true
            securityView.hidden = false
        }
        else {
            detailsLabel.text = "Choose a security to buy on"
            dayOfTradeLabel.text = text!
            securityView.hidden = true
            detailsView.hidden = false
        }
    }
    
    func searchBar(searchBar: UISearchBar, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        return count(searchBar.text) + count(text) - range.length <= 5;
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if !searchText .hasPrefix("^") && !disabledSymbols.containsObject(searchText.uppercaseString){
            let symbols: Set<String> = ["\(searchText.uppercaseString)"]
            FinanceClient.fetchQuotesForSymbols(symbols, block: { (response: NSURLResponse!, data: NSData!, error: NSError!) -> Void in
                self.quote = nil
                if let data: NSData = data {
                    let quotes: Array<Quote> = Quote.fromData(data)
                    if let quote = quotes.first {
                        if quote.symbol == searchBar.text.uppercaseString {
                            self.quote = quote
                        }
                    }
                }
                if let error: NSError = error {
                    println("Error \(error) \(error.userInfo)")
                }
                self.refreshView()
            })
        }
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        view.endEditing(true)
    }
    
    @IBAction func onSubmitButtonPressed(sender: AnyObject) {
        if let account: Account = self.account {
            if let quote: Quote = self.quote {
                let dayOfTrade: String = MarketHelper.nextDayOfTrade()
                let pick: Pick = Pick(account: account, symbol: quote.symbol!, dayOfTrade: dayOfTrade)
                ParseClient.createOrUpdatePick(pick, block: { (succeeded: Bool, error: NSError?) -> Void in
                    self.delegate?.updateNextPick(pick)
                    self.navigationController?.popViewControllerAnimated(true)
                })
            }
        }
    }

    @IBAction func onTap(sender: AnyObject) {
        view.endEditing(true)
    }
    
}



