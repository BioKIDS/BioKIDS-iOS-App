/*
  ObservationsVC.h
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

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "InfoVC.h"


@interface ObservationsVC : UIViewController <UITableViewDataSource,
											UITableViewDelegate,
											NSFetchedResultsControllerDelegate,
											UIActionSheetDelegate,
											InfoVCDelegate>
{
	@private BOOL mHasViewAppeared;
	@private UITableView *mTableView;
	@private NSManagedObjectContext *mMOContext;
	@private NSFetchedResultsController *mFRController;
	@private NSDateFormatter *mDateFormatter;
}

@property (nonatomic, assign) BOOL mHasViewAppeared;
@property (nonatomic, retain) IBOutlet UITableView *mTableView;
@property (nonatomic, retain) NSManagedObjectContext *mMOContext;
@property (nonatomic, retain) NSFetchedResultsController *mFRController;
@property (nonatomic, retain) NSDateFormatter *mDateFormatter;


@end
