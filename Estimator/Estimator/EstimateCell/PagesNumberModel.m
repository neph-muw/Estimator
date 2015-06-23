//
//  PagesNumberModel.m
//  Estimator
//
//  Created by Roman Mykitchak on 2/3/15.
//  Copyright (c) 2015 ukrinsoft. All rights reserved.
//

#import "PagesNumberModel.h"

@interface PagesNumberModel()
{
    NSMutableArray *pagesInCell;
}

@end

@implementation PagesNumberModel

static PagesNumberModel *singleton;

+ (instancetype)pagesModelWithLenght:(unsigned long)lenghtMAX
{
    if (!singleton || singleton == nil) {
        singleton = [[PagesNumberModel alloc] initMAX:lenghtMAX];
    }
    
    return singleton;
}

+ (instancetype)pagesModel
{
    if (!singleton || singleton == nil) {
        singleton = [[PagesNumberModel alloc] init];
    }
    
    return singleton;
}

- (instancetype)initMAX:(unsigned long)lenghtMAX
{
    self = [super init];
    if (self) {
        pagesInCell = [[NSMutableArray alloc] initWithCapacity:lenghtMAX];
        while (lenghtMAX--) {
            [pagesInCell addObject:[NSNumber numberWithLong:1]];
        }
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        pagesInCell = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)pagesCountChangedTo:(long)pagesNumber indexCell:(unsigned long)index
{
    //replace new
    if (pagesInCell) {
        [pagesInCell replaceObjectAtIndex:index withObject:[NSNumber numberWithLong:pagesNumber]];
        [self.delegate reestimate];
    }
}

- (long)pagesNumberForIndex:(unsigned long)index
{
    if (pagesInCell != nil && pagesInCell.count>=index && pagesInCell.count>0) {
        if ([pagesInCell objectAtIndex:index] != nil) {
            return [[pagesInCell objectAtIndex:index] longValue];
        }
    }
    
    return 1;
    
}

@end
