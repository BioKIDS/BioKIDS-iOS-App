/*
  SeqCountVC.m
  Created 8/9/11.

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

#import "SeqCountVC.h"
#import "BioKIDSUtil.h"


// Declare private methods.
@interface SeqCountVC()
- (void)onNextPress:(id)aSender;
- (void)repositionViews;
@end


@implementation SeqCountVC

@synthesize mScreenDict, mObservation, mCountField, mExactOrEstimateCtrl, mNextBtn;

// Constants:
const NSInteger kCountContainerViewTag = 100;
const CGFloat kCountContainerPortraitY = 94.0;
const CGFloat kCountContainerLandscapeY = 62.0;
const CGFloat kNextBtnPortraitY = 174.0;
const CGFloat kNextBtnLandscapeY = 95.0;

static const CGFloat kIOS6BarHeightPortrait = 64.0;
static const CGFloat kIOS6BarHeightLandscape = 52.0;


-(id)initWithScreen:(NSDictionary *)aScreen
		observation:(Observation *)aObservation
{
	if (!aScreen || !aObservation)
		return nil;

	self = [super initWithNibName:@"SeqCountVC" bundle:nil];
	if (self)
	{
		self.mScreenDict = aScreen;
		self.mObservation = aObservation;

		// Add Next button below controls.
		CGFloat w = self.view.frame.size.width;
		self.mNextBtn = [[BioKIDSUtil sharedBioKIDSUtil] nextButtonForView:w];
		[self.mNextBtn addTarget:self action:@selector(onNextPress:)
				forControlEvents:UIControlEventTouchUpInside];
		
		CGRect r = CGRectMake(0, kNextBtnPortraitY, w, 70.0);
		UIView *v = [[UIView alloc] initWithFrame:r];
		v.autoresizingMask = UIViewAutoresizingFlexibleWidth |
							 UIViewAutoresizingFlexibleBottomMargin;
		[v addSubview:self.mNextBtn];
		
		[self.view addSubview:v];
		[v release];

		// Reposition views to account for orientation.
		[self repositionViews];
	}

	return self;
}


- (void)dealloc
{
	self.mScreenDict = nil;
	self.mObservation = nil;
	self.mCountField = nil;
	self.mExactOrEstimateCtrl = nil;
	self.mNextBtn = nil;

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
	self.view.backgroundColor = [bku appBackgroundColor];
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


- (void)viewWillAppear:(BOOL)aAnimated
{
	[super viewWillAppear:aAnimated];

	[self.mCountField becomeFirstResponder];
}


-(void) viewWillDisappear:(BOOL)aAnimated
{
	if ([[BioKIDSUtil sharedBioKIDSUtil]
								sequenceViewIsDisappearingDueToBack:self])
	{
		// Back was pressed.  Clear our data fields.
		NSString *dataField = [self.mScreenDict objectForKey:@"dataField"];
		if (dataField)
		{
			[self.mObservation setValue:nil forKey:dataField];
			// This code assumes there is a data field with the suffix "IsEstimated".
			dataField = [dataField stringByAppendingString:@"IsEstimated"];
			[self.mObservation setValue:nil forKey:dataField];
		}
	}
	
    [super viewWillDisappear:aAnimated];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)aOrient
{
	return YES;
}


- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)aFromOrient
{
	[self repositionViews];
}


-(IBAction)onCountFieldChange:(id)aSender
{
	NSString *s = self.mCountField.text;
	NSInteger count = 0;
	if ([s length] > 0)
	{
		count = [s integerValue];
		NSString *newVal = [NSString stringWithFormat:@"%d", count];
		if (![newVal isEqualToString:s])
			self.mCountField.text = newVal;
	}

	self.mNextBtn.enabled = (count > 0);

	// Note: if dataField is not in Observation, the following code will crash.
	NSString *dataField = [self.mScreenDict objectForKey:@"dataField"];
	if (dataField)
	{
		[self.mObservation setValue:[NSNumber numberWithInteger:count]
							 forKey:dataField];
	}
}


-(IBAction)onExactOrEstimateChange:(id)aSender
{
	// This code assumes there is a data field with the suffix "IsEstimated".
	NSString *dataField = [self.mScreenDict objectForKey:@"dataField"];
	if (dataField)
	{
		BOOL isEstimated = (1 == self.mExactOrEstimateCtrl.selectedSegmentIndex);
		dataField = [dataField stringByAppendingString:@"IsEstimated"];
		[self.mObservation setValue:[NSNumber numberWithBool:isEstimated]
							 forKey:dataField];
	}	
}


#pragma mark Private Methods
-(void)onNextPress:(id)aSender
{
	NSString *nextScreen = [self.mScreenDict objectForKey:@"next"];
	[[BioKIDSUtil sharedBioKIDSUtil] pushViewControllerForScreen:nextScreen
									navController:self.navigationController
									observation:self.mObservation];
}


- (void)repositionViews
{
	UIInterfaceOrientation orientation =
				[[UIApplication sharedApplication] statusBarOrientation];
	BOOL isIPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
	BOOL treatAsLandscape = (!isIPad) && UIDeviceOrientationIsLandscape(orientation);
	CGFloat barHeightAdjustment = 0.0;
	BioKIDSUtil *bku = [BioKIDSUtil sharedBioKIDSUtil];
	if (![bku systemVersionIsAtLeast:@"7.0"])
	{
		barHeightAdjustment = (treatAsLandscape) ? -kIOS6BarHeightLandscape
												 : -kIOS6BarHeightPortrait;
	}
	
	
	UIView *container = [self.view viewWithTag:kCountContainerViewTag];
	if (container)
	{
		CGRect r = container.frame;
		r.origin.y = (treatAsLandscape) ? kCountContainerLandscapeY
										: kCountContainerPortraitY;
		r.origin.y += barHeightAdjustment;
		container.frame = r;
	}
	
	CGRect r = self.mNextBtn.superview.frame;
	r.origin.y = (treatAsLandscape) ? kNextBtnLandscapeY : kNextBtnPortraitY;
	r.origin.y += barHeightAdjustment;
	self.mNextBtn.superview.frame = r;
}
@end
