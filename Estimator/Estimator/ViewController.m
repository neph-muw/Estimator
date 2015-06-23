//
//  ViewController.m
//  Estimator
//
//  Created by Roman Mykitchak on 1/21/15.
//  Copyright (c) 2015 ukrinsoft. All rights reserved.
//

#import "ViewController.h"
#import "EstimateCell/EstimateCell.h"
#import "UIImage+animatedGIF.h"

const NSString *hourKey = @"HOUR";
const NSString *descriptKey = @"DESCRIPTION";
const NSString *subDescriptKey = @"SUB_DESCRIPTION";
const double IOS_SHIFT = 0.1;
const double IPHONE_IPAD_APP = 1.3;
const double UNIVERSAL_MODE = 1.2;

@interface ViewController ()
{
    bool *marked;
    
    NSArray *IOS_VERSIONS_ARRAY;
    NSArray *DEVICE_VERSIONS_ARRAY;
    NSArray *MODE_ARRAY;
    
    UITapGestureRecognizer *tap;
    
    CGPoint lastFoundIndex;
    NSRange foundRange;
}

@property (strong, nonatomic) IBOutlet UILabel *hoursLabel;
@property (strong, nonatomic) IBOutlet UILabel *hoursMeter;
@property NSArray *estiky;

@property UIPickerView *iosPicker;
@property UIPickerView *devicePicker;
@property UIPickerView *modePicker;

@property (strong) AVAudioPlayer *player;

@end

@implementation ViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self prepareTextFields];
    
    self.estiky = [self readExelFile:@"Estimate_hour.xls"];
    unsigned long c = [self.estiky count];
    [self initMarksSize:c];
    [PagesNumberModel pagesModelWithLenght:c].delegate = self;
    
    [self registerForKeyboardNotifications];
    
    self.searchBar.returnKeyType = UIReturnKeyNext;
    
    lastFoundIndex = CGPointZero;
}

- (void)prepareTextFields
{
    IOS_VERSIONS_ARRAY = @[@"8.0", @"7.0", @"6.0", @"5.0", @"4.1"];
    DEVICE_VERSIONS_ARRAY = @[@"iPhone", @"iPad", @"Universal"];
    MODE_ARRAY = @[@"Portrait", @"Landscape", @"Both"];
    
    self.iOS_TF.text = [IOS_VERSIONS_ARRAY firstObject];
    self.device_TF.text = [DEVICE_VERSIONS_ARRAY firstObject];
    self.mode_TF.text = [MODE_ARRAY firstObject];
    
    self.iosPicker = [[UIPickerView alloc] init];
    self.iosPicker.delegate = self;
    self.iosPicker.dataSource = self;
    [self.iosPicker setShowsSelectionIndicator:YES];
    self.iOS_TF.inputView = self.iosPicker;
    
    self.devicePicker = [[UIPickerView alloc] init];
    self.devicePicker.delegate = self;
    self.devicePicker.dataSource = self;
    [self.devicePicker setShowsSelectionIndicator:YES];
    self.device_TF.inputView = self.devicePicker;
    
    self.modePicker = [[UIPickerView alloc] init];
    self.modePicker.delegate = self;
    self.modePicker.dataSource = self;
    [self.modePicker setShowsSelectionIndicator:YES];
    self.mode_TF.inputView = self.modePicker;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)estimatePressed:(id)sender {
    if (soundEnable) {
        [self playSound];
    }
    
    long estimate = 0;
    for (int i=0; i<self.estiky.count; i++) {
        if (marked[i] == true) {
            long pages = [[PagesNumberModel pagesModel] pagesNumberForIndex:i];
            long onePage = [[[self.estiky objectAtIndex:i] objectForKey:hourKey] intValue];
            estimate += pages*onePage;
        }
    }
    
    // iOS version
    estimate *= [self persentageForIOS:self.iOS_TF.text];
    
    // device version
    estimate *= [self persentageForDevice:self.device_TF.text];
    
    // Portrait Landscape modes
    estimate *= [self persentageForMode:self.mode_TF.text];
    
    // additional hours
    if (self.additionalHours_TF.text.length>0) {
        long addHours = [self.additionalHours_TF.text intValue];
        estimate += addHours;
    }
    
    self.hoursLabel.text = [NSString stringWithFormat:@"%ld", estimate];
    
}

