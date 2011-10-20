/*
  BioKIDSUtil.m
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

#import "BioKIDSUtil.h"
#import "Constants.h"
#import "BioKIDSAppDelegate.h"
#import "SeqChoose1VC.h"
#import "SeqChooseNVC.h"
#import "SeqCountVC.h"
#import "SeqTextVC.h"
#import "Observation.h"


static BioKIDSUtil *gSharedBioKIDSUtil = nil;

// Declare Private Methods
@interface BioKIDSUtil()
- (void)cancelUploadAndReportError:(NSString *)aMsg;
- (NSMutableDictionary *)passwordItemDict;
@end


@implementation BioKIDSUtil

@synthesize mIsFinishingSequence, mUploadStatus, mObsToUpload, mConnection;

// Define constants.
const NSInteger kTableHeaderLabelTag = 120;
const CGFloat kTableHeaderTopMargin = 8.0;
const CGFloat kTableHeaderBottomMargin = 2.0;


#pragma mark Public Methods
- (void)showAlert:(NSString *)aMsg delegate:(id<UIAlertViewDelegate>)aDelegate
{
	[self closePopoversAndAlerts:nil];

	NSString *title = NSLocalizedString(@"MainAppTitle", nil);
	NSString *okLabel = NSLocalizedString(@"OKButtonLabel", nil);
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
													message:aMsg
												   delegate:aDelegate
										  cancelButtonTitle:okLabel
										  otherButtonTitles:nil];
	[alert show];
	[alert release];
}


// Close all open alerts and action sheets.
- (void) closePopoversAndAlerts:(UIView *)aParentView
{
	if (!aParentView)
	{
		BioKIDSAppDelegate *ad = (BioKIDSAppDelegate *)
							[[UIApplication sharedApplication] delegate];
		aParentView = ad.window;
	}

	for (UIView *v in aParentView.subviews)
	{
		if ([v isKindOfClass:[UIAlertView class]])
			[(UIAlertView *)v dismissWithClickedButtonIndex:-1 animated:NO];
		else if ([v isKindOfClass:[UIActionSheet class]])
			[(UIActionSheet *)v dismissWithClickedButtonIndex:-1 animated:NO];
		else
			[self closePopoversAndAlerts:v];	// recurse.
	}
}


- (BOOL)haveSettings
{
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	NSString *bkidStr = [ud stringForKey:kBioKIDSIDKey];
	NSInteger bkid = [bkidStr integerValue];
	NSString *tracker = [ud stringForKey:kTrackerKey];
	NSString *zone = [ud stringForKey:kZoneKey];
	return (bkid != 0) && ([tracker length] > 0) && ([zone length] > 0);
}


- (void)useBackButtonLabel:(UIViewController *)aVC
{
	NSString *s = NSLocalizedString(@"BackTitle", nil);
	UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] initWithTitle:s
											style:UIBarButtonItemStyleBordered
										   target:nil action:nil];
	[aVC.navigationItem setBackBarButtonItem:backBtn];
	[backBtn release];
}


- (void)configureNavTitle:(NSString *)aTitle forVC:(UIViewController *)aVC
{
	CGRect appFrame = [UIScreen mainScreen].applicationFrame;
	if (appFrame.size.width > 480.0)	// Bigger than an iPhone/iPod touch?
	{
		aVC.navigationItem.title = aTitle;
		return;
	}

	// On small devices, create a custom navigation item title view so font
	// will shrink if necessary.
	// TODOFuture:  text is not centered on screen if only Back button is present.
	CGRect r = CGRectMake(0.0, 0.0, 1000.0, 30.0);	// The system will resize this.
	UILabel *label = [[UILabel alloc] initWithFrame:r];
	label.font = [UIFont boldSystemFontOfSize:20.0];
	label.adjustsFontSizeToFitWidth = YES;
	label.minimumFontSize = 10.0;
	label.textAlignment = UITextAlignmentCenter;
	label.textColor = [UIColor whiteColor];
	label.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.5];
	label.backgroundColor = [UIColor clearColor];
	label.text = aTitle;

	aVC.navigationItem.titleView = label;
	[label release];
}


- (void)pushViewControllerForScreen:(NSString *)aName
					  navController:(UINavigationController *)aNavController
						observation:(Observation *)aObservation
{
	BOOL isLeavingLastScreen = [aName isEqualToString:kSeqNameObservationList];
	if (isLeavingLastScreen)
		aObservation.Completed = [NSNumber numberWithBool:YES];

	BioKIDSAppDelegate *ad = (BioKIDSAppDelegate *)
								[[UIApplication sharedApplication] delegate];
	[ad saveContext];	// Save core data before switching screens.

	if (isLeavingLastScreen)
	{
		self.mIsFinishingSequence = YES;
		NSArray *vcArray = [aNavController viewControllers];
		if ([vcArray count] >= 2)
		{
			UIViewController *obsVC = [vcArray objectAtIndex:1];
			[aNavController popToViewController:obsVC animated:YES];
		}
		else
			[aNavController popViewControllerAnimated:YES];

		return;
	}

	self.mIsFinishingSequence = NO;

	// TODOFuture: cache allscreensDict.
	NSString *path = [[NSBundle mainBundle] pathForResource:@"sequence"
													 ofType:@"plist"];
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
	NSDictionary *allScreensDict = [dict objectForKey:@"screens"];
	NSDictionary *screenDict = [allScreensDict objectForKey:aName];
	if (!screenDict)
		return;

	UIViewController *vc = nil;
	NSString *screenType = [screenDict objectForKey:@"type"];
	if ([screenType isEqualToString:@"Choose1"])
	{
		vc = [[SeqChoose1VC alloc] initWithScreen:screenDict
									  observation:aObservation];
	}
	else if ([screenType isEqualToString:@"Choose0"])
	{
		vc = [[SeqChooseNVC alloc] initWithScreen:screenDict
									  observation:aObservation
								requireAtLeastOne:NO];
	}
	else if ([screenType isEqualToString:@"ChooseN"])
	{
		vc = [[SeqChooseNVC alloc] initWithScreen:screenDict
									  observation:aObservation
								requireAtLeastOne:YES];
	}
	else if ([screenType isEqualToString:@"Count"])
	{
		vc = [[SeqCountVC alloc] initWithScreen:screenDict 
									observation:aObservation];
	}
	else if ([screenType isEqualToString:@"Text"])
	{
		vc = [[SeqTextVC alloc] initWithScreen:screenDict
								 observation:aObservation];
	}

	if (vc)
	{
		[aNavController pushViewController:vc animated:YES];
		[vc release];
	}
}


- (BOOL)sequenceViewIsDisappearingDueToBack:(UIViewController *)aVC
{
	if (self.mIsFinishingSequence)
		return NO;

	return (NSNotFound == [aVC.navigationController.viewControllers
						   indexOfObject:aVC]);
}


- (void)configureSeqCellLabel:(UITableViewCell *)aCell
{
	aCell.textLabel.lineBreakMode = UILineBreakModeTailTruncation;
	// Could use numberOfLines = 0, but then font won't shrink.
	aCell.textLabel.numberOfLines = 1;
	aCell.textLabel.font = [UIFont boldSystemFontOfSize:18];
	aCell.textLabel.textColor = [UIColor blackColor];
	aCell.textLabel.adjustsFontSizeToFitWidth = YES;
	aCell.textLabel.minimumFontSize = 10.0;
}


- (UIButton *)nextButtonForView:(CGFloat)aParentViewWidth
{
	const CGFloat kBtnWidth = 130.0;
	UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[btn setTitle:NSLocalizedString(@"NextTitle", nil)
		 forState:UIControlStateNormal];
	[btn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
	btn.titleLabel.font = [UIFont boldSystemFontOfSize:18.0];
	UIImage *nextImg = [UIImage imageNamed:@"nextarrow.png"];
	[btn setImage:nextImg forState:UIControlStateNormal];
	
	CGFloat imgWidth = btn.imageView.image.size.width;
	btn.titleEdgeInsets = UIEdgeInsetsMake(0.0, -imgWidth, 0.0, 0.0);
	btn.imageEdgeInsets = UIEdgeInsetsMake(0.0, kBtnWidth - imgWidth - 25.0,
										   0.0, 0.0);
	
	btn.frame = CGRectMake((aParentViewWidth - kBtnWidth) / 2.0, 20.0,
						   kBtnWidth, 40.0);
	btn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
						   UIViewAutoresizingFlexibleRightMargin;
	btn.enabled = NO;
	return btn;
}


// Note: this method assumes that the table is the full width of the screen.
- (void)addTextHeaderForTable:(UITableView *)aTableView text:(NSString *)aText
{
	CGFloat screenWidth = [UIScreen mainScreen].applicationFrame.size.width;
	CGFloat marginLR = (screenWidth > 600.0) ? 55.0 : 12.0;
	CGRect r = CGRectMake(0.0, 0.0, aTableView.frame.size.width, 20.0);
	UIView *v = [[UIView alloc] initWithFrame:r];
	v.autoresizingMask = UIViewAutoresizingFlexibleWidth;

	r.origin.x = marginLR;
	r.size.width -= (2 * marginLR);
	r.origin.y = kTableHeaderTopMargin;
	r.size.height -= (kTableHeaderTopMargin + kTableHeaderBottomMargin);
	UILabel *headerLabel = [[UILabel alloc] initWithFrame:r];
	headerLabel.tag = kTableHeaderLabelTag;
	headerLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth |
									UIViewAutoresizingFlexibleHeight;
	headerLabel.numberOfLines = 0;
	headerLabel.text = aText;
	headerLabel.font = [UIFont systemFontOfSize:15.0];
	headerLabel.textColor = [UIColor whiteColor];
	headerLabel.backgroundColor = [UIColor clearColor];
	
	[v addSubview:headerLabel];
	aTableView.tableHeaderView = v;
	[headerLabel release];
	[v release];

	[self resizeTextHeaderForTable:aTableView];
}


- (void)resizeTextHeaderForTable:(UITableView *)aTableView
{
	UIView *v = aTableView.tableHeaderView;
	UILabel *label = (UILabel *)[v viewWithTag:kTableHeaderLabelTag];
	CGRect r = label.frame;
	r.size.height = 9999;
	CGSize sz = [label.text sizeWithFont:label.font constrainedToSize:r.size
						   lineBreakMode:label.lineBreakMode];
	sz.height += (kTableHeaderTopMargin + kTableHeaderBottomMargin);
	r = v.frame;
	r.size.height = sz.height;
	v.frame = r;
	aTableView.tableHeaderView = v;
}


// Returns count of observations to be uploaded (0 if upload is in progress).
- (NSUInteger)prepareForUpload
{
	if (self.mUploadStatus != UploadStatusIdle)
		return 0;

	BioKIDSAppDelegate *ad = (BioKIDSAppDelegate *)
								[[UIApplication sharedApplication] delegate];
	NSManagedObjectContext *moCtxt = ad.managedObjectContext;
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription
								   entityForName:@"Observation"
								   inManagedObjectContext:moCtxt];
	[fetchRequest setEntity:entity];
	
	NSPredicate *predicate =
						[NSPredicate predicateWithFormat:@"Completed == YES"];
	[fetchRequest setPredicate:predicate];

	NSError *error = nil;
	self.mObsToUpload = [moCtxt executeFetchRequest:fetchRequest error:&error];
	[fetchRequest release];

	if (!self.mObsToUpload)
	{
		NSLog(@"Fetch error in observationsToUpload: %@\n",
			  [error localizedDescription]);
	}

	return [self.mObsToUpload count];
}


- (void)discardUploadData:(BOOL)aDeleteObservations
{
	if (UploadStatusIdle == self.mUploadStatus)
	{
		if (aDeleteObservations)
		{
			for (Observation *obs in self.mObsToUpload)
				[obs.managedObjectContext deleteObject:obs];
			
			BioKIDSAppDelegate *ad = (BioKIDSAppDelegate *)
							[[UIApplication sharedApplication] delegate];
			[ad saveContext];
		}

		self.mObsToUpload = nil;
	}
}


- (BioKIDSUploadStatus)startUpload
{
	if (0 == [self.mObsToUpload count])
	{
		self.mObsToUpload = nil;
		self.mUploadStatus = UploadStatusIdle;
	}
	else
	{
		// Generate data to post to server.
		NSMutableString *dataStr = [NSMutableString stringWithCapacity:250];
		[dataStr appendString:kCSVColumns];
		[dataStr appendString:@"\n"];

		for (Observation *obs in self.mObsToUpload)
		{
			NSString *s = [obs serverString];
			if (!s)
				NSLog(@"failed to get CSV serverString\n");
			else
			{
				[dataStr appendString:s];
				[dataStr appendString:@"\n"];
			}
		}

//		NSLog(@"CSV data:\n%@", dataStr);

		NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
		NSString *urlStr = [ud stringForKey:kServerURLKey];
		if (!urlStr)
		{
			NSLog(@"no server URL configured\n");
		}
		else
		{
			NSURL *url = [NSURL URLWithString:urlStr];
			NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url
					cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
					timeoutInterval:kNetworkPOSTTimeout];
			[req setHTTPMethod:@"POST"];

			NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
			NSString *userName = [ud valueForKey:kUserNameKey];
			NSString *pwd = [self retrievePassword];
			if (([userName length] > 0) && ([pwd length] > 0))
			{
				// Add HTTP Authorization header.  Use temporary Core Foundation
				// request to generate correct header value.
				CFHTTPMessageRef tmpReq = CFHTTPMessageCreateRequest(
									   kCFAllocatorDefault, CFSTR("POST"),
									   (CFURLRef)url, kCFHTTPVersion1_1);
				CFHTTPMessageAddAuthentication(tmpReq, nil,
									(CFStringRef)userName, (CFStringRef)pwd,
									kCFHTTPAuthenticationSchemeBasic, FALSE);
				CFStringRef as = CFHTTPMessageCopyHeaderFieldValue(
												tmpReq, CFSTR("Authorization"));
				CFRelease(tmpReq);
			
				[req setValue:(NSString *)as forHTTPHeaderField:@"Authorization"];
				CFRelease(as);
			}

			[req setValue:@"text/csv" forHTTPHeaderField:@"Content-Type"];
			NSData *postData = [dataStr dataUsingEncoding:NSUTF8StringEncoding
								allowLossyConversion:YES];
			[req setHTTPBody:postData];
		
			self.mConnection = [[[NSURLConnection alloc] initWithRequest:req
							delegate:self startImmediately:YES] autorelease];
			if (!self.mConnection)
			{
				NSString *msg = NSLocalizedString(@"ConnectionError", nil);
				[self performSelector:@selector(cancelUploadAndReportError:)
						   withObject:msg];
			}
			else
				self.mUploadStatus = UploadStatusInProgress;
		}
	}

	return self.mUploadStatus;
}


- (BioKIDSUploadStatus)uploadStatus
{
	return self.mUploadStatus;
}


// Pass nil for aPassword to remove.
- (OSStatus)storePassword:(NSString *)aPassword
{
	NSMutableDictionary *itemDict = [self passwordItemDict];
	if (!aPassword)
		return SecItemDelete((CFDictionaryRef)itemDict);
	
	NSData *pwdData = [aPassword dataUsingEncoding:NSUTF8StringEncoding];
	
	// First try to update an existing item.
	NSMutableDictionary *attrDict = [[NSMutableDictionary alloc] init];
	[attrDict setObject:pwdData forKey:(id)kSecValueData];
	OSStatus status = SecItemUpdate((CFDictionaryRef)itemDict,
									(CFDictionaryRef)attrDict);
	[attrDict release];
	
	if (errSecItemNotFound == status)
	{
		// Existing item not found.  Add a new one.
		[itemDict setObject:pwdData forKey:(id)kSecValueData];
		status = SecItemAdd((CFDictionaryRef)itemDict, NULL);
	}
	
	return status;
}


- (NSString *)retrievePassword
{
	NSString *pwd = nil;
	NSMutableDictionary *queryDict = [self passwordItemDict];
	[queryDict setObject:(id)kSecMatchLimitOne forKey:(id)kSecMatchLimit];
	[queryDict setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];
	NSData *pwdData = nil;
	OSStatus status = SecItemCopyMatching((CFDictionaryRef)queryDict,
										  (CFTypeRef *)&pwdData);
	if (noErr == status && pwdData)
	{
		pwd = [[NSString alloc] initWithBytes:[pwdData bytes]
									   length:[pwdData length]
									 encoding:NSUTF8StringEncoding];
	}

	return [pwd autorelease];
}


#pragma mark NSURLConnection Delegate Methods
- (void) connection:(NSURLConnection *)aConnection
							didReceiveResponse:(NSURLResponse *)aResponse
{	
	if ([aResponse respondsToSelector:@selector(statusCode)])
	{
		NSInteger httpStatusCode = [((NSHTTPURLResponse *)aResponse) statusCode];
		if (httpStatusCode >= 400)
		{
			NSString *msg = nil;
			if (401 == httpStatusCode)
				msg = NSLocalizedString(@"ServerAuthError", nil);
			else
			{
				NSString *fmt = NSLocalizedString(@"HTTPErrorFmt", nil);
				msg = [NSString stringWithFormat:fmt, httpStatusCode];
			}
			[self cancelUploadAndReportError:msg];
		}
	}
}


- (void) connection:(NSURLConnection *)aConnection
									didFailWithError:(NSError *)aError
{
	NSString *msg = nil;
	if (NSURLErrorUserCancelledAuthentication == [aError code])
		msg = NSLocalizedString(@"ServerAuthError", nil);
	else
		msg = [aError localizedDescription];
	
	[self cancelUploadAndReportError:msg];
}


- (NSCachedURLResponse *) connection:(NSURLConnection *)aConnection
				   willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
	return nil; // We do not use an NSURLCache.
}


- (void) connectionDidFinishLoading:(NSURLConnection *)aConnection
{
	self.mConnection = nil;

	// Successful upload.  Delete the Observations.
	for (Observation *obs in self.mObsToUpload)
		[obs.managedObjectContext deleteObject:obs];

	self.mObsToUpload = nil;

	// Notify others that upload is done.
	self.mUploadStatus = UploadStatusIdle;
	[[NSNotificationCenter defaultCenter]
							postNotificationName:kNotificationUploadComplete
							object:self userInfo:nil];
}


#pragma mark Private Methods
- (void)cancelUploadAndReportError:(NSString *)aMsg
{
	// Consider storing aMsg in a lastError pref. so it can be retrieved later.
	[self.mConnection cancel];
	self.mConnection = nil;

	self.mUploadStatus = UploadStatusIdle;

	NSDictionary *d = [NSDictionary dictionaryWithObject:aMsg
												  forKey:@"errorMsg"];
	[[NSNotificationCenter defaultCenter]
							postNotificationName:kNotificationUploadComplete
							object:self userInfo:d];
}


#pragma mark Private Methods
- (NSMutableDictionary *)passwordItemDict
{
	return [NSMutableDictionary dictionaryWithObjectsAndKeys:
				(id)kSecClassGenericPassword, (id)kSecClass,
				kBioKIDSServiceName, (id)kSecAttrService,
				(id)kSecAttrAccessibleWhenUnlocked, (id)kSecAttrAccessible,
				nil];
}


#pragma mark Singleton Methods
+ (BioKIDSUtil *)sharedBioKIDSUtil
{
	@synchronized(self)
	{
		if (nil == gSharedBioKIDSUtil)
			gSharedBioKIDSUtil = [[BioKIDSUtil alloc] init];
	}
	
	return gSharedBioKIDSUtil;
}


+ (id)allocWithZone:(NSZone *)aZone
{
	@synchronized(self)
	{
		if (nil == gSharedBioKIDSUtil)
		{
			gSharedBioKIDSUtil = [super allocWithZone:aZone];
			return gSharedBioKIDSUtil;
		}
	}
	
	return nil;
}


- (id)copyWithZone:(NSZone *)aZone
{
	return self;
}


- (id)retain
{
	return self;
}


- (NSUInteger)retainCount
{
	return NSUIntegerMax;  // denotes an object that cannot be released
}


- (oneway void)release
{
	// NOOP
}


- (id)autorelease
{
	return self;
}

@end
