//
//  EstimateCell.h
//  Estimator
//
//  Created by Roman Mykitchak on 2/2/15.
//  Copyright (c) 2015 ukrinsoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "YellowLineLabel.h"

@protocol EstimateCellDelegate <NSObject>

- (void)pagesCountChangedTo:(long)pagesNumber indexCell:(unsigned long)index;

@end

@interface EstimateCell : UITableViewCell
{
@public
    long stateNumber;
}

@property (strong, nonatomic) id <EstimateCellDelegate> delegate;
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *plusMinus;
@property (strong, nonatomic) IBOutlet YellowLineLabel *cellTitle;
@property (strong, nonatomic) IBOutlet UILabel *cellSubtitle;
@property (strong, nonatomic) IBOutlet UILabel *cellCounter;
- (IBAction)increasePressed:(id)sender;
- (IBAction)decreasePressed:(id)sender;
- (void)refreshCounter;
- (void)setHours:(NSString *)hours;

- (void)setAccessoryType:(UITableViewCellAccessoryType)accessoryType;
- (void)setAccessoryTypeResetStateNum:(UITableViewCellAccessoryType)accessoryType;

- (long)stateValue;

@end
