/*
  SettingsVC.m
  Created 8/11/11.

  Copyright (c) 2011 The Regents of the University of Michigan

  Permission is hereby granted, free of charge, to any person obtaining
  a copy of this software and associated documentation files (the
  "Software"), to deal in the Software without restriction, including
  without limitation the rights to use, copy, modify, merge, publish,
  distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject
  to the following conditions:

  The above copyright notice and this permission notice shall be
  included in all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
  ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#import "SettingsVC.h"
#import "Constants.h"
#import "BioKIDSUtil.h"
#import "SettingsChoose1VC.h"

// Declare private methods.
@interface SettingsVC()
- (void) cellTextFromPref:(UITableViewCell *)aCell prefKey:(NSString *)aPrefKey;
@end


@implementation SettingsVC

@synthesize mIDCell;

// Define constants.
const NSInteger kIDRow = 0;
const NSInteger kTrackerRow = 1;
const NSInteger kZoneRow = 2;

- (id)init
{
	self = [super initWithNibName:@"SettingsVC" bundle:nil];
	if (self)
	{
	}

	return self;
}


- (void)dealloc
{
	self.mIDCell = nil;

	[super dealloc];
}


- (void)didReceiveMemoryWarning
{
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];

	// Release any cached data, images, etc that aren't in use.
}


#pragma mark - View lifecycle
- (void)viewDidLoad
{
	[super viewDidLoad];

	self.tableView.backgroundView = nil;	// Needed for transparent background.
	self.navigationItem.title = NSLocalizedString(@"SettingsTitle", nil);

	// Create table header view (on screen instructions).
	NSString *s = NSLocalizedString(@"SettingsHeader", nil);
	[[BioKIDSUtil sharedBioKIDSUtil] addTextHeaderForTable:self.tableView
													  text:s];
}


- (void)viewDidUnload
{
	[super viewDidUnload];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)viewWillAppear:(BOOL)aAnimated
{
	[super viewWillAppear:aAnimated];

	NSIndexPath *ip = [NSIndexPath indexPathForRow:kTrackerRow inSection:0];
	UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:ip];
	[self cellTextFromPref:cell prefKey:kTrackerKey];

	ip = [NSIndexPath indexPathForRow:kZoneRow inSection:0];
	cell = [self.tableView cellForRowAtIndexPath:ip];
	[self cellTextFromPref:cell prefKey:kZoneKey];

	[[BioKIDSUtil sharedBioKIDSUtil] resizeTextHeaderForTable:self.tableView];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)aOrient
{
	return YES;
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)aFromOrient
{
	[[BioKIDSUtil sharedBioKIDSUtil] resizeTextHeaderForTable:self.tableView];	
}


#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView
{
	return 1;
}


- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section
{
	return 3;
}


- (UITableViewCell *)tableView:(UITableView *)aTableView
							cellForRowAtIndexPath:(NSIndexPath *)aIndexPath
{
	BOOL isIDCell = (kIDRow == aIndexPath.row);
	NSString *cellID = isIDCell ? @"IDCell" : @"OtherCell";

	UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:cellID];
	if (cell == nil)
	{
		if (isIDCell)
		{
			[[NSBundle mainBundle] loadNibNamed:@"BioKIDSIDCell" owner:self
										options:nil];
			[self.mIDCell setupCell];
			cell = self.mIDCell;
		}
		else
		{
			cell = [[[UITableViewCell alloc]
					 initWithStyle:UITableViewCellStyleValue1
					 reuseIdentifier:cellID] autorelease];
		}
	}

	// Configure the cell.
	switch (aIndexPath.row)
	{
		case kIDRow:
			break;
		case kTrackerRow:
			cell.textLabel.text = NSLocalizedString(@"SettingsTrackerLabel", nil);
			[self cellTextFromPref:cell prefKey:kTrackerKey];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			break;
		case kZoneRow:
			cell.textLabel.text = NSLocalizedString(@"SettingsZoneLabel", nil);
			[self cellTextFromPref:cell prefKey:kZoneKey];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			break;
	}

	return cell;
}


#pragma mark - Table view delegate
- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)aIndexPath
{
	NSString *plistFile = nil;
	NSString *prefKey = nil;
	NSString *title = nil;

	if (kTrackerRow == aIndexPath.row)
	{
		plistFile = @"trackers";
		prefKey = kTrackerKey;
		title = NSLocalizedString(@"SettingsChooseTrackerTitle", nil);
	}
	else if (kZoneRow == aIndexPath.row)
	{
		plistFile = @"zones";
		prefKey = kZoneKey;
		title = NSLocalizedString(@"SettingsChooseZoneTitle", nil);
	}

	if (plistFile)
	{
		[self.mIDCell closeKeyboard];

		SettingsChoose1VC *vc = [[SettingsChoose1VC alloc]
						initWithList:plistFile prefKey:prefKey title:title];
		if (vc)
		{
			[self.navigationController pushViewController:vc animated:YES];
			[vc release];
		}
	}
}


#pragma mark Private Methods
- (void) cellTextFromPref:(UITableViewCell *)aCell prefKey:(NSString *)aPrefKey
{
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	NSString *s = [ud stringForKey:aPrefKey];
	if (!s)
		s = @"";
	aCell.detailTextLabel.text = s;
}

@end
