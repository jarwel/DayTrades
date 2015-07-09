//
//  FinanceClient.swift
//  DayTrades
//
//  Created by Jason Wells on 7/9/15.
//  Copyright (c) 2015 Jason Wells. All rights reserved.
//

import Foundation

class FinanceClient: NSObject {
    
    class func fetchQuotes(symbols: Set<String>, block: (NSURLResponse!, NSData!, NSError!) -> Void ) {
        let query: String = "select symbol, Name, LastTradePriceOnly, Change, ChangeinPercent, Open from yahoo.finance.quotes where symbol in ('" + "','".join(symbols) + "') and ErrorIndicationreturnedforsymbolchangedinvalid is not null and MarketCapitalization <> '0'"
        sendRequestToYQL(query, block: block);
    }
    
    class func fetchDayQuote(symbol: String, dayOfTrade: String, block: (NSURLResponse!, NSData!, NSError!) -> Void ) {
        let query: String = String(format: "select * from yahoo.finance.historicaldata where symbol = '%@' and startDate = '%@' and endDate = '%@'", symbol, dayOfTrade, dayOfTrade)
        sendRequestToYQL(query, block: block);
    }
    
    static func sendRequestToYQL(query: String, block: (NSURLResponse!, NSData!, NSError!) -> Void) {
        let encoded = query.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        let path: String = String(format: "http://query.yahooapis.com/v1/public/yql?q=%@&env=store://datatables.org/alltableswithkeys&format=json", encoded!)
        let url = NSURL(string: path)
        let request = NSURLRequest(URL: url!)
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: block)
    }

}