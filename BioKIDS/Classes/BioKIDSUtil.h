/*
  BioKIDSUtil.h
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

#import <Foundation/Foundation.h>
#import "Observation.h"
#import "BioKIDSLocationManager.h"


typedef enum
{
	UploadStatusIdle = 0,
	UploadStatusInProgress
} BioKIDSUploadStatus;

@interface BioKIDSUtil : NSObject<BioKIDSLocationManagerDelegate>
{
	@private BOOL mIsFinishingSequence;
	@private CLLocation *mCachedLocation;
	@private BioKIDSLocationManager *mBioKIDSLocationManager;	// non-nil if currently fetching location
	@private BioKIDSUploadStatus mUploadStatus;
	@private NSArray *mObsToUpload;
	@private NSURLConnection *mConnection;
}

@property (nonatomic, assign) BOOL mIsFinishingSequence;
@property (nonatomic, retain) CLLocation *mCachedLocation;
@property (nonatomic, retain) BioKIDSLocationManager *mBioKIDSLocationManager;
@property (nonatomic, assign) BioKIDSUploadStatus mUploadStatus;
@property (nonatomic, retain) NSArray *mObsToUpload;
@property (nonatomic, retain) NSURLConnection *mConnection;


// Declare public methods.
+ (BioKIDSUtil *)sharedBioKIDSUtil;
- (BOOL) systemVersionIsAtLeast:(NSString *)aVersion;
- (UIColor *)titleTextColor;
- (UIColor *)appBackgroundColor;
- (void)showAlert:(NSString *)aMsg delegate:(id<UIAlertViewDelegate>)aDelegate;
- (void) closePopoversAndAlerts:(UIView *)aParentView;
- (BOOL)haveSettings;
- (BOOL)isPersonalUse;
- (void)useBackButtonLabel:(UIViewController *)aVC;
- (void)configureNavTitle:(NSString *)aTitle forVC:(UIViewController *)aVC;
- (void)pushViewControllerForScreen:(NSString *)aName
					  navController:(UINavigationController *)aNavController
						observation:(Observation *)aObservation;
- (BOOL)sequenceViewIsDisappearingDueToBack:(UIViewController *)aVC;
- (void)configureSeqCellLabel:(UITableViewCell *)aCell;
- (UIButton *)nextButtonForView:(CGFloat)aParentViewWidth;
- (UIFont *)fontForTextView;
- (UIView *)viewForText:(NSString *)aText withWidth:(CGFloat)aWidth;
- (CGFloat) tableSectionHeaderSideMargin;
- (void)resizeTextHeaderForTable:(UITableView *)aTableView;
- (void) addEmptyHeaderAndFooterForTable:(UITableView *)aTableView;
- (CGFloat) idealHeightForString:(NSString *)aString withFont:(UIFont *)aFont
				   lineBreakMode:(NSLineBreakMode)aLineBreakMode
						   width:(CGFloat)aWidth;
- (void)useLowestPossiblePhotoID;
- (NSString *)nextPhotoFileNameWithTracker:(NSString *)aTracker;
- (void) startFetchingLocation;
- (CLLocation *)recentValidLocation;
- (NSUInteger)prepareForUpload;
- (void)discardUploadData:(BOOL)aDeleteObservations;
- (NSMutableString *)csvForObservations;
- (NSArray *)imagePathsForObservations;
- (BioKIDSUploadStatus)startUpload;
- (BioKIDSUploadStatus)uploadStatus;
- (OSStatus)storePassword:(NSString *)aPassword;
- (NSString *)retrievePassword;

@end