- (IBAction)emailPressed:(id)sender {
    if ([MFMailComposeViewController canSendMail]) {
        if ([self.hoursLabel.text intValue]>0) {
            _mailComposer = [[MFMailComposeViewController alloc] init];
            _mailComposer.mailComposeDelegate = self;
            [_mailComposer setSubject:@"iOS estimate"];
            
            NSMutableString *message = [[NSMutableString alloc] init];
            [message appendString:@"Project : \n"];
            for (int i=0; i<self.estiky.count; i++) {
                if (marked[i] == true) {
                    long pages = [[PagesNumberModel pagesModel] pagesNumberForIndex:i];
                    long onePage = [[[self.estiky objectAtIndex:i] objectForKey:hourKey] intValue];
                    [message appendString:[NSString stringWithFormat:@"%ld\t - %@\n", pages*onePage, [[self.estiky objectAtIndex:i] objectForKey:descriptKey]]];
                }
            }
            if (self.additionalHours_TF.text.length>0) {
                [message appendString:[NSString stringWithFormat:@"%@\t - Additional hours\n", self.additionalHours_TF.text]];
            }
            [message appendString:[NSString stringWithFormat:@"+ consider iOS:%@ device:%@ mode:%@\n", self.iOS_TF.text, self.device_TF.text, self.mode_TF.text]];
            
            [message appendString:[NSString stringWithFormat:@"\n\nEstimate : %@ hours", self.hoursLabel.text]];
            
            [_mailComposer setMessageBody:message isHTML:NO];
            [_mailComposer setToRecipients:@[@"account.manager@ukrinsoft.com"]];
            
            [self presentViewController:_mailComposer animated:YES completion:^{
                NSLog(@"Complete");
            }];
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                            message:@"Please choose categories or enter some values for giving estimate."
                                                           delegate:nil
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles: nil];
            [alert show];
        }
        
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                        message:@"Please adjust your email info for sending message inside phone Settings."
                                                       delegate:nil
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles: nil];
        [alert show];
    }
    
}

#pragma mark MFMailComposeViewControllerDelegate

-(void)mailComposeController:(MFMailComposeViewController *)controller
         didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error{
    if (result) {
        NSLog(@"Result : %d",result);
        if (result == MFMailComposeResultSent) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success"
                                                            message:@"Estimate succesfully sent."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles: nil];
            [alert show];
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning"
                                                            message:@"Estimate wasn't sent."
                                                           delegate:nil
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles: nil];
            [alert show];
        }
    }
    if (error) {
        NSLog(@"Error : %@",error);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:error.localizedDescription
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles: nil];
        [alert show];
    }
    
    [self dismissViewControllerAnimated:YES completion:^{
        NSLog(@"Dismissed");
    }];
}

- (double)persentageForIOS:(NSString *)iosStr
{
    double persentage = 1.0;
    for (int i=0; i<IOS_VERSIONS_ARRAY.count; i++) {
        if ([[IOS_VERSIONS_ARRAY objectAtIndex:i] isEqualToString:iosStr]) {
            persentage += i * IOS_SHIFT;
        }
    }
    
    return persentage;
}

- (double)persentageForDevice:(NSString *)deviceStr
{
    double persentage = 1.0;
    if ([[DEVICE_VERSIONS_ARRAY lastObject] isEqualToString:deviceStr]) {
        persentage = IPHONE_IPAD_APP;
    }
    
    return persentage;
}

- (double)persentageForMode:(NSString *)modeStr
{
    double persentage = 1.0;
    if ([[MODE_ARRAY lastObject] isEqualToString:modeStr]) {
        persentage = UNIVERSAL_MODE;
    }
    
    return persentage;
}

