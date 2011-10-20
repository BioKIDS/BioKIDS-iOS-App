/*
  ObservationsVC.m
  Created 8/10/11.

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

#import "ObservationsVC.h"
#import "Constants.h"
#import "BioKIDSUtil.h"
#import "BioKIDSAppDelegate.h"
#import "Observation.h"
#import "ObservationCell.h"


// Declare private methods.
@interface ObservationsVC()
- (void)onAddPress:(id)aSender;
- (void)setUpCell:(UITableViewCell *)aCell
						atIndexPath:(NSIndexPath *)aIndexPath;
- (BOOL)deleteObservationAtIndexPath:(NSIndexPath *)aIndexPath;
@end


@implementation ObservationsVC

@synthesize mHasViewAppeared;
@synthesize mTableView, mMOContext, mFRController, mDateFormatter;


-(id)init
{
	self = [super initWithNibName:@"ObservationsVC" bundle:nil];
	if (self)
	{
		// Create date formatter and configure it.
		self.mDateFormatter = [[[NSDateFormatter alloc] init] autorelease];
		[self.mDateFormatter setDateStyle:NSDateFormatterShortStyle];
		[self.mDateFormatter setTimeStyle:NSDateFormatterShortStyle];

		// Set up Fetched Results Controller for table view.  Only Completed
		// Observation objects are fetched and displayed.
		BioKIDSAppDelegate *ad = (BioKIDSAppDelegate *)
								[[UIApplication sharedApplication] delegate];
		self.mMOContext = ad.managedObjectContext;

		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		NSEntityDescription *entity = [NSEntityDescription
									   entityForName:@"Observation"
									   inManagedObjectContext:self.mMOContext];
		[fetchRequest setEntity:entity];

		NSPredicate *predicate =
					[NSPredicate predicateWithFormat:@"Completed == YES"];
		[fetchRequest setPredicate:predicate];

		NSSortDescriptor *sd = [[NSSortDescriptor alloc]
										initWithKey:@"Timestamp" ascending:YES];
		NSArray *sortDescs = [[NSArray alloc] initWithObjects:sd, nil];
		[sd release];
		[fetchRequest setSortDescriptors:sortDescs];
		[sortDescs release];

		self.mFRController = [[[NSFetchedResultsController alloc]
						  initWithFetchRequest:fetchRequest
						  managedObjectContext:self.mMOContext
						  sectionNameKeyPath:nil cacheName:nil] autorelease];
		[fetchRequest release];

		NSError *err = nil;
		if (![self.mFRController performFetch:&err])
		{
			NSLog(@"performFetch error: %@", err);
			return nil; // No point in opening view
		}

#if 0
		NSUInteger obsCount = [[self.mFRController fetchedObjects] count];
		NSLog(@"observations: %d\n", obsCount);
#endif

		// Arrange for table to update dynamically when box list changes.
		// Assigning delegate must be done after performFetch.
		self.mFRController.delegate = self;
	}

	return self;
}


- (void)dealloc
{
	self.mTableView = nil;
	self.mMOContext = nil;
	self.mFRController = nil;
	self.mDateFormatter = nil;

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

	self.navigationItem.title = NSLocalizedString(@"ObservationsTitle", nil);

	UIBarButtonItem *btn = [[UIBarButtonItem alloc]
							initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
							target:self action:@selector(onAddPress:)];
	self.navigationItem.rightBarButtonItem = btn;
	[btn release];
}


- (void)viewDidUnload
{
	[super viewDidUnload];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)viewWillAppear:(BOOL)aAnimated
{
	[super viewWillAppear:aAnimated];

	// Ensure that "Delete Observation" UIAlertView is closed if back was
	// pressed to return from an observation InfoVC view.
	[[BioKIDSUtil sharedBioKIDSUtil] closePopoversAndAlerts:nil];

	// Remove selection.
	NSIndexPath *ip = [self.mTableView indexPathForSelectedRow];
	if (ip)
		[self.mTableView deselectRowAtIndexPath:ip animated:NO];

	// Delete Observation objects that are not Complete.
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Observation"
										inManagedObjectContext:self.mMOContext];
	[fetchRequest setEntity:entity];

	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"Completed == NO"];
	[fetchRequest setPredicate:predicate];

	NSError *error = nil;
	NSArray *incompleteObs = [self.mMOContext executeFetchRequest:fetchRequest
															 error:&error];
	[fetchRequest release];
	if (incompleteObs)
	{
		for (Observation *obs in incompleteObs)
			[self.mMOContext deleteObject:obs];

		// Do not save Core Data here (it is okay for that to happen later).
	}
	else
	{
		NSLog(@"ObservationVC viewWillAppear: unable to fetch Observation objects (%@)\n",
			  [error localizedDescription]);
	}

	// When view appears for the first time, skip to the "Add" screen if no
	// observations have been recorded yet.
	if (!self.mHasViewAppeared &&
		(0 == [[self.mFRController fetchedObjects] count]))
	{
		self.mHasViewAppeared = YES;
		[self onAddPress:nil];
	}
}


- (void)viewDidAppear:(BOOL)aAnimated
{
	[super viewDidAppear:aAnimated];

	[self.mTableView flashScrollIndicators];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)aOrient
{
	return YES;
}


#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView
{
	return [[self.mFRController sections] count];
}


- (NSInteger)tableView:(UITableView *)aTableView
									numberOfRowsInSection:(NSInteger)aSection
{
	NSArray *sections = [self.mFRController sections];
	id <NSFetchedResultsSectionInfo> sectionInfo =
											[sections objectAtIndex:aSection];
	return [sectionInfo numberOfObjects];
}


- (UITableViewCell *)tableView:(UITableView *)aTableView
							cellForRowAtIndexPath:(NSIndexPath *)aIndexPath
{
	static NSString *cellID = @"ObservationCell";

	UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:cellID];
	if (cell == nil)
	{
		cell = [[[ObservationCell alloc] initWithReuseIdentifier:cellID]
																autorelease];
	}

	// Configure the cell.
	[self setUpCell:cell atIndexPath:aIndexPath];

	return cell;
}


- (void)tableView:(UITableView *)aTableView
				commitEditingStyle:(UITableViewCellEditingStyle)aEditingStyle
				forRowAtIndexPath:(NSIndexPath *)aIndexPath
{
	if (aEditingStyle == UITableViewCellEditingStyleDelete)
		[self deleteObservationAtIndexPath:aIndexPath];
}


#pragma mark - Table view delegate
- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)aIndexPath
{
	Observation *obs = [self.mFRController objectAtIndexPath:aIndexPath];
	if (obs)
	{
		NSString *s = NSLocalizedString(@"ObservationDetailsTitle", nil);
		NSString *t = [obs htmlString];
		UIViewController *vc = [[InfoVC alloc] initWithHTMLText:t title:s
													   delegate:self];
		if (vc)
		{
			[self.navigationController pushViewController:vc animated:YES];
			[vc release];
		}
	}
}


#pragma mark NSFetchedResultsControllerDelegate methods
- (void)controllerDidChangeContent:(NSFetchedResultsController *)aController
{
	// The fetch controller has finished sending all change notifications.
	[self.mTableView reloadData];
}


#pragma mark UIActionSheetDelegate method
- (void)actionSheet:(UIActionSheet *)aActionSheet
							clickedButtonAtIndex:(NSInteger)aButtonIndex
{
	if (aActionSheet.cancelButtonIndex == aButtonIndex)
		return; // Cancel.

	NSIndexPath *ip = [self.mTableView indexPathForSelectedRow];
	if ([self deleteObservationAtIndexPath:ip])
		[self.navigationController popViewControllerAnimated:YES];
}


#pragma mark InfoVCDelegate Methods
- (void) InfoVCDeletePressed:(UIBarButtonItem *)aDeleteBtn
{
	NSString *cancelTitle = NSLocalizedString(@"CancelTitle", nil);
	NSString *deleteTitle = NSLocalizedString(@"DeleteObsTitle", nil);
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
								delegate:self cancelButtonTitle:cancelTitle
								destructiveButtonTitle:deleteTitle
								otherButtonTitles:nil];
	actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
	UIViewController *topVC = [self.navigationController topViewController];
	if (aDeleteBtn)
		[actionSheet showFromBarButtonItem:aDeleteBtn animated:YES];
	else
		[actionSheet showInView:topVC.view];
	[actionSheet release];
}


#pragma mark Private Methods
// aSender may be nil.
- (void)onAddPress:(id)aSender
{
	Observation *obs = [NSEntityDescription
						insertNewObjectForEntityForName:@"Observation"
						inManagedObjectContext:self.mMOContext];
	obs.Timestamp = [NSDate date];

	CFUUIDRef uuidRef = CFUUIDCreate(nil);
	CFStringRef guid = CFUUIDCreateString(nil, uuidRef);
	CFRelease(uuidRef);
	obs.GUID = (NSString *)guid;
	CFRelease(guid);

	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	obs.BioKIDSID = [ud stringForKey:kBioKIDSIDKey];
	obs.Tracker = [ud stringForKey:kTrackerKey];
	obs.Zone = [ud stringForKey:kZoneKey];

	if (!obs.Timestamp || !obs.GUID || !obs.BioKIDSID || !obs.Tracker || !obs.Zone)
	{
		NSLog(@"missing fields for new observation\n");
		[self.mMOContext deleteObject:obs];
		return;
	}

	[[BioKIDSUtil sharedBioKIDSUtil] pushViewControllerForScreen:@"_start"
									navController:self.navigationController
									observation:obs];
}


- (void) setUpCell:(UITableViewCell *)aCell
									atIndexPath:(NSIndexPath *)aIndexPath
{
	if (aCell && aIndexPath)
	{
		// Set up the cell from Core Data object.
		Observation *obs = [self.mFRController objectAtIndexPath:aIndexPath];
		if (obs)
		{
			// Place "Species (#)" in main cell label.
			NSString *mainText = @"";
			NSString *species = obs.Species;
			if (species)
			{
				if ([species isEqualToString:kSpeciesGrass])
				{
					NSString *coverage = [obs grassCoverageString];
					if (!coverage)
						mainText = obs.Species;
					else
					{
						mainText = [NSString stringWithFormat:@"%@ (%@)",
									  obs.Species, coverage];
					}
				}
				else
				{
					NSInteger count = 0;
					if (obs.HowMany)
						count = [obs.HowMany integerValue];

					if (count > 0)
					{
						BOOL isEstimated = [obs.HowManyIsEstimated boolValue];
						NSString *estStr = (isEstimated) ? @"~" : @"";
						mainText = [NSString stringWithFormat:@"%@ (%@%d)",
									  obs.Species, estStr, count];
					}
					else
						mainText = obs.Species;
				}
			}

			aCell.textLabel.text = mainText;

			// Place timestamp in secondary cell label and set zone.
			aCell.detailTextLabel.text =
							[self.mDateFormatter stringFromDate:obs.Timestamp];
			if ([aCell isKindOfClass:[ObservationCell class]])
			{
				ObservationCell *obsCell = (ObservationCell *)aCell;
				obsCell.zoneName = obs.Zone;
			}
		}
		else
		{
			aCell.textLabel.text = @"";
			aCell.detailTextLabel.text = @"";
		}
	}
}


// Returns YES if successful.
- (BOOL)deleteObservationAtIndexPath:(NSIndexPath *)aIndexPath
{
	BOOL didSucceed = NO;

	Observation *obs = [self.mFRController objectAtIndexPath:aIndexPath];
	if (obs)
	{
		[self.mMOContext deleteObject:obs];

		NSError *err = nil;
		didSucceed = [self.mMOContext save:&err];
		if (!didSucceed)
		{
			NSLog(@"unable to save after delete: %@, %@", err, [err userInfo]);
			NSString *msg = NSLocalizedString(@"UnableToDeleteObservation", nil);
			[[BioKIDSUtil sharedBioKIDSUtil]  showAlert:msg delegate:nil];
		}
	}

	return didSucceed;
}

@end
