/*
  ServerVC.m
  Created 8/22/11.

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

#import "ServerVC.h"
#import "Constants.h"
#import "ServerSettingsVC.h"


// Declare Private Methods
@interface ServerVC()
- (BOOL)haveServerSettings;
- (void)resetUpload;
- (void)newUploadStatus:(BioKIDSUploadStatus)aStatus animate:(BOOL)aAnimate;
- (void)uploadComplete:(NSNotification *)aNotification;
@end


@implementation ServerVC

@synthesize mObsLabel, mSaveBtn, mSettingsBtn, mDeleteAllBtn, mSpinner;
@synthesize mErrorLabel, mUtil, mUnsavedCount, mLastSaveSucceeded;


- (id)init
{
	self = [super initWithNibName:@"ServerVC" bundle:nil];
	if (self)
	{
		self.mUtil = [BioKIDSUtil sharedBioKIDSUtil];
	}
	
	return self;
}


- (void)dealloc
{
	[self.mUtil discardUploadData:NO];

	self.mObsLabel = nil;
	self.mSaveBtn = nil;
	self.mSettingsBtn = nil;
	self.mDeleteAllBtn = nil;
	self.mSpinner = nil;
	self.mErrorLabel = nil;
	self.mUtil = nil;

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
	self.navigationItem.title = NSLocalizedString(@"ServerTitle", nil);

	[[NSNotificationCenter defaultCenter] addObserver:self
						selector:@selector(uploadComplete:)
						name:kNotificationUploadComplete
						object:nil];
}


- (void)viewDidUnload
{
	[super viewDidUnload];

	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)viewWillAppear:(BOOL)aAnimated
{
	[super viewWillAppear:aAnimated];

	[self resetUpload];
}


- (void)viewDidDisappear:(BOOL)aAnimated
{
	[super viewWillDisappear:aAnimated];

	[[BioKIDSUtil sharedBioKIDSUtil] closePopoversAndAlerts:nil];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)aOrient
{
	// Return YES for supported orientations
	return YES;
}


#pragma mark UITextFieldDelegate Methods
- (BOOL)textFieldShouldReturn:(UITextField *)aTextField
{
	// The user pressed the "Done" button, so dismiss the keyboard.
	[aTextField resignFirstResponder];
	return YES;
}


#pragma mark UIActionSheetDelegate method
- (void)actionSheet:(UIActionSheet *)aActionSheet
				clickedButtonAtIndex:(NSInteger)aButtonIndex
{
	if (aActionSheet.cancelButtonIndex == aButtonIndex)
		return; // Cancel.

	[self.mUtil discardUploadData:YES];
	self.mErrorLabel.text = nil;
	[self resetUpload];
}


#pragma mark Other Public Methods
- (IBAction) onSavePress:(id)aSender
{
	self.mErrorLabel.text = nil;
	BioKIDSUploadStatus status = [self.mUtil startUpload];
	[self newUploadStatus:status animate:YES];
}


- (IBAction) onDeleteAllPress:(id)aSender
{
	NSString *prompt = nil;
	if (1 == self.mUnsavedCount)
		prompt = NSLocalizedString(@"DeleteAllObsPromptOne", nil);
	else
	{
		NSString *fmt = NSLocalizedString(@"DeleteAllObsPromptFmt", nil);
		prompt = [NSString stringWithFormat:fmt, self.mUnsavedCount];
	}

	NSString *cancelTitle = NSLocalizedString(@"CancelTitle", nil);
	NSString *deleteTitle = NSLocalizedString(@"DeleteAllObsTitle", nil);
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:prompt
									delegate:self cancelButtonTitle:cancelTitle
									destructiveButtonTitle:deleteTitle
									otherButtonTitles:nil];
	actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
	[actionSheet showFromRect:self.mDeleteAllBtn.frame inView:self.view
					 animated:NO];
	[actionSheet release];
}


- (IBAction) onSettingsPress:(id)aSender
{
	ServerSettingsVC *vc = [[ServerSettingsVC alloc] init];
	if (vc)
	{
		[self.navigationController pushViewController:vc animated:YES];
		[vc release];
	}
}


#pragma mark Private Methods
- (BOOL)haveServerSettings
{
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	NSString *url = [ud valueForKey:kServerURLKey];
	NSString *userName = [ud valueForKey:kUserNameKey];
	NSString *pwd = [[BioKIDSUtil sharedBioKIDSUtil] retrievePassword];
	return ([url length] > 0) && ([userName length] > 0) && ([pwd length] > 0);
}


- (void)resetUpload
{
	BioKIDSUploadStatus status = [self.mUtil uploadStatus];
	[self newUploadStatus:status animate:NO];
}


- (void)newUploadStatus:(BioKIDSUploadStatus)aStatus animate:(BOOL)aAnimate
{
	NSString *labelText = nil;
	
	aAnimate = NO;		// TODOFuture: enable fade in/out animation of mObsLabel (enabling causes text to get clobbered).

	if (UploadStatusIdle == aStatus)
	{
		self.mSaveBtn.hidden = NO;
		self.mSettingsBtn.hidden = NO;
		self.mDeleteAllBtn.hidden = NO;
		[self.mSpinner stopAnimating];

		self.mUnsavedCount = [self.mUtil prepareForUpload];
		if (0 == self.mUnsavedCount)
		{
			if (self.mLastSaveSucceeded)
				labelText = NSLocalizedString(@"UploadOK", nil);
			else
				labelText = NSLocalizedString(@"NoObservationsToUpload", nil);
			self.mSaveBtn.enabled = NO;
			self.mDeleteAllBtn.enabled = NO;
		}
		else
		{
			if (1 == self.mUnsavedCount)
				labelText = NSLocalizedString(@"OneObservationToUpload", nil);
			else
			{
				NSString *fmt = NSLocalizedString(@"ObservationsToUploadFmt", nil);
				labelText = [NSString stringWithFormat:fmt, self.mUnsavedCount];
			}

			self.mSaveBtn.enabled = [self haveServerSettings];
			self.mDeleteAllBtn.enabled = YES;
		}
	}
	else
	{
		self.mSaveBtn.hidden = YES;
		self.mSettingsBtn.hidden = YES;
		self.mDeleteAllBtn.hidden = YES;
		[self.mSpinner startAnimating];
		labelText = NSLocalizedString(@"Uploading", nil);
	}

	if (!aAnimate)
		self.mObsLabel.text = labelText;
	else
	{
		// Fade out and back in when changing mObsLabel.
		NSTimeInterval duration = 0.5;
		[UIView animateWithDuration:duration
				animations:^
				{
					self.mObsLabel.alpha = 0.0;
				}
				completion:^(BOOL aFinished)
				{
					self.mObsLabel.text = labelText;
					[UIView animateWithDuration:duration
									 animations:^
					 {
						 self.mObsLabel.text = labelText;
						 self.mObsLabel.alpha = 1.0;
					 }
					 completion:^(BOOL aFinished)
					 {
					 }];
				}];
	}
}


- (void)uploadComplete:(NSNotification *)aNotification
{
	NSDictionary *d = [aNotification userInfo];
	NSString *errMsg = (d) ? [d objectForKey:@"errorMsg"]: nil;
	if (errMsg)
	{
		NSString *fmt = NSLocalizedString(@"UploadErrorFmt", nil);
		self.mErrorLabel.text = [NSString stringWithFormat:fmt, errMsg];
		self.mLastSaveSucceeded = NO;
	}
	else
		self.mLastSaveSucceeded = YES;

	[self newUploadStatus:[self.mUtil uploadStatus] animate:YES];
}

@end
