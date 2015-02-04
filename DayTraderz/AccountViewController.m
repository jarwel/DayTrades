//
//  AccountViewController.m
//  DayTraderz
//
//  Created by Jason Wells on 1/9/15.
//  Copyright (c) 2015 Jason Wells. All rights reserved.
//

#import "AccountViewController.h"
#import "AppConstants.h"
#import "ParseClient.h"
#import "FinanceClient.h"
#import "PicksViewController.h"
#import "Account.h"
#import "Quote.h"
#import "DayQuote.h"
#import "PickCell.h"

@interface AccountViewController () <PicksViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;
@property (weak, nonatomic) IBOutlet UILabel *nextPickLabel;

@property (strong, nonatomic) Account *account;
@property (strong, nonatomic) Pick *nextPick;
@property (strong, nonatomic) Pick *currentPick;
@property (strong, nonatomic) NSMutableArray *picks;
@property (strong, nonatomic) NSMutableDictionary *quotes;

@end

@implementation AccountViewController

static NSString * const cellIdentifier = @"PickCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.picks = [[NSMutableArray alloc] init];
    self.quotes = [[NSMutableDictionary alloc ] init];
    
    UINib *userCell = [UINib nibWithNibName:cellIdentifier bundle:nil];
    [self.tableView registerNib:userCell forCellReuseIdentifier:cellIdentifier];
    
    [[ParseClient instance] fetchAccountForUser:PFUser.currentUser callback:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.account = objects[0];
            [[ParseClient instance] fetchPicksForAccount:self.account callback:^(NSArray *objects, NSError *error) {
                if (!error) {
                    [self updateViewsWithObjects:objects];
                }
            }];
        }
    }];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"Current";
    }
    return @"Past";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    }
    return self.picks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PickCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    if (indexPath.section == 0 && self.currentPick) {
        cell.dateLabel.text = [self formatFromTradeDate:self.currentPick.tradeDate];
        cell.symbolLabel.text = self.currentPick.symbol;
    }
    
    if (indexPath.section == 1) {
        Pick* pick = [self.picks objectAtIndex:indexPath.row];
        cell.dateLabel.text = [self formatFromTradeDate:pick.tradeDate];
        cell.symbolLabel.text = pick.symbol;
        
        NSString *key = [NSString stringWithFormat:@"%@-%@", pick.symbol, pick.tradeDate];
        DayQuote *quote = [self.quotes objectForKey:key];
        cell.buyLabel.text = [NSString stringWithFormat:@"%0.02f Buy", quote.open];
        cell.sellLabel.text = [NSString stringWithFormat:@"%0.02f Sell", quote.close];
        cell.changeLabel.text = [self formatChangeFromQuote:quote];
    }
    
    return cell;
}

- (void)pickFromController:(Pick *)pick {
    self.nextPick = pick;
    [self.tableView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"ShowPicksSegue"]) {
        PicksViewController *picksViewController = segue.destinationViewController;
        picksViewController.delegate = self;
        picksViewController.account = self.account;
    }
}

- (BOOL)isCurrentPick:(Pick *) pick {
    if (pick) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd"];
        NSString* today = [formatter stringFromDate:[NSDate date]];
        if ([today isEqualToString:pick.tradeDate]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isNextPick:(Pick *) pick {
    if (pick) {
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDate* date = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:[NSDate date] options:0];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd"];
        NSString* today = [formatter stringFromDate:date];
        if ([today isEqualToString:pick.tradeDate]) {
            return YES;
        }
    }
    return NO;
}

- (NSString *)formatFromTradeDate:(NSString *)tradeDate {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSDate* date = [formatter dateFromString:tradeDate];
    [formatter setDateFormat:@"MM-dd-yyyy"];
    return [formatter stringFromDate:date];
}

- (NSString *)formatChangeFromQuote:(DayQuote *)quote {
    float priceChange = quote.close - quote.open;
    float percentChange = priceChange / quote.open;
    NSString *priceChangeFormat = [NSString stringWithFormat:@"%+0.2f", priceChange];
    NSString *percentChangeFormat = [NSString stringWithFormat:@"%+0.2f%%", percentChange];
    return [NSString stringWithFormat:@"%@ (%@)", priceChangeFormat, percentChangeFormat];
}

- (void)updateViewsWithObjects:(NSArray *)objects {
    [self.picks removeAllObjects];
    
    float value = self.account.value;
    for (Pick* pick in objects) {
        if ([self isNextPick:pick]) {
            self.nextPick = pick;
        }
        else if ([self isCurrentPick:pick]) {
            self.currentPick = pick;
        }
        else {
            [self.picks addObject:pick];
            [[FinanceClient instance] fetchQuoteForSymbol:pick.symbol onDate:pick.tradeDate callback:^(NSURLResponse *response, NSData *data, NSError *error) {
                if (!error) {
                    DayQuote* dayQuote = [DayQuote fromData:data];
                    if (dayQuote) {
                        NSString *key = [NSString stringWithFormat:@"%@-%@", dayQuote.symbol, dayQuote.date];
                        [self.quotes setObject:dayQuote forKey:key];
                        [self.tableView reloadData];
                    }
                }
            }];
        }
    }
    
    NSString *tradeDateFormat =  [self formatFromTradeDate:self.nextPick.tradeDate];
    self.valueLabel.text = [NSString stringWithFormat:@"$%0.02f", value];
    self.nextPickLabel.text = [NSString stringWithFormat:@"Next Pick: %@ on %@", self.nextPick.symbol, tradeDateFormat];
    [self.tableView reloadData];
}

- (IBAction)onLogOutButton:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:LogOutNotification object:nil];
}


@end
