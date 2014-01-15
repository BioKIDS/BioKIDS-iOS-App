/*
  HomeVC.m
  Created 9/19/11.

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

#import "HomeVC.h"
#import "Constants.h"
#import "InfoVC.h"
#import "ObservationsVC.h"
#import "ServerVC.h"
#import "SettingsVC.h"


// Declare private methods.
@interface HomeVC()
	- (void)configureViewForOrientationAndSize;
	- (void)configureSettingsLabels;
	- (void)pushViewController:(UIViewController *)aVC;
	- (BOOL)needToEnterSettings;
@end


@implementation HomeVC

@synthesize mBGImageView, mKidsImageView, mObserveButton;
@synthesize mBioKIDSIDLabel, mTrackerLabel, mZoneLabel;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self)
	{
		// Custom initialization
	}

	return self;
}


- (void)dealloc
{
	self.mBGImageView = nil;
	self.mKidsImageView = nil;
	self.mObserveButton = nil;
	self.mBioKIDSIDLabel = nil;
	self.mTrackerLabel = nil;
	self.mZoneLabel = nil;

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

	// Set kids" image.
	BOOL isIPad = [[UIDevice currentDevice] userInterfaceIdiom]
						== UIUserInterfaceIdiomPad;
	NSString *kidsFileName = (isIPad) ? @"home-kids-ipad.png"
									  : @"home-kids-iphone.png";
	UIImage *kidsImage = [UIImage imageNamed:kidsFileName];
	self.mKidsImageView.image = kidsImage;
	CGRect kidsRect = self.mKidsImageView.frame;
	kidsRect.size = kidsImage.size;
	self.mKidsImageView.frame = kidsRect;

	// Set observe button highlight image.
	NSString *highlightFileName = (isIPad) ? @"observe-highlight-ipad.png"
										   : @"observe-highlight-iphone.png";
	UIImage *highlightImage = [UIImage imageNamed:highlightFileName];
	[self.mObserveButton setBackgroundImage:highlightImage
						 forState:UIControlStateHighlighted];
	CGRect observeBtnRect = self.mObserveButton.frame;
	observeBtnRect.size = highlightImage.size;
	self.mObserveButton.frame = observeBtnRect;
	if (!isIPad)
	{
		UIFont *font = [self.mObserveButton.titleLabel.font fontWithSize:30.0];
		self.mObserveButton.titleLabel.font = font;
		self.mObserveButton.titleEdgeInsets = UIEdgeInsetsMake(50.0, 0.0, 0.0, 0.0);
	}
}


- (void) viewWillAppear:(BOOL)aAnimated
{
	[super viewWillAppear:aAnimated];

	[self.navigationController setNavigationBarHidden:YES animated:YES];

	[self configureViewForOrientationAndSize];
	[self configureSettingsLabels];

	[[BioKIDSUtil sharedBioKIDSUtil] startFetchingLocation];
}


#ifdef BIOKIDS_LAUNCH_IMAGE
- (BOOL) prefersStatusBarHidden
{
	return YES;
}
#endif


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)aOrientation
{
	return YES;
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)aFromInterfaceOrientation
{
	[self configureViewForOrientationAndSize];
}


#pragma mark UIAlertViewDelegate methods
- (void)alertView:(UIAlertView *)aView didDismissWithButtonIndex:(NSInteger)aIdx
{
	UIViewController *vc = [[SettingsVC alloc] init];
	[self pushViewController:vc];
	[vc release];
}


#pragma mark Public Methods
- (IBAction)onAboutTap:(id)aSender
{
	NSString *title = NSLocalizedString(@"AboutTitle", nil);
	InfoVC *vc = [[InfoVC alloc] initWithHTMLFile:@"about" title:title
												   delegate:nil];
	[self pushViewController:vc];
	[vc release];
}


- (IBAction)onObserveTap:(id)aSender
{
	if (![self needToEnterSettings])
	{
		ObservationsVC *vc = [[ObservationsVC alloc] init];
		[self pushViewController:vc];
		[vc release];
	}
}


- (IBAction)onSaveToServerTap:(id)aSender
{
	ServerVC *vc = [[ServerVC alloc] init];
	[self pushViewController:vc];
	[vc release];
}


- (IBAction)onSettingsTap:(id)aSender
{
	SettingsVC *vc = [[SettingsVC alloc] init];
	[self pushViewController:vc];
	[vc release];
}


#pragma mark Private Methods
- (void)configureViewForOrientationAndSize
{
	UIInterfaceOrientation orientation =
					[[UIApplication sharedApplication] statusBarOrientation];
	BOOL isIPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;

	// Set background image.
	NSString *bgFileName = nil;
	if (UIDeviceOrientationIsLandscape(orientation))
	{
		bgFileName = (isIPad) ? @"home-ipad-landscape.png"
							  : @"home-iphone-landscape.png";
	}
	else
	{
		bgFileName = (isIPad) ? @"home-ipad-portrait.png"
							  : @"home-iphone-portrait.png";
	}

	UIImage *bgImage = [UIImage imageNamed:bgFileName];
	self.mBGImageView.image = bgImage;
}


- (void)configureSettingsLabels
{
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

	self.mBioKIDSIDLabel.text = [ud stringForKey:kBioKIDSIDKey];
	self.mTrackerLabel.text = [ud stringForKey:kTrackerKey];
	self.mZoneLabel.text = [ud stringForKey:kZoneKey];
}


- (void)pushViewController:(UIViewController *)aVC
{
	if (!aVC)
		return;

	[self.navigationController pushViewController:aVC animated:YES];
	[self.navigationController setNavigationBarHidden:NO animated:YES];
}


- (BOOL)needToEnterSettings
{
	BioKIDSUtil *bku = [BioKIDSUtil sharedBioKIDSUtil];
	if ([bku haveSettings])
		return NO;

	NSString *s = NSLocalizedString(@"SettingsRequired", nil);
	[bku showAlert:s delegate:self];
	return YES;
}

@end
