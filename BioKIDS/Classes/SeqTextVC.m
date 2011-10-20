/*
  SeqTextVC.m
  Created 8/9/11.

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

#import "SeqTextVC.h"
#import "Constants.h"
#import "BioKIDSUtil.h"
#import <QuartzCore/CALayer.h>	// for self.mTextView.layer properties.


// Declare private methods.
@interface SeqTextVC()
	- (void)onDonePress:(id)aSender;
	- (void)onKeyboardWillShow:(NSNotification *)aNotification;
	- (void)flashScrollIndicators;
@end


@implementation SeqTextVC

@synthesize mScreenDict, mObservation, mTextView;

// Constants:
const CGFloat kTextViewBottomMargin = 8.0;


-(id)initWithScreen:(NSDictionary *)aScreen
		observation:(Observation *)aObservation
{
	if (!aScreen || !aObservation)
		return nil;
	
	self = [super initWithNibName:@"SeqTextVC" bundle:nil];
	if (self)
	{
		self.mScreenDict = aScreen;
		self.mObservation = aObservation;
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

	BioKIDSUtil *bku = [BioKIDSUtil sharedBioKIDSUtil];
	[bku useBackButtonLabel:self];
	NSString *title = [self.mScreenDict objectForKey:@"title"];
	[bku configureNavTitle:title forVC:self];
	
	NSString *action = [self.mScreenDict objectForKey:@"rightButtonAction"];
	if ([action isEqualToString:kSeqNameObservationList])
	{
		UIBarButtonItem *btn = [[UIBarButtonItem alloc]
						initWithBarButtonSystemItem:UIBarButtonSystemItemDone
								target:self action:@selector(onDonePress:)];
		self.navigationItem.rightBarButtonItem = btn;
		[btn release];
	}

	// Add rounded border to text view.
	self.mTextView.layer.borderColor = [[UIColor grayColor] CGColor];
	self.mTextView.layer.borderWidth = 1.0;
	self.mTextView.layer.cornerRadius = 6;
	
	// To allow time for the view "push" animation to finish, wait a short
	// time before flashing the scroll indicators.
	[self performSelector:@selector(flashScrollIndicators) withObject:nil
			   afterDelay:0.5];
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

	[[NSNotificationCenter defaultCenter] addObserver:self
									 selector:@selector(onKeyboardWillShow:)
										 name:UIKeyboardWillShowNotification
									   object:nil];
}


- (void)viewWillDisappear:(BOOL)aAnimated
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


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)aOrient
{
	return YES;
}


#pragma mark UITextViewDelegate Methods
- (void)textViewDidChange:(UITextView *)aTextView
{
	NSString *dataField = [self.mScreenDict objectForKey:@"dataField"];
	if (dataField)
		[self.mObservation setValue:aTextView.text forKey:dataField];
}


#pragma mark Private Methods
- (void)onDonePress:(id)aSender
{
	NSString *action = [self.mScreenDict objectForKey:@"rightButtonAction"];
	[[BioKIDSUtil sharedBioKIDSUtil] pushViewControllerForScreen:action
								   navController:self.navigationController
								   observation:self.mObservation];
}


- (void)flashScrollIndicators
{
	[self.mTextView flashScrollIndicators];
}


- (void)onKeyboardWillShow:(NSNotification *)aNotification
{
	// Set bottom coordinate of text view so it is just above keyboard.
	id val = [aNotification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
	if (val)
	{
		CGRect keyboardR = {0};
		[val getValue:&keyboardR];
		
		// Convert from screen coordinates to view coordinates.
		keyboardR = [self.view.window convertRect:keyboardR fromWindow:nil];
		keyboardR = [self.view convertRect:keyboardR fromView:nil];

		CGRect r = self.mTextView.frame;
		r.size.height = keyboardR.origin.y - kTextViewBottomMargin - r.origin.y;
		self.mTextView.frame = r;
	}
}

@end
