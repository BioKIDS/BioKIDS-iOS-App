/*
  SettingsVC.m
  Created 8/11/11.

  Copyright (c) 2011-2013 The Regents of the University of Michigan

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
- (void) onClassroomUsePrefChange:(NSNotification *)aNotification;
@end


@implementation SettingsVC

@synthesize mClassroomToggleCell, mIDCell;

// Define constants.
static const NSInteger kIDRow = 0;
static const NSInteger kTrackerRow = 1;
static const NSInteger kZoneRow = 2;

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
	self.mClassroomToggleCell = nil;
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

	self.navigationItem.title = NSLocalizedString(@"SettingsTitle", nil);

	BioKIDSUtil *bku = [BioKIDSUtil sharedBioKIDSUtil];
	self.tableView.backgroundView = nil;	// Needed for transparent background.
	self.view.backgroundColor = [bku appBackgroundColor];
	[bku addEmptyHeaderAndFooterForTable:self.tableView];

	[[NSNotificationCenter defaultCenter] addObserver:self
						 selector:@selector(onClassroomUsePrefChange:)
							 name:kNotificationClassroomUseChanged object:nil];
}


- (void)viewWillAppear:(BOOL)aAnimated
{
	[super viewWillAppear:aAnimated];

	NSIndexPath *ip = [NSIndexPath indexPathForRow:kTrackerRow inSection:1];
	UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:ip];
	[self cellTextFromPref:cell prefKey:kTrackerKey];

	ip = [NSIndexPath indexPathForRow:kZoneRow inSection:1];
	cell = [self.tableView cellForRowAtIndexPath:ip];
	[self cellTextFromPref:cell prefKey:kZoneKey];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)aOrient
{
	return YES;
}


#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView
{
	return 2;
}


- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)aSection
{
	return (0 == aSection) ? 1 : 3;
}


- (UITableViewCell *)tableView:(UITableView *)aTableView
							cellForRowAtIndexPath:(NSIndexPath *)aIndexPath
{
	BOOL isClassroomToggle = (0 == aIndexPath.section);
	BOOL isIDCell = (kIDRow == aIndexPath.row);
	NSString *cellID = isClassroomToggle ? @"ClassroomToggleCell"
										: isIDCell ? @"IDCell" : @"OtherCell";

	UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:cellID];
	if (cell == nil)
	{
		if (isClassroomToggle)
		{
			[[NSBundle mainBundle] loadNibNamed:@"ClassroomToggleCell"
										  owner:self options:nil];
			[self.mClassroomToggleCell setupCell];
			cell = self.mClassroomToggleCell;
		}
		else if (isIDCell)
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
	// Unselect cell in toggle section.
	if (0 == aIndexPath.section)
	{
		[aTableView deselectRowAtIndexPath:aIndexPath animated:NO];
		return;
	}

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


- (CGFloat)tableView:(UITableView *)aTableView heightForHeaderInSection:(NSInteger)aSection
{
	if (0 == aSection)
		return 0.0;

	BioKIDSUtil *bku = [BioKIDSUtil sharedBioKIDSUtil];
	NSString *key = ([bku isPersonalUse])
					? @"PersonalSettingsHeader" : @"ClassroomSettingsHeader";
	NSString *text = NSLocalizedString(key, nil);

	UIFont *font = [bku fontForTextView];
	CGFloat marginLR = [bku tableSectionHeaderSideMargin];
	CGFloat width = aTableView.frame.size.width - (2 * marginLR);
	return [bku idealHeightForString:text withFont:font
					   lineBreakMode:NSLineBreakByWordWrapping
							   width:width];
}


- (UIView *)tableView:(UITableView *)aTableView
								viewForHeaderInSection:(NSInteger)aSection
{
	if (0 == aSection)
		return nil;

	BioKIDSUtil *bku = [BioKIDSUtil sharedBioKIDSUtil];
	NSString *key = ([bku isPersonalUse])
					? @"PersonalSettingsHeader" : @"ClassroomSettingsHeader";
	NSString *text = NSLocalizedString(key, nil);

	return [bku viewForText:text withWidth:aTableView.frame.size.width];
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


- (void) onClassroomUsePrefChange:(NSNotification *)aNotification
{
	// Note: calling reloadSections does not work; the headerLabel subview
	// is resized to the width of the entire table (no right / bottom margin).
	[self.tableView reloadData];	// TODO: this causes the UISwitch animation to be lost :(
}

@end
