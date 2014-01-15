/*
  InfoVC.m
  Created 2/18/11.

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

#import "InfoVC.h"
#import "BioKIDSUtil.h"


// Declare private methods.
@interface InfoVC()
- (void) loadLocalHTML:(NSString *)aFileBaseName;
- (void) loadHTMLText:(NSString *)aText;
- (void) onDeletePress:(id)aSender;
@end


@implementation InfoVC

@synthesize mDelegate, mFileBaseName, mHTMLText, mWebView;

// Define constants:
NSString * const kInfoMeta = @"<meta name=\"viewport\" content=\"width=device-width\" />";
NSString * const kInfoStyle = @"<style type=\"text/css\">body {font-family: Helvetica; -webkit-text-size-adjust: none;}</style>";

- (id)initWithHTMLFile:(NSString *)aFileBaseName title:(NSString *)aTitle
			  delegate:(id<InfoVCDelegate>)aDelegate
{
	
	self = [super initWithNibName:@"InfoVC" bundle:nil];
	if (self)
	{
		self.mFileBaseName = aFileBaseName;
		self.navigationItem.title = aTitle;
		self.mDelegate = aDelegate;
	}

	return self;
}


- (id)initWithHTMLText:(NSString *)aText title:(NSString *)aTitle
			  delegate:(id<InfoVCDelegate>)aDelegate
{
	self = [super initWithNibName:@"InfoVC" bundle:nil];
	if (self)
	{
		self.mHTMLText = aText;
		self.navigationItem.title = aTitle;
		self.mDelegate = aDelegate;
	}
	
	return self;
}


- (void)viewDidLoad
{
	[super viewDidLoad];

	BioKIDSUtil *bku = [BioKIDSUtil sharedBioKIDSUtil];
	if ([bku systemVersionIsAtLeast:@"7.0"])
		self.view.backgroundColor = [bku appBackgroundColor];
	else
	{
		self.view.backgroundColor = [UIColor colorWithRed:192/255.0
									green:206/255.0 blue:221/255.0 alpha:1.0];
	}

	if (self.mFileBaseName)
		[self loadLocalHTML:self.mFileBaseName];
	else
		[self loadHTMLText:self.mHTMLText];

	if (self.mDelegate)
	{
		UIBarButtonItem *deleteBtn = [[UIBarButtonItem alloc]
						initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
						target:self action:@selector(onDeletePress:)];
		self.navigationItem.rightBarButtonItem = deleteBtn;
		[deleteBtn release];
	}
}


- (void)viewDidAppear:(BOOL)aAnimated
{
	[super viewDidAppear:aAnimated];
	[self webViewDidFinishLoad:self.mWebView]; // flash scroll indicators
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)aOrient
{
	return YES;
}


- (void)didReceiveMemoryWarning
{
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload
{
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc
{
	self.mFileBaseName = nil;
	self.mHTMLText = nil;
	self.mWebView = nil;

	[super dealloc];
}


#pragma mark UIWebViewDelegate Methods
- (BOOL) webView:(UIWebView *)webView
				shouldStartLoadWithRequest:(NSURLRequest *)aRequest
				navigationType:(UIWebViewNavigationType)aNavigationType
{
	// Allow initial load of info. text but open all links in Safari.
	if (aNavigationType == UIWebViewNavigationTypeOther)
		return YES;

	if (aNavigationType == UIWebViewNavigationTypeLinkClicked)
		[[UIApplication sharedApplication] openURL:aRequest.URL];

	return NO;
}


- (void)webViewDidFinishLoad:(UIWebView *)aWebView
{
	UIView *scrollView = [aWebView.subviews objectAtIndex:0];
	if ([scrollView respondsToSelector:@selector(flashScrollIndicators)])
		[scrollView performSelector:@selector(flashScrollIndicators)];
}

#pragma mark private methods
- (void) loadLocalHTML:(NSString *)aFileBaseName
{
	// Load text from bundled HTML file.  Set baseURL so other resources
	// in bundle may be used, e.g., images.
	NSString *path = [[NSBundle mainBundle] pathForResource:aFileBaseName
													 ofType:@"html"];
	if (path)
	{
		NSData *htmlData = [NSData dataWithContentsOfFile:path];
		NSURL *baseURL = [NSURL fileURLWithPath:[path stringByDeletingLastPathComponent]];
		[self.mWebView loadData:htmlData MIMEType:@"text/html"
			   textEncodingName:@"utf-8" baseURL:baseURL];
	}
}


- (void) loadHTMLText:(NSString *)aText
{
	if (!aText)
		aText = @"";
	NSString *s = [NSString stringWithFormat:@"%@\n%@\n%@",
				   kInfoMeta, kInfoStyle, aText];
	NSArray *array = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
														 NSUserDomainMask, YES);
	NSURL *baseURL = [NSURL fileURLWithPath:[array lastObject]];
	[self.mWebView loadHTMLString:s baseURL:baseURL];
}


- (void) onDeletePress:(id)aSender
{
	if (self.mDelegate)
		[self.mDelegate InfoVCDeletePressed:self.navigationItem.rightBarButtonItem];
}

@end
