//
//  PagesNumberModel.h
//  Estimator
//
//  Created by Roman Mykitchak on 2/3/15.
//  Copyright (c) 2015 ukrinsoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EstimateCell.h"

@protocol ReestimateDelegate <NSObject>

- (void)reestimate;

@end


@interface PagesNumberModel : NSObject <EstimateCellDelegate>

@property id<ReestimateDelegate> delegate;
+ (instancetype)pagesModel;
+ (instancetype)pagesModelWithLenght:(unsigned long)lenghtMAX;
- (long)pagesNumberForIndex:(unsigned long)index;

- (void)pagesCountChangedTo:(long)pagesNumber indexCell:(unsigned long)index;

- (instancetype)initMAX:(unsigned long)lenghtMAX;

@end
