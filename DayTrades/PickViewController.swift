//
//  PickViewController.swift
//  DayTrades
//
//  Created by Jason Wells on 7/12/15.
//  Copyright (c) 2015 Jason Wells. All rights reserved.
//

import Foundation

@objc protocol PickViewControllerDelegate {
    func updateNextPick(pick: Pick)
}

class PickViewController: UIViewController, UISearchBarDelegate {
 
    weak var delegate: AnyObject?
    
    @IBOutlet weak var detailsView: UIView!
    @IBOutlet weak var securityView: UIView!
    @IBOutlet weak var detailsLabel: UILabel!
    @IBOutlet weak var dayOfTradeLabel: UILabel!
    @IBOutlet weak var symbolLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var changeLabel: UILabel!
    @IBOutlet weak var disclaimerLabel: UILabel!
    @IBOutlet weak var confirmButton: UIButton!
    
    let dateFormatter: NSDateFormatter = NSDateFormatter()
    let numberFormatter: NSNumberFormatter = NSNumberFormatter()
    
    var account: Account?
    var quote: Quote?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if navigationController != nil {
            navigationController!.navigationBar.barStyle = UIBarStyle.Black
            navigationController!.navigationBar.translucent = true
            navigationController!.navigationBar.tintColor = UIColor .whiteColor()
        }
        if let backgroundImage: UIImage = UIImage(named: "background-2.jpg") {
            view.backgroundColor = UIColor(patternImage: backgroundImage)
        }
        detailsView.backgroundColor = UIColor.translucentColor()
        securityView.backgroundColor = UIColor.translucentColor()
        refreshView()
    }
    
    func refreshView() {
        let dayOfTrade:String? = MarketHelper.nextDayOfTrade()
        if dayOfTrade != nil && quote != nil {
            if let dateFormat: String = dateFormatter.fullFromDayOfTrade(dayOfTrade!) {
                disclaimerLabel.text = "The listed security will be purchased for the full value of your account at the opening price and sold at market close on \(dateFormat)."
            }
            symbolLabel.text = quote?.symbol
            nameLabel.text = quote?.name
            priceLabel.text = numberFormatter.priceFromDouble(quote!.price)
            changeLabel.text = ChangeFormatter.stringFromQuote(quote!)
            changeLabel.textColor = UIColor.colorForChange(quote!.priceChange)
            detailsView.hidden = true
            securityView.hidden = false
        }
        else {
            detailsLabel.text = "Choose a security to buy on"
            dayOfTradeLabel.text = dayOfTrade
            securityView.hidden = true
            detailsView.hidden = false
        }
    }
    
    func searchBar(searchBar: UISearchBar, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        return count(searchBar.text) + count(text) - range.length <= 5;
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if !searchText .hasPrefix("^") {
            let symbols: Set<String> = ["\(searchText.uppercaseString )"]
            FinanceClient.fetchQuotesForSymbols(symbols, block:{ response, data, error in
                self.quote = nil
                if error == nil {
                    let quotes: Array<Quote> = Quote.fromData(data)
                    if let quote = quotes.first {
                        if quote.symbol == searchBar.text.uppercaseString {
                            self.quote = quote
                        }
                    }
                }
                else {
                    println("Error \(error) \(error.userInfo)")
                }
                self.refreshView()
            })
        }
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        view.endEditing(true)
    }
    
    @IBAction func onSubmitButtonClicked(sender: AnyObject) {
        let dayOfTrade: String? = MarketHelper.nextDayOfTrade()
        if dayOfTrade != nil && quote != nil && account != nil {
            let pick: Pick = Pick.newForAccount(account!, symbol: quote!.symbol, dayOfTrade: dayOfTrade!)
            ParseClient.createOrUpdatePick(pick, block: { (succeeded: Bool, error: NSError?) -> Void in
                self.delegate?.updateNextPick(pick)
                self.navigationController?.popViewControllerAnimated(true)
            })
            
        }
    }

    @IBAction func onTap(sender: AnyObject) {
        view.endEditing(true)
    }
    
}