- (bool *)initMarksSize:(unsigned long)c
{
    marked = malloc(c*sizeof(*marked));
    
    int i;
    for (i=0; i<c; i++, marked++) {
        *marked = false;
    }
    
    while (i--) {
        marked--;
    }
    
    return marked;
}

- (NSArray *)readExelFile:(NSString *)fileName
{
    NSString *path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:fileName];
    //	NSString *path = @"/tmp/test.xls";
    // xls_debug = 1; // good way to see everything in the Excel file
    
    DHxlsReader *reader = [DHxlsReader xlsReaderWithPath:path];
    assert(reader);
    
    NSMutableArray *exelElements = [[NSMutableArray alloc] init];
    
    int row = 1;
    while(YES) {
        DHcell *cell = [reader cellInWorkSheetIndex:0 row:row col:1];
        if(cell.type == cellBlank) break;
        DHcell *cell1 = [reader cellInWorkSheetIndex:0 row:row col:2];
        DHcell *cell2 = [reader cellInWorkSheetIndex:0 row:row col:3];
        NSString *subDescriptionStr;
        if (cell2.type == cellString) {
            subDescriptionStr = cell2.str;
        }
        else
        {
            subDescriptionStr = @" ";
        }
        NSDictionary *dCell = @{
                                hourKey : cell.val,
                                descriptKey : cell1.str,
                                subDescriptKey : subDescriptionStr
                                };
        [exelElements addObject:dCell];
        
        row++;
    }
    
    return [NSArray arrayWithArray:exelElements];
    
}

