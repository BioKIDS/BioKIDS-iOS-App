/*
  ServerSettingsVC.m
  Created 9/28/11.

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

#import "ServerSettingsVC.h"
#import "BioKIDSUtil.h"
#import "Constants.h"
#import <QuartzCore/QuartzCore.h>	// Needed for layer.cornerRadius


// Declare private methods.
@interface ServerSettingsVC()
- (void) onKeyboardWillShow:(NSNotification *)aNotification;
- (void) onKeyboardWillHide:(NSNotification *)aNotification;
- (void) ensureActiveFieldIsVisible;
@end


@implementation ServerSettingsVC

// Define constants
const NSInteger kContainerTag = 200;

@synthesize mServerURLField, mUserNameField, mPasswordField;
@synthesize mKeyboardRect, mActiveField;


- (id)init
{
	self = [super initWithNibName:@"ServerSettingsVC" bundle:nil];
	if (self)
	{
		// Custom initialization
	}

	return self;
}


- (void)dealloc
{
	self.mServerURLField = nil;
	self.mUserNameField = nil;
	self.mPasswordField = nil;
	self.mActiveField = nil;

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

	self.navigationItem.title = NSLocalizedString(@"ServerSettingsTitle", nil);

	UIView *containerView = [self.view viewWithTag:kContainerTag];
	if (containerView)
		containerView.layer.cornerRadius = 8.0;

	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	self.mServerURLField.text = [ud valueForKey:kServerURLKey];
	self.mUserNameField.text = [ud valueForKey:kUserNameKey];

	BioKIDSUtil *bku = [BioKIDSUtil sharedBioKIDSUtil];
	self.view.backgroundColor = [bku appBackgroundColor];
	self.mPasswordField.text = [bku retrievePassword];
}


- (void) viewWillAppear:(BOOL)aAnimated
{
	[super viewWillAppear:aAnimated];

	[[NSNotificationCenter defaultCenter] addObserver:self
								selector:@selector(onKeyboardWillShow:)
								name:UIKeyboardWillShowNotification
								object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
								selector:@selector(onKeyboardWillHide:)
								name:UIKeyboardWillHideNotification
								object:nil];
}


- (void) viewWillDisappear:(BOOL)aAnimated
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[super viewWillDisappear:aAnimated];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)aOrient
{
	return YES;
}


#pragma mark UITextFieldDelegate Methods
-(void)textFieldDidBeginEditing:(UITextField *)aSender
{
	self.mActiveField = aSender;
	[self ensureActiveFieldIsVisible];
}


-(void)textFieldDidEndEditing:(UITextField *)aSender
{
	self.mActiveField = nil;
}


- (BOOL)textFieldShouldReturn:(UITextField *)aTextField
{

	if (UIReturnKeyNext == aTextField.returnKeyType)
	{
		if (aTextField == self.mServerURLField)
			[self.mUserNameField becomeFirstResponder];
		else
			[self.mPasswordField becomeFirstResponder];
	}
	else
		[aTextField resignFirstResponder];

	return YES;
}


#pragma mark Other Public Methods
- (IBAction) onServerURLChange:(id)aSender
{
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	[ud setValue:self.mServerURLField.text forKey:kServerURLKey];
}


- (IBAction) onServerURLEditingDidEnd:(id)aSender
{
	if ([self.mServerURLField.text isEqualToString:@"det"])
	{
		self.mServerURLField.text = NSLocalizedString(@"DefaultServerURL", nil);
		[self onServerURLChange:aSender];
	}
}


- (IBAction) onUserNameChange:(id)aSender
{
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	[ud setValue:self.mUserNameField.text forKey:kUserNameKey];
}


- (IBAction) onPasswordChange:(id)aSender
{
	BioKIDSUtil *bku = [BioKIDSUtil sharedBioKIDSUtil];
	[bku storePassword:self.mPasswordField.text];
}

#pragma mark Private Methods
- (void) onKeyboardWillShow:(NSNotification *)aNotification
{
	id val = [aNotification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
	if (val)
	{
		CGRect kbdRect = {0};
		[val getValue:&kbdRect];

		// Convert from screen coordinates to view coordinates.
		kbdRect = [self.view.window convertRect:kbdRect fromWindow:nil];
		self.mKeyboardRect = [self.view convertRect:kbdRect fromView:nil];

		[self ensureActiveFieldIsVisible];
	}
}


- (void) onKeyboardWillHide:(NSNotification *)aNotification
{
	CGRect r = self.view.frame;
	if (r.origin.y < 0.0)
	{
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.5];
		r.size.height += r.origin.y;
		r.origin.y = 0.0;
		self.view.frame = r;
		[UIView commitAnimations];

		self.mKeyboardRect = CGRectZero;
	}
}


- (void) ensureActiveFieldIsVisible
{
	if (CGRectIsEmpty(self.mKeyboardRect))
		return;

	// If active text field and its label are not visible, move the view
	// up until they are.
	CGFloat deltaY = 0.0;
	CGRect fieldRect = [self.view convertRect:self.mActiveField.frame
									 fromView:self.mActiveField.superview];
	CGFloat fieldBottom = fieldRect.origin.y + fieldRect.size.height;
	if (fieldBottom < 0.0)
	{
		// The field is scrolled off the top of the view.  This won't
		// happen for this view because there is no way to return to the
		// top field.
	}
	else if (fieldBottom > self.mKeyboardRect.origin.y)
	{
		// The field is under the keyboard.  Move view up to reveal it.
		deltaY = self.mKeyboardRect.origin.y - fieldBottom - 4.0;
	}

	if (0.0 != deltaY)
	{
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.5];
		CGRect r = self.view.frame;
		r.origin.y += deltaY;
		r.size.height -= deltaY;
		self.view.frame = r;
		[UIView commitAnimations];

		self.mKeyboardRect = CGRectOffset(self.mKeyboardRect, 0.0, -deltaY);
	}
}

@end
