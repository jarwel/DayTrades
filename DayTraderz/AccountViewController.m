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

@end

@implementation AccountViewController

static NSString * const cellIdentifier = @"PickCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.picks = [[NSMutableArray alloc] init];
    
    UINib *userCell = [UINib nibWithNibName:cellIdentifier bundle:nil];
    [self.tableView registerNib:userCell forCellReuseIdentifier:cellIdentifier];
    
    [[ParseClient instance] fetchAccountForUser:PFUser.currentUser callback:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.account = objects[0];
            [[ParseClient instance] fetchPicksForAccount:self.account callback:^(NSArray *objects, NSError *error) {
                if (!error) {
                    [self parseObjects:objects];
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
        
        cell.buyLabel.text = [NSString stringWithFormat:@"%0.02f Buy", pick.open];
        cell.sellLabel.text = [NSString stringWithFormat:@"%0.02f Sell", pick.close];
        cell.changeLabel.text = [self formatChangeFromPick:pick];
        cell.valueLabel.text = [NSString stringWithFormat:@"$%0.02f", pick.value + pick.change];
    }
    
    return cell;
}

- (void)pickFromController:(Pick *)pick {
    self.nextPick = pick;
    [self refreshViews];
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
        unsigned unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay;
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSDateComponents *comps = [calendar components:unitFlags fromDate:[NSDate date]];
        comps.hour = 14;
        comps.minute = 30;
        comps.second = 0;
        NSDate *date = [calendar dateFromComponents:comps];
        if ([date compare:pick.tradeDate] == NSOrderedSame) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isNextPick:(Pick *) pick {
    if (pick) {
        unsigned unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay;
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSDateComponents *comps = [calendar components:unitFlags fromDate:[NSDate date]];
        comps.hour = 14;
        comps.minute = 30;
        comps.second = 0;
        NSDate *date = [calendar dateFromComponents:comps];
        if ([date compare:pick.tradeDate] == NSOrderedAscending) {
            return YES;
        }
    }
    return NO;
}

- (NSString *)formatFromTradeDate:(NSDate *)tradeDate {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MM-dd-yyyy"];
    return [formatter stringFromDate:tradeDate];
}

- (NSString *)formatChangeFromPick:(Pick *)pick {
    float priceChange = pick.close - pick.open;
    float percentChange = priceChange / pick.open;
    NSString *priceChangeFormat = [NSString stringWithFormat:@"%+0.2f", priceChange];
    NSString *percentChangeFormat = [NSString stringWithFormat:@"%+0.2f%%", percentChange];
    return [NSString stringWithFormat:@"%@ (%@)", priceChangeFormat, percentChangeFormat];
}

- (void)refreshViews {
    self.valueLabel.text = [NSString stringWithFormat:@"$%0.02f", self.account.value];
    self.nextPickLabel.text = [NSString stringWithFormat:@"Next Pick: %@", self.nextPick.symbol];
    [self.tableView reloadData];
}

- (void)parseObjects:(NSArray *)objects {
    [self.picks removeAllObjects];
    for (Pick* pick in objects) {
        if ([self isNextPick:pick]) {
            self.nextPick = pick;
        }
        else if ([self isCurrentPick:pick]) {
            self.currentPick = pick;
        }
        else {
            [self.picks addObject:pick];
        }
    }
    [self refreshViews];
}

- (IBAction)onLogOutButton:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:LogOutNotification object:nil];
}


@end
