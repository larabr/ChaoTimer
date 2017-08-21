//
//  CHTStatsViewController.m
//  ChaoTimer
//
//  Created by Jichao Li on 10/2/13.
//  Copyright (c) 2013 Jichao Li. All rights reserved.
//

#import "CHTStatsViewController.h"
#import "CHTTheme.h"
#import "CHTSettings.h"
#import "CHTUtil.h"
#import "CHTSession.h"
#import "CHTSessionManager.h"
#import "CHTOneStat.h"
#import "CHTStatDetailViewController.h"
#import "CHTSessionViewController.h"
#import "CHTSolveDetailViewController.h"

@interface CHTStatsViewController ()
@property (nonatomic, strong) CHTSession *session;
@property (nonatomic, strong) UIPopoverController *popoverController;
@property (nonatomic, strong) CHTTheme *timerTheme;
@end

@implementation CHTStatsViewController
@synthesize session = _session;
@synthesize stats = _stats;
@synthesize timerTheme;
@synthesize popoverController;

- (CHTSession *) session {
    if (!_session) {
        _session = [[CHTSessionManager load] loadCurrentSession];
    }
    return _session;
}

- (NSMutableArray *) stats {
    if (!_stats) {
        _stats = [[NSMutableArray alloc] init];
    }
    return _stats;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = [CHTUtil getLocalizedString:@"Stats"];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"sessions.png"] style:UIBarButtonItemStylePlain target:self action:@selector(presentSessionView)];
    }

- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"view will appear");
    [self reload];
    self.timerTheme = [CHTTheme getTimerTheme];
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.stats.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    CHTOneStat *oneStats = [self.stats objectAtIndex:indexPath.row];
    //NSLog(@"Stat: %@, detail %@",oneStats.statType, oneStats.statValue);
    cell.textLabel.text = [CHTUtil getLocalizedString:oneStats.statType];
    cell.detailTextLabel.text = oneStats.statValue;
    if (indexPath.row == 0) {
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        [cell setAccessoryType: UITableViewCellAccessoryNone];
        
    } else {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    [cell.detailTextLabel setTextColor:[self.timerTheme getTintColor]];
    [cell.textLabel setFont:[CHTTheme font:FONT_REGULAR iphoneSize:18.0f ipadSize:18.0f]];
    [cell.detailTextLabel setFont:[CHTTheme font:FONT_LIGHT iphoneSize:18.0f ipadSize:18.0f]];
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([self.session.sessionName isEqualToString:@"main session"]) {
        return [CHTUtil getLocalizedString:@"main session"];
    } else
        return self.session.sessionName;
}