#pragma mark UITableViewDataSource, UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.estiky count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"EstimateCell";
    
    EstimateCell *estCell = (EstimateCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (estCell == nil) {
        estCell = (EstimateCell *)[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                         reuseIdentifier:cellIdentifier];
    }
    
    estCell.delegate = [PagesNumberModel pagesModel];
    estCell->stateNumber = [[PagesNumberModel pagesModel] pagesNumberForIndex:indexPath.row];
    
    NSLog(@"%ld row %ld pages %@", (long)indexPath.row, [[PagesNumberModel pagesModel] pagesNumberForIndex:indexPath.row], estCell);
    
    if (marked[indexPath.row] == true) {
        [estCell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
    else
    {
        [estCell setAccessoryType:UITableViewCellAccessoryNone];
    }
    
    estCell.cellTitle.text = [[self.estiky objectAtIndex:indexPath.row] objectForKey:descriptKey];
    [estCell setHours:[[[self.estiky objectAtIndex:indexPath.row] objectForKey:hourKey] stringValue]];
    estCell.cellSubtitle.text = [[self.estiky objectAtIndex:indexPath.row] objectForKey:subDescriptKey];
    
    
    // highlight text
    // - used here because some cell cann't be accessible outside when they aren't visible
    if ((int)lastFoundIndex.y==indexPath.row && (int)lastFoundIndex.x!=0) {
        NSAttributedString *attrString;
        if ((int)lastFoundIndex.x == 1) {
            attrString = estCell.cellTitle.attributedText;
        } else if ((int)lastFoundIndex.x == 2) {
            attrString = estCell.cellSubtitle.attributedText;
        }
        NSMutableAttributedString *text = [[NSMutableAttributedString alloc]initWithAttributedString:attrString];
        [text addAttribute:NSBackgroundColorAttributeName
                     value:[UIColor redColor]
                     range:foundRange];
        if ((int)lastFoundIndex.x == 1) {
            [estCell.cellTitle setAttributedText: text];
        } else if ((int)lastFoundIndex.x == 2) {
            [estCell.cellSubtitle setAttributedText: text];
        }
    }
    
    
    return estCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    EstimateCell *selectedCell = (EstimateCell *)[tableView cellForRowAtIndexPath:indexPath];
    if ([selectedCell accessoryType] == UITableViewCellAccessoryNone)
    {
        [selectedCell setAccessoryType:UITableViewCellAccessoryCheckmark];
        marked[indexPath.row] = true;
    }
    else
    {
        [selectedCell setAccessoryTypeResetStateNum:UITableViewCellAccessoryNone];
        marked[indexPath.row] = false;
    }
    
    [self estimatePressed:nil];
}

#pragma mark Picker Delegates and DataSources

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (pickerView == self.iosPicker) {
        return [IOS_VERSIONS_ARRAY count];
    }
    else if (pickerView == self.devicePicker)
    {
        return [DEVICE_VERSIONS_ARRAY count];
    }
    else if (pickerView == self.modePicker)
    {
        return [MODE_ARRAY count];
    }
    
    return 0;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (pickerView == self.iosPicker) {
        return [IOS_VERSIONS_ARRAY objectAtIndex:row];
    }
    else if (pickerView == self.devicePicker)
    {
        return [DEVICE_VERSIONS_ARRAY objectAtIndex:row];
    }
    else if (pickerView == self.modePicker)
    {
        return [MODE_ARRAY objectAtIndex:row];
    }
    
    return @"";
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if (pickerView == self.iosPicker) {
        self.iOS_TF.text = [IOS_VERSIONS_ARRAY objectAtIndex:row];
        [self.iOS_TF resignFirstResponder];
    }
    else if (pickerView == self.devicePicker)
    {
        self.device_TF.text = [DEVICE_VERSIONS_ARRAY objectAtIndex:row];
        [self.device_TF resignFirstResponder];
    }
    else if (pickerView == self.modePicker)
    {
        self.mode_TF.text = [MODE_ARRAY objectAtIndex:row];
        [self.mode_TF resignFirstResponder];
    }
    
    [self estimatePressed:nil];
}

#pragma mark KeyboardNotifications

- (IBAction)viewTap:(UITapGestureRecognizer *)sender {
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
    
    if (self.searchBar.text.length>0) {
        self.searchBar.text = @"";
        [self cleanLastSearchLabel];
        lastFoundIndex = CGPointZero;
    }
}

- (IBAction)clearTap:(UIButton *)sender
{
    self.cleanBtn.hidden = YES;
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"broom" withExtension:@"gif"];
    self.clean.image = [UIImage animatedImageWithAnimatedGIFData:[NSData dataWithContentsOfURL:url]];
    
    CGRect basicPosition = self.clean.frame;
    
    [UIView animateWithDuration:2.0 animations:^{
        self.clean.frame = CGRectMake(self.hoursLabel.frame.origin.x, self.clean.frame.origin.y, self.clean.frame.size.width, self.clean.frame.size.height);
        self.hoursLabel.alpha = 0.0;
        self.hoursMeter.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self resetToDefault];
        [UIView animateWithDuration:1.2 animations:^{
            self.clean.frame = basicPosition;
        } completion:^(BOOL finished) {
            self.hoursLabel.alpha = 1.0;
            self.hoursMeter.alpha = 1.0;
            self.clean.image = [UIImage imageNamed:@"broom.gif"];
            self.cleanBtn.hidden = NO;
        }];
    }];
}

- (void)resetToDefault
{
    for (int i=0; i<[self.estiky count]; i++) {
        marked[i] = false;
    }
    [[PagesNumberModel pagesModel] initMAX:[self.estiky count]].delegate = self;
    
    self.iOS_TF.text = [IOS_VERSIONS_ARRAY firstObject];
    [self.iosPicker selectRow:0 inComponent:0 animated:NO];
    
    self.device_TF.text = [DEVICE_VERSIONS_ARRAY firstObject];
    [self.devicePicker selectRow:0 inComponent:0 animated:NO];
    
    self.mode_TF.text = [MODE_ARRAY firstObject];
    [self.modePicker selectRow:0 inComponent:0 animated:NO];
    
    self.additionalHours_TF.text = @"";
    
    [self estimatePressed:nil];
    
    [self.tableView reloadData];
}

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}

