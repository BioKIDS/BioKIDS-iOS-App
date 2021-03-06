/*
  ServerVC.h
  Created 8/22/11.

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

#import <UIKit/UIKit.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "BioKIDSUtil.h"

@interface ServerVC : UIViewController<UITextFieldDelegate,
										UIActionSheetDelegate,
										MFMailComposeViewControllerDelegate>
{
	UILabel *mObsLabel;
	UIButton *mEmailBtn;
	UIButton *mSaveBtn;
	UIButton *mSettingsBtn;
	UIButton *mDeleteAllBtn;
	UIActivityIndicatorView *mSpinner;
	UILabel *mErrorLabel;
	@private BioKIDSUtil *mUtil;
	@private NSUInteger mUnsavedCount;
	@private BOOL mLastSaveSucceeded;
}

@property (nonatomic, retain) IBOutlet UILabel *mObsLabel;
@property (nonatomic, retain) IBOutlet UIButton *mEmailBtn;
@property (nonatomic, retain) IBOutlet UIButton *mSaveBtn;
@property (nonatomic, retain) IBOutlet UIButton *mSettingsBtn;
@property (nonatomic, retain) IBOutlet UIButton *mDeleteAllBtn;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *mSpinner;
@property (nonatomic, retain) IBOutlet UILabel *mErrorLabel;
@property (nonatomic, retain) BioKIDSUtil *mUtil;
@property (nonatomic, assign) NSUInteger mUnsavedCount;
@property (nonatomic, assign) BOOL mLastSaveSucceeded;

// Declare public methods.
- (IBAction) onSendEmail:(id)aSender;
- (IBAction) onSavePress:(id)aSender;
- (IBAction) onSettingsPress:(id)aSender;
- (IBAction) onDeleteAllPress:(id)aSender;

@end
