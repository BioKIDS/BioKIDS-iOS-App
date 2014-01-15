/*
  ServerVC.m
  Created 8/22/11.

  Copyright (c) 2011-2014 The Regents of the University of Michigan

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
- (BOOL)haveEmailSettings;
- (BOOL)haveServerSettings;
- (void)resetUpload;
- (void)newUploadStatus:(BioKIDSUploadStatus)aStatus animate:(BOOL)aAnimate;
- (void)uploadComplete:(NSNotification *)aNotification;
- (void)promptToDeleteAll:(NSString *)aPromptString fromButton:(UIButton *)aBtn;
@end


@implementation ServerVC

@synthesize mObsLabel, mEmailBtn, mSaveBtn, mSettingsBtn, mDeleteAllBtn, mSpinner;
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
	self.mEmailBtn = nil;
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

	self.view.backgroundColor = [self.mUtil appBackgroundColor];
	[self.mUtil useBackButtonLabel:self];
	self.navigationItem.title = NSLocalizedString(@"ShareObservationsTitle", nil);

	self.mObsLabel.textColor = [self.mUtil titleTextColor];
	self.mErrorLabel.textColor = [self.mUtil titleTextColor];

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

	// Display/Clear "check your email settings" error message as appropriate.
	NSString *errMsg = NSLocalizedString(@"NoEmailSettings", nil);
	if (![self haveEmailSettings])
		self.mErrorLabel.text = errMsg;
	else if ([self.mErrorLabel.text isEqualToString:errMsg])
		self.mErrorLabel.text = nil;

	[self resetUpload];
}


- (void)viewDidDisappear:(BOOL)aAnimated
{
	[super viewWillDisappear:aAnimated];

	[self.mUtil closePopoversAndAlerts:nil];
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


#pragma mark MFMailComposeViewControllerDelegate Methods
- (void)mailComposeController:(MFMailComposeViewController *)aController
          didFinishWithResult:(MFMailComposeResult)aResult
                        error:(NSError *)aError;
{
	if (aResult == MFMailComposeResultFailed)
	{
		NSString *msg = aError ? [aError localizedDescription] : @"";
		NSString *fmt = NSLocalizedString(@"SendEmailErrorFmt", nil);
		self.mErrorLabel.text = [NSString stringWithFormat:fmt, msg];
	}

	BOOL wasSentOrSaved = (aResult == MFMailComposeResultSent)
							|| (aResult == MFMailComposeResultSaved);
	[self dismissViewControllerAnimated:YES completion:^{
		if (wasSentOrSaved)
		{
			NSString *prompt = NSLocalizedString(@"DeleteAfterEmailPrompt", nil);
			[self promptToDeleteAll:prompt fromButton:self.mEmailBtn];
		}
	}];
}


#pragma mark Other Public Methods
- (IBAction) onSendEmail:(id)aSender
{
	if (![self haveEmailSettings])
		return;

	MFMailComposeViewController *controller =
								[[MFMailComposeViewController alloc] init];
	controller.mailComposeDelegate = self;
	[controller setSubject:NSLocalizedString(@"EmailSubject", nil)];
	NSString *s = [self.mUtil csvForObservations];
//	NSLog(@"CSV data:\n%@", s);
	NSData *csvData = [s dataUsingEncoding:NSUTF8StringEncoding];
	[controller addAttachmentData:csvData mimeType:@"text/csv;charset=utf-8"
						 fileName:@"observations.csv"];
	NSArray *imagePathArray = [self.mUtil imagePathsForObservations];
	for (NSString *imgPath in imagePathArray)
	{
		NSData *imgData = [NSData dataWithContentsOfFile:imgPath];
		NSString *imgName = [imgPath lastPathComponent];
		[controller addAttachmentData:imgData mimeType:@"image/jpeg"
							 fileName:imgName];
	}

	if (controller)
		[self presentViewController:controller animated:YES completion:nil];
	[controller release];
}


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

	[self promptToDeleteAll:prompt fromButton:self.mDeleteAllBtn];
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
- (BOOL)haveEmailSettings
{
	return [MFMailComposeViewController canSendMail];
}


- (BOOL)haveServerSettings
{
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	NSString *url = [ud valueForKey:kServerURLKey];
	NSString *userName = [ud valueForKey:kUserNameKey];
	NSString *pwd = [self.mUtil retrievePassword];
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
		self.mEmailBtn.hidden = NO;
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
			self.mEmailBtn.enabled = NO;
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

			self.mEmailBtn.enabled = [self haveEmailSettings] &&
										(self.mUnsavedCount != 0);
			self.mSaveBtn.enabled = [self haveServerSettings];
			self.mDeleteAllBtn.enabled = YES;
		}
	}
	else
	{
		self.mEmailBtn.hidden = YES;
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


- (void) promptToDeleteAll:(NSString *)aPromptString fromButton:(UIButton *)aBtn
{
	NSString *cancelTitle = NSLocalizedString(@"CancelTitle", nil);
	NSString *deleteTitle = NSLocalizedString(@"DeleteAllObsTitle", nil);
	UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:aPromptString
									delegate:self cancelButtonTitle:cancelTitle
									destructiveButtonTitle:deleteTitle
									otherButtonTitles:nil];
	as.actionSheetStyle = UIActionSheetStyleDefault;
	[as showFromRect:aBtn.frame inView:self.view animated:NO];
	[as release];
}

@end
