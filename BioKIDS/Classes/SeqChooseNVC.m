/*
  SeqChooseNVC.m (for type=ChooseN and type=Choose0).
  Created 8/8/11.

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

#import "SeqChooseNVC.h"
#import "BioKIDSUtil.h"


// Declare private methods.
@interface SeqChooseNVC()
- (NSDictionary *)itemForRow:(NSUInteger)aRow;
- (void)setCheckMarkImageForCell:(UITableViewCell *)aCell
						 checked:(BOOL)aChecked;
- (BOOL)itemIsChecked:(NSUInteger)aIndex;
- (void)configureNextButtonState:(BOOL)aAtLeastOneIsChecked;
- (void)updateObservation;
- (void)onNextPress:(id)aSender;
@end


@implementation SeqChooseNVC

@synthesize mScreenDict, mObservation, mRequireOne, mItemChecks;
@synthesize mNextBtn, mCheckedImage, mUncheckedImage;


// Constants:
const NSInteger kCheckMarkImageTag = 1;

-(id)initWithScreen:(NSDictionary *)aScreen
		observation:(Observation *)aObservation
		requireAtLeastOne:(BOOL)aRequireOne
{
	if (!aScreen || !aObservation)
		return nil;

	self = [super initWithNibName:@"SeqChooseNVC" bundle:nil];
	if (self)
	{
		self.mRequireOne = aRequireOne;
		self.mScreenDict = aScreen;
		self.mObservation = aObservation;

		// TODOFuture: for editing, use aObservation to initialize the self.mItemChecks array.
		NSUInteger itemCount = [[self.mScreenDict objectForKey:@"items"] count];
		self.mItemChecks = [NSMutableArray arrayWithCapacity:itemCount];
		for (int i = 0; i < itemCount; ++i)
			[self.mItemChecks addObject:[NSNumber numberWithBool:NO]];

		self.mCheckedImage = [UIImage imageNamed:@"checked.png"];
		self.mUncheckedImage = [UIImage imageNamed:@"unchecked.png"];

		// Add Next button as table footer.
		CGFloat w = self.tableView.frame.size.width;
		self.mNextBtn = [[BioKIDSUtil sharedBioKIDSUtil] nextButtonForView:w];
		[self.mNextBtn addTarget:self action:@selector(onNextPress:)
								forControlEvents:UIControlEventTouchUpInside];

		UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, 70.0)];
		v.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[v addSubview:self.mNextBtn];

		[self.tableView setTableFooterView:v];
		[v release];

		[self configureNextButtonState:NO];
	}

	return self;
}


- (void)dealloc
{
	self.mScreenDict = nil;
	self.mObservation = nil;
	self.mItemChecks = nil;
	self.mNextBtn = nil;
	self.mCheckedImage = nil;
	self.mUncheckedImage = nil;

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

	BioKIDSUtil *bku = [BioKIDSUtil sharedBioKIDSUtil];
	[bku useBackButtonLabel:self];
	NSString *title = [self.mScreenDict objectForKey:@"title"];
	[bku configureNavTitle:title forVC:self];
}


- (void)viewDidUnload
{
	[super viewDidUnload];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


-(void) viewWillDisappear:(BOOL)aAnimated
{
	if ([[BioKIDSUtil sharedBioKIDSUtil]
							sequenceViewIsDisappearingDueToBack:self])
	{
		// Back was pressed.  Clear our data field.
		NSString *dataField = [self.mScreenDict objectForKey:@"dataField"];
		if (dataField)
			[self.mObservation setValue:nil forKey:dataField];
	}
	
	[super viewWillDisappear:aAnimated];
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
	return [self.mItemChecks count];
}


- (UITableViewCell *)tableView:(UITableView *)aTableView
							cellForRowAtIndexPath:(NSIndexPath *)aIndexPath
{
	static NSString *cellID = @"ItemCell";

	UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:cellID];
	if (cell == nil)
	{
		cell = [[[UITableViewCell alloc]
					initWithStyle:UITableViewCellStyleDefault
					reuseIdentifier:cellID] autorelease];
		[[BioKIDSUtil sharedBioKIDSUtil] configureSeqCellLabel:cell];

		// Use a standard table cell with a UIImageView subview for
		// the checkmark (on left hand side).
		// Create with unchecked image; will be reset below.
		UIImage *img = self.mUncheckedImage;
		cell.indentationLevel = 1;
		cell.indentationWidth = img.size.width;	// Make room for checkmark.
		UIImageView *iv = [[UIImageView alloc] initWithImage:img];
		iv.tag = kCheckMarkImageTag;
		[cell.contentView addSubview:iv];
		[iv release];
	}

	// Configure the cell.
	BOOL doCheck = [self itemIsChecked:aIndexPath.row];
	[self setCheckMarkImageForCell:cell checked:doCheck];

	NSDictionary *item = [self itemForRow:aIndexPath.row];
	if (item)
	{
		cell.textLabel.text = [item objectForKey:@"label"];

		UIImage *img = nil;
		NSString *imgName = [item objectForKey:@"icon"];
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

	BOOL isItemSection = (0 == aIndexPath.section);
	if (isItemSection)
	{
		// Toggle checkmark.
		BOOL willBeChecked = ![self itemIsChecked:aIndexPath.row];
		[self.mItemChecks replaceObjectAtIndex:aIndexPath.row
						withObject:[NSNumber numberWithBool:willBeChecked]];
		[self setCheckMarkImageForCell:cell checked:willBeChecked];
		[self configureNextButtonState:willBeChecked];
		[self updateObservation];
	}

	[aTableView deselectRowAtIndexPath:aIndexPath animated:YES];
}


#pragma mark Private Methods
- (NSDictionary *)itemForRow:(NSUInteger)aRow
{
	NSArray *items = [self.mScreenDict objectForKey:@"items"];
	return (aRow < [items count]) ? [items objectAtIndex:aRow] : nil;
}


- (void)setCheckMarkImageForCell:(UITableViewCell *)aCell
						  checked:(BOOL)aChecked
{
	UIImageView *iv = (UIImageView *)[aCell viewWithTag:kCheckMarkImageTag];
	iv.image = (aChecked) ? self.mCheckedImage : self.mUncheckedImage;
}


- (BOOL)itemIsChecked:(NSUInteger)aIndex
{
	NSNumber *checkNum = [self.mItemChecks objectAtIndex:aIndex];
	return (checkNum) ? [checkNum boolValue] : NO;
}


- (void)configureNextButtonState:(BOOL)aAtLeastOneIsChecked
{
	BOOL enableNextBtn = aAtLeastOneIsChecked || !self.mRequireOne;
	if (!enableNextBtn)
	{
		NSUInteger itemCount = [self.mItemChecks count];
		for (NSUInteger idx = 0; !enableNextBtn && (idx < itemCount); ++idx)
		{
			enableNextBtn = [self itemIsChecked:idx];
		}
	}

	self.mNextBtn.enabled = enableNextBtn;
}


- (void)updateObservation
{
	NSString *dataField = [self.mScreenDict objectForKey:@"dataField"];
	if (!dataField)
		return;

	NSMutableString *value = [NSMutableString stringWithCapacity:20];
	NSInteger rowCount = [self.tableView numberOfRowsInSection:0];
	for (NSInteger row = 0; row < rowCount; ++row)
	{
		if ([self itemIsChecked:row])
		{
			NSDictionary *item = [self itemForRow:row];
			if (item)
			{
				NSString *s = [item objectForKey:@"label"];
				if (0 == [value length])
					[value appendString:s];
				else
					[value appendFormat:@"|%@", s];
			}
		}
	}

	[self.mObservation setValue:value forKey:dataField];
}


- (void)onNextPress:(id)aSender
{
	NSString *nextScreen = nil;
	NSUInteger itemCount = [self.mItemChecks count];
	for (NSUInteger idx = 0; !nextScreen && (idx < itemCount); ++idx)
	{
		if ([self itemIsChecked:idx])
		{
			NSDictionary *item = [self itemForRow:idx];
			nextScreen = [item objectForKey:@"next"];
		}
	}
	if (!nextScreen)
		nextScreen = [self.mScreenDict objectForKey:@"next"];
	[[BioKIDSUtil sharedBioKIDSUtil] pushViewControllerForScreen:nextScreen
										navController:self.navigationController
										observation:self.mObservation];
}

@end
