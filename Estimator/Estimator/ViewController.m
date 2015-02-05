//
//  ViewController.m
//  Estimator
//
//  Created by Roman Mykitchak on 1/21/15.
//  Copyright (c) 2015 ukrinsoft. All rights reserved.
//

#import "ViewController.h"
#import "EstimateCell/EstimateCell.h"

const NSString *hourKey = @"HOUR";
const NSString *descriptKey = @"DESCRIPTION";
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
}

@property (strong, nonatomic) IBOutlet UILabel *hoursLabel;
@property NSArray *estiky;

@property UIPickerView *iosPicker;
@property UIPickerView *devicePicker;
@property UIPickerView *modePicker;

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
    mailComposer = [[MFMailComposeViewController alloc]init];
    mailComposer.mailComposeDelegate = self;
    [mailComposer setSubject:@"iOS estimate"];
    
    NSMutableString *message = [[NSMutableString alloc] init];
    [message appendString:@"Project : \n"];
    for (int i=0; i<self.estiky.count; i++) {
        if (marked[i] == true) {
            long pages = [[PagesNumberModel pagesModel] pagesNumberForIndex:i];
            long onePage = [[[self.estiky objectAtIndex:i] objectForKey:hourKey] intValue];
            [message appendString:[NSString stringWithFormat:@"%ld\t - %@\n", pages*onePage, [[self.estiky objectAtIndex:i] objectForKey:descriptKey]]];
        }
    }
    [message appendString:[NSString stringWithFormat:@"\n\nEstimate : %@ hours", self.hoursLabel.text]];
    
    [mailComposer setMessageBody:message isHTML:NO];
    [self presentViewController:mailComposer animated:YES completion:nil];
}

#pragma mark MFMailComposeViewControllerDelegate

-(void)mailComposeController:(MFMailComposeViewController *)controller
         didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error{
    if (result) {
        NSLog(@"Result : %d",result);
    }
    if (error) {
        NSLog(@"Error : %@",error);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
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
        NSDictionary *dCell = @{
                                hourKey : cell.val,
                                descriptKey : cell1.str
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
    
    if (marked[indexPath.row] == true) {
        [estCell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
    else
    {
        [estCell setAccessoryType:UITableViewCellAccessoryNone];
    }
    
    estCell.cellTitle.text = [[self.estiky objectAtIndex:indexPath.row] objectForKey:descriptKey];
    estCell.cellHours.text =  [[[self.estiky objectAtIndex:indexPath.row] objectForKey:hourKey] stringValue];
    
    return estCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    if ([selectedCell accessoryType] == UITableViewCellAccessoryNone)
    {
        [selectedCell setAccessoryType:UITableViewCellAccessoryCheckmark];
        marked[indexPath.row] = true;
    }
    else
    {
        [selectedCell setAccessoryType:UITableViewCellAccessoryNone];
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
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    [self.view removeGestureRecognizer:tap];
    [self estimatePressed:nil];
}

#pragma mark ReestimateDelegate

- (void)reestimate
{
    [self estimatePressed:nil];
}

@end




