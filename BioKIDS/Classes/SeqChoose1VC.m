/*
  SeqChoose1VC.m
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

#import "SeqChoose1VC.h"
#import "BioKIDSUtil.h"
#import "InfoVC.h"

// Declare private methods.
@interface SeqChoose1VC()
- (NSDictionary *)itemForRow:(NSUInteger)aRow;
@end


@implementation SeqChoose1VC

@synthesize mScreenDict, mObservation, mHasIcons;

-(id)initWithScreen:(NSDictionary *)aScreen
		observation:(Observation *)aObservation
{
	if (!aScreen || !aObservation)
		return nil;

	self = [super initWithNibName:@"SeqChoose1VC" bundle:nil];
	if (self)
	{
		self.mScreenDict = aScreen;
		self.mObservation = aObservation;

		self.mHasIcons = NO;
		NSArray *items = [self.mScreenDict objectForKey:@"items"];
		for (NSDictionary *d in items)
		{
			if (nil != [d objectForKey:@"icon"])
			{
				self.mHasIcons = YES;
				break;
			}
		}
	}

	return self;
}


- (void)dealloc
{
	self.mScreenDict = nil;
	self.mObservation = nil;

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

	NSString *headerText = [self.mScreenDict objectForKey:@"helpText"];
	if (0 != [headerText length])
	{
		// Create table header view (on screen instructions).
		headerText = [headerText stringByReplacingOccurrencesOfString:@"\\n"
														   withString:@"\n"];
		[[BioKIDSUtil sharedBioKIDSUtil] addTextHeaderForTable:self.tableView
														  text:headerText];		
	}
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

	[[BioKIDSUtil sharedBioKIDSUtil] resizeTextHeaderForTable:self.tableView];
}


- (void)viewWillDisappear:(BOOL)aAnimated
{
	if ([[BioKIDSUtil sharedBioKIDSUtil]
							sequenceViewIsDisappearingDueToBack:self])
	{
		// Back was pressed.  Clear our main data field.
		NSString *dataField = [self.mScreenDict objectForKey:@"dataField"];
		if (dataField)
			[self.mObservation setValue:nil forKey:dataField];

		// Also clear data field associated with items (if any).
		for (NSDictionary *item in [self.mScreenDict objectForKey:@"items"])
		{
			dataField = [item objectForKey:@"dataField"];
			if (dataField)
				[self.mObservation setValue:nil forKey:dataField];
		}
	}
	
	[super viewWillDisappear:aAnimated];
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


- (NSInteger)tableView:(UITableView *)aTableView
			numberOfRowsInSection:(NSInteger)aSection
{
	NSArray *items = [self.mScreenDict objectForKey:@"items"];
	return (items) ? [items count] : 0;
}


- (UITableViewCell *)tableView:(UITableView *)aTableView
		 cellForRowAtIndexPath:(NSIndexPath *)aIndexPath
{
	NSString *CellIdentifier = @"ItemCell";
	UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil)
	{
		cell = [[[UITableViewCell alloc]
				 initWithStyle:UITableViewCellStyleDefault
				 reuseIdentifier:CellIdentifier] autorelease];
		[[BioKIDSUtil sharedBioKIDSUtil] configureSeqCellLabel:cell];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}

	// Configure the cell.
	NSDictionary *item = [self itemForRow:aIndexPath.row];
	if (item)
	{
		cell.textLabel.text = [item objectForKey:@"label"];

		if (self.mHasIcons)
		{
			UIImage *img = nil;
			NSString *imgName = [item objectForKey:@"icon"];
			if (imgName)
				img = [UIImage imageNamed:imgName];
			if (!img)
				img = [UIImage imageNamed:@"blank-40.png"];
			cell.imageView.image = img;
		}
	}

	return cell;
}


#pragma mark - Table view delegate
- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)aIndexPath
{
	NSDictionary *item = [self itemForRow:aIndexPath.row];
	if (item)
	{
		// Set Observation data field for entire screen.
		NSString *dataField = [self.mScreenDict objectForKey:@"dataField"];
		if (dataField)
		{
			// dataFieldType = "int" is used for the grass-howmuch screen.
			BOOL isNumber = [[self.mScreenDict objectForKey:@"dataFieldType"]
											isEqualToString:@"int"];
			if (isNumber)
			{
				NSNumber *itemNum = [NSNumber numberWithInteger:aIndexPath.row];
				[self.mObservation setValue:itemNum forKey:dataField];
			}
			else
			{
				NSString *s = [item objectForKey:@"label"];
				[self.mObservation setValue:s forKey:dataField];
			}
		}

		// Set Observation data field for the chosen item.
		dataField = [item objectForKey:@"dataField"];
		if (dataField)
		{
			NSString *s = [item objectForKey:@"label"];
			[self.mObservation setValue:s forKey:dataField];
		}

		NSString *nextScreen = [item objectForKey:@"next"];
//		NSLog(@"item: %@, next: %@\n", [item objectForKey:@"label"], nextScreen);
		if (!nextScreen)
			nextScreen = [self.mScreenDict objectForKey:@"next"];

		if (nextScreen)
		{
			[[BioKIDSUtil sharedBioKIDSUtil] pushViewControllerForScreen:nextScreen
									navController:self.navigationController
									 observation:self.mObservation];
		}
	}

	[aTableView deselectRowAtIndexPath:aIndexPath animated:YES];
}


#pragma mark Private Methods
- (NSDictionary *)itemForRow:(NSUInteger)aRow
{
	NSArray *items = [self.mScreenDict objectForKey:@"items"];
	return (aRow < [items count]) ? [items objectAtIndex:aRow] : nil;
}

@end
