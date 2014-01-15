/*
  SettingsChoose1VC.m
  Created 8/12/11.

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

#import "SettingsChoose1VC.h"
#import "BioKIDSUtil.h"


// Declare private methods.
@interface SettingsChoose1VC()
- (void)configureCell:(UITableViewCell *)aCell isSelected:(BOOL)aIsSelected;
- (void)showSelectedItem;
@end


@implementation SettingsChoose1VC

@synthesize mItems, mPrefKey, mIconHeight, mSelectedItemIndex;

// Define constants.
static const CGFloat kIconVerticalMargin = 4.0;
static const NSInteger kNoneRowIndex = 0;


- (id)initWithList:(NSString *)aFileBaseName prefKey:(NSString *)aPrefKey
			 title:(NSString *)aTitle
{
	self = [super initWithNibName:@"SettingsChoose1VC" bundle:nil];
	if (self)
	{
		NSString *path = [[NSBundle mainBundle] pathForResource:aFileBaseName
														 ofType:@"plist"];
		NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
		self.mItems = [dict objectForKey:@"items"];
		if (!self.mItems)
			return nil;

		NSNumber *ht = [dict objectForKey:@"iconHeight"];
		self.mIconHeight = (ht) ? [ht floatValue] : 0.0;
		if (self.mIconHeight > 0)
		{
			CGFloat proposedHt = self.mIconHeight + kIconVerticalMargin;
			if (proposedHt > self.tableView.rowHeight)
				self.tableView.rowHeight = proposedHt;
		}

		self.navigationItem.title = aTitle;

		self.mSelectedItemIndex = -1;
		self.mPrefKey = aPrefKey;
		NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
		NSString *selectedItemName = [ud stringForKey:self.mPrefKey];
		if (selectedItemName)
		{
			for (int i = 0; i < [self.mItems count]; ++i)
			{
				NSString *name = [[self.mItems objectAtIndex:i] objectForKey:@"name"];
				if ([name isEqualToString:selectedItemName])
				{
					self.mSelectedItemIndex	= i;
					break;
				}
			}
			if (self.mSelectedItemIndex < 0)
				self.mSelectedItemIndex = kNoneRowIndex;
		}
	}

	return self;
}


- (void)dealloc
{
	self.mItems = nil;
	self.mPrefKey = nil;

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

	BioKIDSUtil *bku = [BioKIDSUtil sharedBioKIDSUtil];
	self.tableView.backgroundView = nil;	// Needed for transparent background.
	self.view.backgroundColor = [bku appBackgroundColor];
	[bku addEmptyHeaderAndFooterForTable:self.tableView];
	
	// TODOFuture: it would be better to avoid using a timer.  For ideas, see:
	// http://stackoverflow.com/questions/1483581/
	[self performSelector:@selector(showSelectedItem) withObject:nil
			   afterDelay:0.5];
}


- (void)viewDidUnload
{
	[super viewDidUnload];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)aOrient
{
	return YES;
}


#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView
{
	return 1;
}


- (NSInteger)tableView:(UITableView *)aTableView
								numberOfRowsInSection:(NSInteger)aSection
{
	return [self.mItems count];
}


- (UITableViewCell *)tableView:(UITableView *)aTableView
								cellForRowAtIndexPath:(NSIndexPath *)aIndexPath
{
	static NSString *cellID = @"ItemCell";

	UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:cellID];
	if (cell == nil)
	{
		cell = [[[UITableViewCell alloc]
				 initWithStyle:UITableViewCellStyleValue1
								reuseIdentifier:cellID] autorelease];
	}

	// Configure the cell.
	NSDictionary *itemDict = [self.mItems objectAtIndex:aIndexPath.row];
	cell.textLabel.text = [itemDict objectForKey:@"name"];

	BOOL isSelected = (aIndexPath.row == self.mSelectedItemIndex);
	[self configureCell:cell isSelected:isSelected];

	if (self.mIconHeight > 0)
	{
		UIImage *img = nil;
		NSString *imgName = [itemDict objectForKey:@"icon"];
		if (imgName)
			img = [UIImage imageNamed:imgName];
		if (!img)
			img = [UIImage imageNamed:@"blank-40.png"];
		cell.imageView.image = img;
	}

	return cell;
}


#pragma mark - Table view delegate
- (void)tableView:(UITableView *)aTableView
							didSelectRowAtIndexPath:(NSIndexPath *)aIndexPath
{
	UITableViewCell *cell = [aTableView cellForRowAtIndexPath:aIndexPath];
	if (cell)
	{
		if (self.mSelectedItemIndex >= 0) // Uncheck previously selected cell.
		{
			NSIndexPath *oldIP = [NSIndexPath indexPathForRow:self.mSelectedItemIndex inSection:0];
			UITableViewCell *oldCell = [aTableView cellForRowAtIndexPath:oldIP];
			[self configureCell:oldCell isSelected:NO];
		}

		self.mSelectedItemIndex = aIndexPath.row;
		[self configureCell:cell isSelected:YES];
		NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
		if (aIndexPath.row == kNoneRowIndex)
			[ud removeObjectForKey:self.mPrefKey];
		else
			[ud setObject:cell.textLabel.text forKey:self.mPrefKey];
		[ud synchronize];
	}

	[aTableView deselectRowAtIndexPath:aIndexPath animated:YES];
}


#pragma mark Private Methods
- (void)configureCell:(UITableViewCell *)aCell isSelected:(BOOL)aIsSelected
{
	aCell.accessoryType = (aIsSelected) ? UITableViewCellAccessoryCheckmark
										: UITableViewCellAccessoryNone;
	if (aIsSelected)
	{
		// Copy text color from detail label (which we don't use).
		aCell.textLabel.textColor = aCell.detailTextLabel.textColor;
	}
	else
		aCell.textLabel.textColor = [UIColor blackColor];
}


- (void)showSelectedItem
{
	if (self.mSelectedItemIndex >= 0)
	{
		NSIndexPath *ip = [NSIndexPath indexPathForRow:self.mSelectedItemIndex
											 inSection:0];
		[self.tableView scrollToRowAtIndexPath:ip
				atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
	}
}

@end
