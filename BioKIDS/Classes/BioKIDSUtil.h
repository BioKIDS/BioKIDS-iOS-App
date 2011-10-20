/*
  BioKIDSUtil.h
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

#import <Foundation/Foundation.h>
#import "Observation.h"


typedef enum
{
	UploadStatusIdle = 0,
	UploadStatusInProgress
} BioKIDSUploadStatus;

@interface BioKIDSUtil : NSObject
{
	@private BOOL mIsFinishingSequence;
	@private BioKIDSUploadStatus mUploadStatus;
	@private NSArray *mObsToUpload;
	@private NSURLConnection *mConnection;
}

@property (nonatomic, assign) BOOL mIsFinishingSequence;
@property (nonatomic, assign) BioKIDSUploadStatus mUploadStatus;
@property (nonatomic, retain) NSArray *mObsToUpload;
@property (nonatomic, retain) NSURLConnection *mConnection;


// Declare public methods.
+ (BioKIDSUtil *)sharedBioKIDSUtil;
- (void)showAlert:(NSString *)aMsg delegate:(id<UIAlertViewDelegate>)aDelegate;
- (void) closePopoversAndAlerts:(UIView *)aParentView;
- (BOOL)haveSettings;
- (void)useBackButtonLabel:(UIViewController *)aVC;
- (void)configureNavTitle:(NSString *)aTitle forVC:(UIViewController *)aVC;
- (void)pushViewControllerForScreen:(NSString *)aName
					  navController:(UINavigationController *)aNavController
						observation:(Observation *)aObservation;
- (BOOL)sequenceViewIsDisappearingDueToBack:(UIViewController *)aVC;
- (void)configureSeqCellLabel:(UITableViewCell *)aCell;
- (UIButton *)nextButtonForView:(CGFloat)aParentViewWidth;
- (void)addTextHeaderForTable:(UITableView *)aTableView text:(NSString *)aText;
- (void)resizeTextHeaderForTable:(UITableView *)aTableView;
- (NSUInteger)prepareForUpload;
- (void)discardUploadData:(BOOL)aDeleteObservations;
- (BioKIDSUploadStatus)startUpload;
- (BioKIDSUploadStatus)uploadStatus;
- (OSStatus)storePassword:(NSString *)aPassword;
- (NSString *)retrievePassword;

@end
