//
//  ViewController.h
//  Estimator
//
//  Created by Roman Mykitchak on 1/21/15.
//  Copyright (c) 2015 ukrinsoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PagesNumberModel.h"
#import <MessageUI/MessageUI.h>
#import <AVFoundation/AVFoundation.h>
#import "Global.h"
 
@interface ViewController : UIViewController <UITableViewDataSource,
UITableViewDelegate,
UIPickerViewDataSource,
UIPickerViewDelegate,
ReestimateDelegate,
MFMailComposeViewControllerDelegate,
UISearchBarDelegate>
{
    MFMailComposeViewController *_mailComposer;
}

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UITextField *iOS_TF;
@property (strong, nonatomic) IBOutlet UITextField *device_TF;
@property (strong, nonatomic) IBOutlet UITextField *mode_TF;
@property (strong, nonatomic) IBOutlet UITextField *additionalHours_TF;
@property (strong, nonatomic) IBOutlet UIImageView *clean;
@property (strong, nonatomic) IBOutlet UIButton *cleanBtn;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
- (IBAction)viewTap:(UITapGestureRecognizer *)sender;
- (IBAction)clearTap:(UIButton *)sender;
- (IBAction)emailPressed:(id)sender;


@end

