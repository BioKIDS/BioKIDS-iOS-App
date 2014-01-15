/*
  BioKIDSAppDelegate.m
  Created 8/8/11.

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

#import "BioKIDSAppDelegate.h"
#import "BioKIDSUtil.h"
#import "Constants.h"
#import "HomeVC.h"


// Declare private methods.
@interface BioKIDSAppDelegate()
- (BOOL)createPersistentStoreCoordinator:(BOOL)aExitOnError;
- (NSURL *)getDataStoreURL;
- (void)saveAllState;
@end

@implementation BioKIDSAppDelegate


@synthesize window=_window;
@synthesize managedObjectContext=__managedObjectContext;
@synthesize managedObjectModel=__managedObjectModel;
@synthesize persistentStoreCoordinator=__persistentStoreCoordinator;
@synthesize rootNavController;


- (BOOL)application:(UIApplication *)aApplication
				didFinishLaunchingWithOptions:(NSDictionary *)aLaunchOptions
{
	// Create Core Data persistent store coordinator.  Upon failure, delete
	// existing data file and try one more time.
	BOOL coreDataOK = [self createPersistentStoreCoordinator:NO];
	if (!coreDataOK)
	{
		NSURL *storeURL = [self getDataStoreURL];
		[[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
		coreDataOK = [self createPersistentStoreCoordinator:YES];
	}

	if (coreDataOK)
	{
		HomeVC *homeVC = [[HomeVC alloc] initWithNibName:@"HomeVC" bundle:nil];
		homeVC.view.frame = [UIScreen mainScreen].applicationFrame;

		self.rootNavController = [[[UINavigationController alloc]
							  initWithRootViewController:homeVC] autorelease];
		[homeVC release];

		self.rootNavController.navigationBarHidden = YES;

		self.window.rootViewController = self.rootNavController;

		// For iOS 7 and newer, set navigation bar appearance.
		UINavigationBar *navBar = self.rootNavController.navigationBar;
		if ([navBar respondsToSelector:@selector(setBarTintColor:)])
		{
			BioKIDSUtil *bku = [BioKIDSUtil sharedBioKIDSUtil];
			UIColor *bgColor = [bku appBackgroundColor];
			UIColor *btnAndTextColor = [bku titleTextColor];
			[navBar setBarTintColor:bgColor];
			navBar.tintColor = btnAndTextColor;

			NSDictionary *textAttrs = @{UITextAttributeTextColor: btnAndTextColor};
			navBar.titleTextAttributes = textAttrs;

			// Set tintColor for some controls.
			[[UIButton appearance] setTintColor:btnAndTextColor];
			[[UISegmentedControl appearance] setTintColor:btnAndTextColor];
			UIColor *swColor = bgColor;
			[[UISwitch appearance] setTintColor:swColor];
			[[UISwitch appearance] setOnTintColor:swColor];
		}

		// Show our views to the world.
		[self.window makeKeyAndVisible];
		
		// If first launch, prompt for classroom vs personal use.
		NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
		NSString *version = [ud stringForKey:kLastVersionKey];
		if (0 == [version length])
		{
			NSString *prompt = NSLocalizedString(@"ClassroomUsePrompt", nil);
			NSString *classroom = NSLocalizedString(@"ClassroomUseTitle", nil);
			NSString *personal = NSLocalizedString(@"PersonalUseTitle", nil);
			UIAlertView *av = [[UIAlertView alloc] initWithTitle:@""
							   message:prompt delegate:self cancelButtonTitle:nil
							   otherButtonTitles:classroom, personal, nil];
			[av show];
			[av release];
		}
	}

	return YES;
}


- (void)applicationWillResignActive:(UIApplication *)aApplication
{
}


- (void)applicationDidEnterBackground:(UIApplication *)aApplication
{
	[self saveAllState];
}


- (void)applicationWillEnterForeground:(UIApplication *)aApplication
{
	/*
	 Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	 */
}


- (void)applicationDidBecomeActive:(UIApplication *)aApplication
{
	/*
	 Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	 */
}


- (void)applicationWillTerminate:(UIApplication *)aApplication
{
	[self saveAllState];
}


