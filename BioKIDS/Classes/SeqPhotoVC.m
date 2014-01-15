/*
 SeqPhotoVC.m
 Created 10/20/13.
 
 Copyright (c) 2013-2014 The Regents of the University of Michigan
 
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


#import "SeqPhotoVC.h"
#import "Constants.h"
#import "BioKIDSUtil.h"
#import <QuartzCore/QuartzCore.h>

@interface SeqPhotoVC ()
- (NSString *) photoPath;
- (IBAction) onCapturePress:(id)aSender;
- (void) onNextPress:(id)aSender;
- (void) repositionViews;
@end


@implementation SeqPhotoVC

static const NSInteger kImagePreviewTag = 1000;
static const NSInteger kTakePhotoBtnTag = 1001;
static const CGFloat kImagePreviewBorderWidth = 2.0;
static const CGFloat kImagePreviewPortraitX = 36.0;
static const CGFloat kImagePreviewPortraitY = 74.0;
static const CGFloat kImagePreviewLandscapeX = 10.0;
static const CGFloat kImagePreviewLandscapeY = 62.0;

static const CGFloat kTakePhotoBtnPortraitX = 95.0;
static const CGFloat kTakePhotoBtnPortraitY = 344.0;
static const CGFloat kTakePhotoBtnLandscapeX = 290.0;
static const CGFloat kTakePhotoBtnLandscapeY = 112.0;

static const CGFloat kNextBtnWidth = 130.0;
static const CGFloat kNextBtnPortraitX = 95.0;
static const CGFloat kNextBtnPortraitY = 404.0;
static const CGFloat kNextBtnLandscapeX = 290.0;
static const CGFloat kNextBtnLandscapeY = 182.0;

static const CGFloat kIOS6BarHeightPortrait = 64.0;
static const CGFloat kIOS6BarHeightLandscape = 52.0;


-(id)initWithScreen:(NSDictionary *)aScreen
		observation:(Observation *)aObservation
{
	if (!aScreen || !aObservation)
		return nil;

	self = [super initWithNibName:@"SeqPhotoVC" bundle:nil];
	if (self)
	{
		self.mScreenDict = aScreen;
		self.mObservation = aObservation;

		// Add a border around the image preview.
		UIImageView *iv = (UIImageView *)[self.view viewWithTag:kImagePreviewTag];
		iv.layer.borderColor = [UIColor colorWithWhite:0.8 alpha:1.0].CGColor;
		iv.layer.borderWidth = kImagePreviewBorderWidth;
		iv.image = [UIImage imageNamed:@"photoPlaceholder.png"];
		iv.contentMode = UIViewContentModeCenter;

		// Add "Next" button.
		CGFloat w = kNextBtnWidth;
		self.mNextBtn = [[BioKIDSUtil sharedBioKIDSUtil] nextButtonForView:w];
		[self.mNextBtn addTarget:self action:@selector(onNextPress:)
							forControlEvents:UIControlEventTouchUpInside];
		CGRect r = self.mNextBtn.frame;
		r.origin.y = 0.0;
		self.mNextBtn.frame = r;

		r = CGRectMake(0, kNextBtnPortraitY, w, self.mNextBtn.frame.size.height);
		BOOL isIPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
		if (isIPad)
			r.origin.x = (self.view.frame.size.width - r.size.width) / 2.0;

		UIView *v = [[UIView alloc] initWithFrame:r];
		if (isIPad)
		{
			v.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin
									| UIViewAutoresizingFlexibleRightMargin;
		}
		else
			v.autoresizingMask = UIViewAutoresizingNone;

		[v addSubview:self.mNextBtn];
		[self.view addSubview:v];
		[v release];

		self.mNextBtn.enabled = YES;
	}

	return self;
}


- (void)viewDidLoad
{
	[super viewDidLoad];

	BioKIDSUtil *bku = [BioKIDSUtil sharedBioKIDSUtil];
	self.view.backgroundColor = [bku appBackgroundColor];
	[bku useBackButtonLabel:self];
	NSString *title = [self.mScreenDict objectForKey:@"title"];
	[bku configureNavTitle:title forVC:self];
}


- (void)viewWillAppear:(BOOL)aAnimated
{
	[super viewWillAppear:aAnimated];

	// Reposition views to account for orientation.
	[self repositionViews];
}


- (void)viewWillDisappear:(BOOL)aAnimated
{
	BioKIDSUtil *bku = [BioKIDSUtil sharedBioKIDSUtil];
	if ([bku sequenceViewIsDisappearingDueToBack:self])
	{
		// Back was pressed.  Clear our data field and delete associated image.
		NSString *dataField = [self.mScreenDict objectForKey:@"dataField"];
		if (dataField)
		{
			id valObj = [self.mObservation valueForKey:dataField];
			if ([valObj isKindOfClass:[NSString class]])
			{
				NSString *path = (NSString *)valObj;
				NSFileManager *fm = [NSFileManager defaultManager];
				NSError *err = nil;
				if (![fm removeItemAtPath:path error:&err])
				{
					NSLog(@"failed to remove image %@: %@\n",
						  path, [err localizedDescription]);
				}

				[bku useLowestPossiblePhotoID];
			}
			
			[self.mObservation setValue:nil forKey:dataField];
		}
	}

	[super viewWillDisappear:aAnimated];
}


- (void)viewDidAppear:(BOOL)aAnimated
{
	[super viewDidAppear:aAnimated];

	if (!self.mHasViewAppeared)
	{
		self.mHasViewAppeared = YES;

		if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
			; // [self onCapturePress:self.mTakePhotoBtn];
		else
			[self onNextPress:nil];
	}
}


- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)aOrient
{
	return YES;
}


- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)aFromOrient
{
	[self repositionViews];
}


#pragma mark UINavigationControllerDelegate methods
// Not needed at this time.


#pragma mark UIImagePickerControllerDelegate methods
- (void)imagePickerController:(UIImagePickerController *)aPicker
					didFinishPickingMediaWithInfo:(NSDictionary *)aInfo
{
	if (self.mPopOver)
	{
		[self.mPopOver dismissPopoverAnimated:YES];
		self.mPopOver = nil;
	}
	else
		[self dismissViewControllerAnimated:YES completion:nil];

	UIImage *image = [aInfo objectForKey:UIImagePickerControllerOriginalImage];
	if (image)
		[self pickedImage:image withInfo:aInfo];
}


- (void)pickedImage:(UIImage *)aImage withInfo:(NSDictionary *)aInfo
{
	UIImageView *iv = (UIImageView *)[self.view viewWithTag:kImagePreviewTag];

	if (!aImage)
	{
		iv.backgroundColor = [UIColor whiteColor];
		return;
	}

	NSString *path = [self photoPath];
	if (0 == [path length])
	{
		NSString *fileName = [[BioKIDSUtil sharedBioKIDSUtil]
						nextPhotoFileNameWithTracker:self.mObservation.Tracker];
		NSArray *array = NSSearchPathForDirectoriesInDomains(
								NSDocumentDirectory, NSUserDomainMask, YES);
		path = [[array lastObject] stringByAppendingPathComponent:fileName];
	}

	if (![UIImageJPEGRepresentation(aImage, 0.95) writeToFile:path
											options:NSAtomicWrite error:nil])
	{
		path = nil;
		aImage = nil;
	}

	NSString *dataField = [self.mScreenDict objectForKey:@"dataField"];
	if (dataField)
		[self.mObservation setValue:path forKey:dataField];

	iv.image = (aImage) ? aImage : [UIImage imageNamed:@"photoPlaceholder.png"];
	iv.layer.borderWidth = (aImage) ? 0.0 : kImagePreviewBorderWidth;
	iv.contentMode = (aImage) ? UIViewContentModeScaleAspectFit
							  : UIViewContentModeCenter;
	iv.backgroundColor = (aImage) ? [UIColor clearColor] : [UIColor whiteColor];
}


#pragma mark Private Methods
- (NSString *) photoPath
{
	NSString *dataField = [self.mScreenDict objectForKey:@"dataField"];
	if (dataField)
		return [self.mObservation valueForKey:dataField];

	return nil;
}


- (IBAction) onCapturePress:(id)aSender
{
	UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera;
	if (![UIImagePickerController isSourceTypeAvailable:sourceType])
		sourceType = UIImagePickerControllerSourceTypePhotoLibrary;

	UIImagePickerController *ipc = [[UIImagePickerController alloc] init];
	ipc.delegate = self;
	ipc.sourceType = sourceType;
	BOOL showPopup = NO;
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
	{
		ipc.modalPresentationStyle = UIModalPresentationCurrentContext;
		if (UIImagePickerControllerSourceTypeCamera != sourceType)
			showPopup = YES;
	}
	
	if (showPopup)
	{
		CGRect r = CGRectMake(0.0, 0.0, 1.0, 1.0);
		if ([aSender isKindOfClass:[UIView class]])
		{
			UIView *v = (UIView *)aSender;
			r = [self.view convertRect:v.frame fromView:v.superview];
		}
		UIPopoverController *popover = [[UIPopoverController alloc]
										initWithContentViewController:ipc];
		[popover presentPopoverFromRect:r inView:self.view
			   permittedArrowDirections:UIPopoverArrowDirectionAny
							   animated:YES];
		self.mPopOver = popover;
		[popover release];
	}
	else
		[self presentViewController:ipc animated:YES completion:nil];
}


- (void) onNextPress:(id)aSender
{
	NSString *nextScreen = [self.mScreenDict objectForKey:@"next"];
	[[BioKIDSUtil sharedBioKIDSUtil] pushViewControllerForScreen:nextScreen
									   navController:self.navigationController
										 observation:self.mObservation];
}


- (void) repositionViews
{
	BOOL isIPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
	if (isIPad)
		return;	// auto resizing is sufficient on iPad.

	UIInterfaceOrientation orientation =
					[[UIApplication sharedApplication] statusBarOrientation];
	BOOL isLandscape = UIDeviceOrientationIsLandscape(orientation);
	CGRect r;
	CGFloat barHeightAdjustment = 0.0;
	BioKIDSUtil *bku = [BioKIDSUtil sharedBioKIDSUtil];
	if (![bku systemVersionIsAtLeast:@"7.0"])
	{
		barHeightAdjustment = (isLandscape) ? -kIOS6BarHeightLandscape
											: -kIOS6BarHeightPortrait;
	}

	// Position the image view.
	UIView *iv = [self.view viewWithTag:kImagePreviewTag];
	if (iv)
	{
		r = iv.frame;
		r.origin.x = (isLandscape) ? kImagePreviewLandscapeX
								   : kImagePreviewPortraitX;
		r.origin.y = (isLandscape) ? kImagePreviewLandscapeY
								   : kImagePreviewPortraitY;
		r.origin.y += barHeightAdjustment;

		iv.frame = r;
	}

	// Position the "Take Photo" button.
	UIView *takePhotoBtn = [self.view viewWithTag:kTakePhotoBtnTag];
	if (takePhotoBtn)
	{
		r = takePhotoBtn.frame;
		r.origin.x = (isLandscape) ? kTakePhotoBtnLandscapeX
									: kTakePhotoBtnPortraitX;
		r.origin.y = (isLandscape) ? kTakePhotoBtnLandscapeY
									: kTakePhotoBtnPortraitY;
		r.origin.y += barHeightAdjustment;
		takePhotoBtn.frame = r;
	}

	// Position the "Next" button.
	r = self.mNextBtn.superview.frame;
	r.origin.x = (isLandscape) ? kNextBtnLandscapeX : kNextBtnPortraitX;
	r.origin.y = (isLandscape) ? kNextBtnLandscapeY : kNextBtnPortraitY;
	r.origin.y += barHeightAdjustment;
	self.mNextBtn.superview.frame = r;
}
@end
