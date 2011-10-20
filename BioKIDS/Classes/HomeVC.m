/*
  HomeVC.m
  Created 9/19/11.

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

@synthesize mBGImageView, mObserveButton;
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
- (void) viewWillAppear:(BOOL)aAnimated
{
	[super viewWillAppear:aAnimated];

	[self.navigationController setNavigationBarHidden:YES animated:YES];

	[self configureViewForOrientationAndSize];
	[self configureSettingsLabels];
}


- (void)viewDidUnload
{
	[super viewDidUnload];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


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
	BOOL isLargeScreen = (self.view.frame.size.width > 480);
	CGRect observeBtnRect = {0};

	NSString *bgFileName = nil;
	NSString *highlightFileName = nil;
	if (UIDeviceOrientationIsLandscape(orientation))
	{
		if (isLargeScreen)
		{
			bgFileName = @"home-ipad-landscape.png";
			highlightFileName = @"observe-highlight-ipad-landscape.png";
			observeBtnRect = CGRectMake(150.0, 338.0, 719.0, 266.0);
		}
		else
		{
			bgFileName = @"home-iphone-landscape.png";
			highlightFileName = @"observe-highlight-iphone-landscape.png";
			observeBtnRect = CGRectMake(65.0, 136.0, 360.0, 146.0);
		}
	}
	else if (isLargeScreen)
	{
		bgFileName = @"home-ipad-portrait.png";
		highlightFileName = @"observe-highlight-ipad-portrait.png";
		observeBtnRect = CGRectMake(23.0, 465.0, 718.0, 292.0);
	}
	else
	{
		bgFileName = @"home-iphone-portrait.png";
		highlightFileName = @"observe-highlight-iphone-portrait.png";
		observeBtnRect = CGRectMake(4.0, 178.0, 304.0, 154.0);
	}

	UIImage *bgImage = [UIImage imageNamed:bgFileName];
	self.mBGImageView.image = bgImage;

	self.mObserveButton.frame = observeBtnRect;
	UIImage *highlightImage = nil;
	if (highlightFileName)
		highlightImage = [UIImage imageNamed:highlightFileName];
	[self.mObserveButton setImage:highlightImage
						 forState:UIControlStateHighlighted];		
}


- (void)configureSettingsLabels
{
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

	NSString *biokidsID = [ud stringForKey:kBioKIDSIDKey];
	self.mBioKIDSIDLabel.text = (biokidsID) ?
						[NSString stringWithFormat:@"# %@", biokidsID] : nil;
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
	BioKIDSUtil *bu = [BioKIDSUtil sharedBioKIDSUtil];
	if ([bu haveSettings])
		return NO;

	NSString *s = NSLocalizedString(@"SettingsRequired", nil);
	[bu showAlert:s delegate:self];
	return YES;
}

@end
