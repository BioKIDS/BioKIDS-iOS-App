/*
  SeqLocationVC.m

  Copyright (c) 2013 The Regents of the University of Michigan

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

#import "SeqLocationVC.h"
#import "Constants.h"
#import "BioKIDSUtil.h"


// Declare private methods.
@interface SeqLocationVC()
- (void)repositionNextButton;
- (void)onNextPress:(id)aSender;
@end


@implementation SeqLocationVC

@synthesize mScreenDict, mObservation, mLocDesc, mLatLong, mNextBtn;

// Constants:
static const CGFloat kNextButtonOffsetY = 25.0;	// Distance below lat/long field.


-(id) initWithScreen:(NSDictionary *)aScreen
		 observation:(Observation *)aObservation
{
	if (!aScreen || !aObservation)
		return nil;

	self = [super initWithNibName:@"SeqLocationVC" bundle:nil];
	if (self)
	{
		self.mScreenDict = aScreen;
		self.mObservation = aObservation;
	}

	return self;
}


- (void) dealloc
{
	self.mScreenDict = nil;
	self.mObservation = nil;
	self.mLocDesc = nil;
	self.mLatLong = nil;
	self.mNextBtn = nil;

	[super dealloc];
}


- (void) didReceiveMemoryWarning
{
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];

	// Release any cached data, images, etc that aren't in use.
}


#pragma mark - View lifecycle
- (void) viewDidLoad
{
	[super viewDidLoad];

	BioKIDSUtil *bku = [BioKIDSUtil sharedBioKIDSUtil];
	self.view.backgroundColor = [bku appBackgroundColor];
	[bku useBackButtonLabel:self];

	NSString *title = [self.mScreenDict objectForKey:@"title"];
	[bku configureNavTitle:title forVC:self];

	// Add Next button.
	CGFloat w = self.view.frame.size.width;
	self.mNextBtn = [bku nextButtonForView:w];
	[self.mNextBtn addTarget:self action:@selector(onNextPress:)
			forControlEvents:UIControlEventTouchUpInside];
	self.mNextBtn.enabled = YES;
	[self.view addSubview:self.mNextBtn];

	// Set text color for all UILabel views.
	for (UIView *v in self.view.subviews)
	{
		if ([v isKindOfClass:[UILabel class]])
			((UILabel *)v).textColor = [bku titleTextColor];
	}

	// On iPad, change keyboard "Done" to "Next"
	BOOL isIPad = [[UIDevice currentDevice] userInterfaceIdiom]
					== UIUserInterfaceIdiomPad;
	if (isIPad)
		self.mLocDesc.returnKeyType = UIReturnKeyNext;

	// Restore last value used (if any).
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	NSString *s = [ud stringForKey:kLastLocationDescriptionKey];
	if (s)
	{
		self.mLocDesc.text = s;
		NSString *dataField = [self.mScreenDict objectForKey:@"dataField"];
		if (dataField)
			[self.mObservation setValue:s forKey:dataField];
	}
}


- (void) viewDidUnload
{
	[super viewDidUnload];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void) viewWillAppear:(BOOL)aAnimated
{
	// Update lat/long location.
	[self.mObservation updateLocation];
	NSString *s = [self.mObservation latLongString];
	if (!s)
		s = NSLocalizedString(@"NoLatLongMsg", nil);

	self.mLatLong.text = s;

	[self repositionNextButton];

	[super viewWillAppear:aAnimated];
}


- (void) viewWillDisappear:(BOOL)aAnimated
{
	if ([[BioKIDSUtil sharedBioKIDSUtil]
								sequenceViewIsDisappearingDueToBack:self])
	{
		// Back was pressed.  Clear our data field.
		NSString *dataField = [self.mScreenDict objectForKey:@"dataField"];
		if (dataField)
			[self.mObservation setValue:nil forKey:dataField];
	}

	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super viewWillDisappear:aAnimated];
}


- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)aOrient
{
	return YES;
}


#pragma mark Other Public Methods
- (IBAction) onLocationDescriptionChange:(id)aSender
{
	NSString *newValue = self.mLocDesc.text;

	NSString *dataField = [self.mScreenDict objectForKey:@"dataField"];
	if (dataField)
		[self.mObservation setValue:newValue forKey:dataField];

	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	[ud setValue:newValue forKey:kLastLocationDescriptionKey];
	[ud synchronize];
}


#pragma mark UITextFieldDelegate Methods
- (BOOL) textFieldShouldReturn:(UITextField *)aTextField
{
	[aTextField resignFirstResponder];
	if (self.mLocDesc.returnKeyType == UIReturnKeyNext)
		[self onNextPress:nil];

	return NO;	// suppress default behavior
}


#pragma mark Private Methods
- (void) repositionNextButton
{
	// Position the Next button below the other fields.
	CGRect latLongFrame = self.mLatLong.frame;
	CGRect r = self.mNextBtn.frame;
	r.origin.y = latLongFrame.origin.y + latLongFrame.size.height
					+ kNextButtonOffsetY;
	self.mNextBtn.frame = r;
}


// onNextPress is sometimes called with a nil aSender.
- (void) onNextPress:(id)aSender
{
	[self.mLocDesc resignFirstResponder];

	NSString *nextScreen = [self.mScreenDict objectForKey:@"next"];
	[[BioKIDSUtil sharedBioKIDSUtil] pushViewControllerForScreen:nextScreen
										navController:self.navigationController
										observation:self.mObservation];
}

@end