- (void)keyboardWasShown:(NSNotification*)aNotification
{
    tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                  action:@selector(viewTap:)];
    [self.view addGestureRecognizer:tap];
    
    float kbHeight = [[[aNotification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbHeight, 0.0);
    self.tableView.contentInset = contentInsets;
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    [self.view removeGestureRecognizer:tap];
    [self estimatePressed:nil];
    
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
}

#pragma mark ReestimateDelegate

- (void)reestimate
{
    [self estimatePressed:nil];
}

- (void)playSound
{
    //http://www.freesfx.co.uk
    
    NSURL *url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/coins.mp3", [[NSBundle mainBundle] resourcePath]]];
    
    NSError *error;
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    
    if (self.player == nil) {
        NSLog(@"%@", [error description]);
    }
    
    [self.player play];
}

#pragma mark UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    //[self searchForText:searchText];
    [self cleanLastSearchLabel];
    if (![self searchFromIndex:0 text:searchText category:1]) {
        [self searchFromIndex:0 text:searchText category:2];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    CGPoint previousIndex = CGPointMake(lastFoundIndex.x, lastFoundIndex.y);
    BOOL toStart = NO;
    
    [self cleanLastSearchLabel];
    if ((toStart = ![self searchFromIndex:(int)lastFoundIndex.y+1 text:searchBar.text category:(int)lastFoundIndex.x])) {
        if ((int)lastFoundIndex.x == 1) {
            toStart = ![self searchFromIndex:0 text:searchBar.text category:2];
        }
    }
    
    if (toStart && (int)previousIndex.x!=0) {
        if (![self searchFromIndex:0 text:searchBar.text category:1]) {
            [self searchFromIndex:0 text:searchBar.text category:2];
        }
    }
}

- (void)cleanLastSearchLabel
{
    if (lastFoundIndex.x != 0) {
        if ((int)lastFoundIndex.x == 1) {
            NSString *cellTitle = [[self.estiky objectAtIndex:(int)lastFoundIndex.y] objectForKey:descriptKey];
            NSIndexPath *path = [NSIndexPath indexPathForRow:(int)lastFoundIndex.y inSection:0];
            EstimateCell *cell = (EstimateCell *)[self.tableView cellForRowAtIndexPath:path];
            [cell.cellTitle setText:cellTitle];
        } else if ((int)lastFoundIndex.x == 2) {
            NSString *cellTitle = [[self.estiky objectAtIndex:(int)lastFoundIndex.y] objectForKey:subDescriptKey];
            NSIndexPath *path = [NSIndexPath indexPathForRow:(int)lastFoundIndex.y inSection:0];
            EstimateCell *cell = (EstimateCell *)[self.tableView cellForRowAtIndexPath:path];
            [cell.cellSubtitle setText:cellTitle];
        }
    }
    
}

- (BOOL)searchFromIndex:(int)index text:(NSString *)searchText category:(int)category
{
    const NSString *key;
    if (category == 1) {
        key = descriptKey;
    } else if (category == 2) {
        key = subDescriptKey;
    }
    
    for (int i=index; i<self.estiky.count; i++) {
        NSString *cellTitle = [[self.estiky objectAtIndex:i] objectForKey:key];
        NSRange range = [cellTitle rangeOfString:searchText options:NSCaseInsensitiveSearch];
        if (range.length>0) {
            NSIndexPath *path = [NSIndexPath indexPathForRow:i inSection:0];
            
            [self.tableView scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
            
            //highlight text
            EstimateCell *cell = (EstimateCell *)[self.tableView cellForRowAtIndexPath:path];//can be nil when cell isn't on screen
            if (cell != nil) {
                NSAttributedString *attrString;
                if (category == 1) {
                    attrString = cell.cellTitle.attributedText;
                } else if (category == 2) {
                    attrString = cell.cellSubtitle.attributedText;
                }
                
                NSMutableAttributedString *text = [[NSMutableAttributedString alloc]initWithAttributedString:attrString];
                [text addAttribute:NSBackgroundColorAttributeName
                             value:[UIColor redColor]
                             range:range];
                //NSLog(@"searched %@", text);
                if (category == 1) {
                    [cell.cellTitle setAttributedText: text];
                } else if (category == 2) {
                    [cell.cellSubtitle setAttributedText: text];
                }
            }
            
            lastFoundIndex = CGPointMake(category, i);
            foundRange = range;
            return YES;
        }
    }
    
    return NO;
}


@end




