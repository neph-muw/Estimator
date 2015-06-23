//
//  EstimateCell.m
//  Estimator
//
//  Created by Roman Mykitchak on 2/2/15.
//  Copyright (c) 2015 ukrinsoft. All rights reserved.
//

#import "EstimateCell.h"

@interface EstimateCell ()

@property (strong, nonatomic) IBOutlet UILabel *cellHours;

@end

@implementation EstimateCell


- (IBAction)increasePressed:(id)sender {
    long pageValue = [self.cellHours.text intValue]/stateNumber;
    stateNumber++;
    self.cellHours.text = [NSString stringWithFormat:@"%ld", (stateNumber * pageValue)];
    UITableView *table = [self parentTableView];
    [self.delegate pagesCountChangedTo:stateNumber indexCell:[table indexPathForCell:self].row];
    [self refreshCounter];
}

- (IBAction)decreasePressed:(id)sender {
    if (stateNumber>1) {
        long pageValue = [self.cellHours.text intValue]/stateNumber;
        stateNumber--;
        self.cellHours.text = [NSString stringWithFormat:@"%ld", (stateNumber * pageValue)];
        UITableView *table = [self parentTableView];
        [self.delegate pagesCountChangedTo:stateNumber indexCell:[table indexPathForCell:self].row];
        [self refreshCounter];
    }
}



- (void)setHours:(NSString *)hours
{
    NSLog(@"setHours: %@ pages %ld", hours, stateNumber);
    self.cellHours.text = [NSString stringWithFormat:@"%ld", (stateNumber * [hours intValue])];
    [self refreshCounter];
}

- (void)refreshCounter
{
    NSLog(@"refreshCounter cell: %@ pages %ld", self.cellHours.text, stateNumber);
    if (stateNumber>1) {
        self.cellCounter.hidden = NO;
        long pageValue = [self.cellHours.text intValue]/stateNumber;
        self.cellCounter.text = [NSString stringWithFormat:@"%ld*%ld", stateNumber, pageValue];
    }
    else
    {
        self.cellCounter.hidden = YES;
    }
}

- (long)stateValue
{
    return stateNumber;
}

- (void)setAccessoryTypeResetStateNum:(UITableViewCellAccessoryType)accessoryType
{
    //set default value
    long pageValue = [self.cellHours.text intValue]/stateNumber;
    self.cellHours.text = [NSString stringWithFormat:@"%ld", pageValue];
    stateNumber = 1;
    UITableView *table = [self parentTableView];
    [self.delegate pagesCountChangedTo:stateNumber indexCell:[table indexPathForCell:self].row];
    
    [self setAccessoryType:accessoryType];
}

- (void)setAccessoryType:(UITableViewCellAccessoryType)accessoryType
{
    [super setAccessoryType:accessoryType];
    
    if (accessoryType == UITableViewCellAccessoryCheckmark) {
        for (UIButton *button in self.plusMinus) {
            button.hidden = NO;
        }
    }
    else if (accessoryType == UITableViewCellAccessoryNone)
    {
        for (UIButton *button in self.plusMinus) {
            button.hidden = YES;
        }
        
    }
    
    [self refreshCounter];
}

-(UITableView *)parentTableView {
    // iterate up the view hierarchy to find the table containing this cell/view
    UIView *aView = self.superview;
    while(aView != nil) {
        if([aView isKindOfClass:[UITableView class]]) {
            return (UITableView *)aView;
        }
        aView = aView.superview;
    }
    return nil; // this view is not within a tableView
}

@end