- (void)dealloc
{
	[_window release];
	[__managedObjectContext release];
	[__managedObjectModel release];
	[__persistentStoreCoordinator release];

	self.rootNavController = nil;

	[super dealloc];
}


- (void)awakeFromNib
{
	/*
	 Typically you should set up the Core Data stack here, usually by passing the managed object context to the first view controller.
	 self.<#View controller#>.managedObjectContext = self.managedObjectContext;
	*/
}


- (void)saveContext
{
	NSManagedObjectContext *moCtxt = self.managedObjectContext;
	if (moCtxt)
	{
		NSError *error = nil;
		if ([moCtxt hasChanges] && ![moCtxt save:&error])
		{
			NSLog(@"Unable to save core data %@, %@", error, [error userInfo]);
		}
	}
}


#pragma mark - Core Data stack
/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext
{
	if (__managedObjectContext != nil)
	{
		return __managedObjectContext;
	}

	NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
	if (coordinator != nil)
	{
		__managedObjectContext = [[NSManagedObjectContext alloc] init];
		[__managedObjectContext setPersistentStoreCoordinator:coordinator];
	}
	return __managedObjectContext;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel
{
	if (__managedObjectModel != nil)
	{
		return __managedObjectModel;
	}
	NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"BioKIDS" withExtension:@"momd"];
	__managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
	return __managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
	if (nil == __persistentStoreCoordinator)
		[self createPersistentStoreCoordinator:NO];

	return __persistentStoreCoordinator;
}


#pragma mark - Application's Documents directory
/**
 Returns the URL to the application's Documents directory.
 */
- (NSURL *)applicationDocumentsDirectory
{
	return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
									inDomains:NSUserDomainMask] lastObject];
}


#pragma mark UIAlertViewDelegate Methods
- (void)alertView:(UIAlertView *)aAlertView
								clickedButtonAtIndex:(NSInteger)aButtonIndex
{
	BOOL isClassroomUse = (0 == aButtonIndex);
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	[ud setBool:isClassroomUse forKey:kClassroomUseKey];

	NSString *appVersion = [[[NSBundle mainBundle] infoDictionary]
							objectForKey:@"CFBundleShortVersionString"];
	[ud setObject:appVersion forKey:kLastVersionKey];
	[ud synchronize];
}


#pragma mark Private Methods
- (BOOL)createPersistentStoreCoordinator:(BOOL)aExitOnError
{
	NSURL *storeURL = [self getDataStoreURL];

	// TODO: test data model 1 to 2 migration

	NSError *error = nil;
	__persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc]
						initWithManagedObjectModel:[self managedObjectModel]];
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithBool:YES],
								NSMigratePersistentStoresAutomaticallyOption,
	 						 [NSNumber numberWithBool:YES],
								NSInferMappingModelAutomaticallyOption, nil];
	if (nil != [__persistentStoreCoordinator
				addPersistentStoreWithType:NSSQLiteStoreType
				configuration:nil URL:storeURL options:options error:&error])
	{
		// Perform any manual migration steps here, if necessary.
		return YES;		// Persistent store has been initialized successfully.
	}

	/*
	 * Typical reasons for an error here include:
	 *   The persistent store is not accessible;
	 *   The schema for the persistent store is incompatible with the
	 *       current managed object model.
	 * Check the error message to determine what the actual problem was.
	 */
	NSLog(@"Unresolved Core Data error %@, %@", error, [error userInfo]);

	if (aExitOnError)
	{
		// Display "Press Home To Exit" alert.
		NSString *title = NSLocalizedString(@"MainAppTitle", nil);
		NSString *fmt = NSLocalizedString(@"CoreDataInitErrorFormat", nil);
		NSMutableString *s = [NSMutableString stringWithFormat:fmt,
							  [error localizedDescription]];
		[s appendString:NSLocalizedString(@"PressHomeToExit", nil)];

		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
														message:s
													   delegate:nil
											  cancelButtonTitle:nil
											  otherButtonTitles:nil];
		[alert show];
		[alert release];
	}

	return NO;
}


- (NSURL *)getDataStoreURL
{
	return [[self applicationDocumentsDirectory]
			URLByAppendingPathComponent:@"BioKIDS.sqlite"];
}


- (void) saveAllState
{
	[self saveContext];

	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	[ud synchronize];
}


@end