- (void)presentSessionView
{
    if([self.popoverController isPopoverVisible])
    {
        NSLog(@"oh");
        [self reload];
        [self.popoverController dismissPopoverAnimated:YES];
        return;
    }
    CHTSessionViewController *sessionViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"sessionManage"];
    if ([CHTUtil getDevice] == DEVICE_PAD) {
        self.popoverController = [[UIPopoverController alloc] initWithContentViewController:sessionViewController];
        self.popoverController.delegate = self;
        [self.popoverController presentPopoverFromBarButtonItem:self.navigationItem.leftBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        [sessionViewController setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
        [self presentViewController:sessionViewController animated:YES completion:NULL];
    }
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    NSLog(@"dismiss");
    [self reload];
}

- (void)reload{
    self.session = [[CHTSessionManager load] loadCurrentSession];
    int numberOfSolves = self.session.numberOfSolves;
    [[self.tabBarController.tabBar.items objectAtIndex:0] setBadgeValue:[NSString stringWithFormat:@"%d", self.session.numberOfSolves]];
    [self.stats removeAllObjects];
    CHTOneStat *numOfSolves = [CHTOneStat initWithType:@"Number of solves: " Value:[NSString stringWithFormat:@"%d", self.session.numberOfSolves]];
    [self.stats addObject:numOfSolves];
    
    if (numberOfSolves > 0) {
        CHTOneStat *bestTime = [CHTOneStat initWithType:@"Best time: " Value:[[self.session bestSolve] toString]];
        CHTOneStat *worstTime = [CHTOneStat initWithType:@"Worst time: " Value:[[self.session worstSolve] toString]];
        CHTOneStat *sessionAvg = [CHTOneStat initWithType:@"Session Average: " Value:[[self.session sessionAvg] toString]];
        CHTOneStat *sessionMean = [CHTOneStat initWithType:@"Session Mean: " Value:[[self.session sessionMean] toString]];
        [self.stats addObject:bestTime];
        [self.stats addObject:worstTime];
        [self.stats addObject:sessionAvg];
        [self.stats addObject:sessionMean];
        
        if (numberOfSolves >= 5) {
            CHTOneStat *current5 = [CHTOneStat initWithType:@"Current average of 5: " Value:[[self.session currentAvgOf:5] toString]];
            CHTOneStat *best5 = [CHTOneStat initWithType:@"Best average of 5: " Value:[[self.session bestAvgOf:5] toString]];
            [self.stats addObject:current5];
            [self.stats addObject:best5];
            
            if (numberOfSolves >= 12) {
                CHTOneStat *current12 = [CHTOneStat initWithType:@"Current average of 12: " Value:[[self.session currentAvgOf:12] toString]];
                CHTOneStat *best12 = [CHTOneStat initWithType:@"Best average of 12: " Value:[[self.session bestAvgOf:12] toString]];
                [self.stats addObject:current12];
                [self.stats addObject:best12];
                
                if (numberOfSolves >= 100) {
                    CHTOneStat *current100 = [CHTOneStat initWithType:@"Current average of 100: " Value:[[self.session currentAvgOf:100] toString]];
                    CHTOneStat *best100 = [CHTOneStat initWithType:@"Best average of 100: " Value:[[self.session bestAvgOf:100] toString]];
                    [self.stats addObject:current100];
                    [self.stats addObject:best100];
                }
            }
        }
    }
    [self.tableView reloadData];
}

#pragma mark - Navigation

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    [cell setSelected:NO animated:YES];
    int row = indexPath.row;
    if (row != 0) {
        if (row == 1 || row == 2) {
            CHTSolveDetailViewController *solveDetailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"oneSolveDetail"];
            solveDetailViewController.hidesBottomBarWhenPushed = YES;
            switch (row) {
                case 1:
                    solveDetailViewController.solve = [self.session bestSolve];
                    break;
                case 2:
                    solveDetailViewController.solve = [self.session worstSolve];
                    break;
                default:
                    break;
            }
            [self.navigationController pushViewController:solveDetailViewController animated:YES];
        } else {
            CHTStatDetailViewController *statDetailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"statDetail"];
            statDetailViewController.hidesBottomBarWhenPushed = YES;
            statDetailViewController.session = self.session;
            statDetailViewController.stat = [self.stats objectAtIndex:row];
            statDetailViewController.row = row;
            switch (row) {
                case 3:
                    // session avg
                    statDetailViewController.statDetails = [self.session getAllSolves];
                    break;
                case 4:
                    // session mean
                    statDetailViewController.statDetails = [self.session getAllSolves];
                    break;
                case 5:
                    // current 5
                    statDetailViewController.statDetails = [self.session getCurrent:5];
                    break;
                case 6:
                    // best 5
                    statDetailViewController.statDetails = [self.session getBest:5];
                    break;
                case 7:
                    // current 12
                    statDetailViewController.statDetails = [self.session getCurrent:12];
                    break;
                case 8:
                    // best 12
                    statDetailViewController.statDetails = [self.session getBest:12];
                    break;
                case 9:
                    // current 100
                    statDetailViewController.statDetails = [self.session getCurrent:100];
                    break;
                case 10:
                    // best 100
                    statDetailViewController.statDetails = [self.session getBest:100];
                    break;
                default:
                    break;
            }
            [self.navigationController pushViewController:statDetailViewController animated:YES];
        }
    }
}

@end
