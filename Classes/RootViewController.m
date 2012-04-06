//
//  RootViewController.m
//  Wikipedia Mobile
//
//  Created by Andreas Lengyel on 2/3/10.
//  Copyright Wikimedia Foundation 2010. All rights reserved.
//

#import "RootViewController.h"
#import "ModalViewController.h"
#import "MapViewController.h"
#import "LanguageSwitcher.h"
#import "Wikipedia_MobileAppDelegate.h"
#import "RecentPage.h"
#import "Bookmark.h"
#import <SystemConfiguration/SystemConfiguration.h>

#define debug(format, ...) CFShow([NSString stringWithFormat:format, ## __VA_ARGS__]);

@implementation RootViewController

@synthesize webView = _webView, searchBar = _searchBar, searchResults = _searchResults, toolBar = _toolBar, backButton = _backButton, forwardButton = _forwardButton;
@synthesize pageTitle = _pageTitle, shade = _shade, tableView = _tableView, externalURL = _externalURL;

@synthesize managedObjectContext;
@synthesize webViewIntermediaryDelegate;

- (void)viewWillAppear:(BOOL)animated {
	
}

- (void)loadStartPage {
	NSString *url = [NSString stringWithFormat:@"http://%@.m.wikipedia.org", [APP_DELEGATE.settings stringForKey:@"languageKey"]];
	NSURL *_url = [NSURL URLWithString:url];
	NSMutableURLRequest *URLrequest = [NSMutableURLRequest requestWithURL:_url];
	
	[self.webView loadRequest:URLrequest];
}

- (BOOL)isDataSourceAvailable
{
    static BOOL checkNetwork = YES;
    if (checkNetwork) {
        checkNetwork = NO;
        
        Boolean success;
        const char *host_name = "wikipedia.org";
		
        SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, host_name);
        SCNetworkReachabilityFlags flags;
        success = SCNetworkReachabilityGetFlags(reachability, &flags);
        _isDataSourceAvailable = success && (flags & kSCNetworkFlagsReachable) && !(flags & kSCNetworkFlagsConnectionRequired);
        CFRelease(reachability);
    }
    return _isDataSourceAvailable;
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (navigationType == UIWebViewNavigationTypeLinkClicked || navigationType == UIWebViewNavigationTypeOther) {
        NSArray *sitesArray = [NSArray arrayWithObjects:@"wikiquote.org",@"wikinews.org",@"wikibooks.org",@"wikipedia.org",@"wiktionary.org",@"wikimedia.org", @"wikisource.org",@"wikiversity.org",nil];
        NSURL *requestURL = [request URL]; 
        BOOL siteFound = NO;

        NSArray *hostParts = [requestURL.host componentsSeparatedByString:@"."];
        NSString *documentDomain = [NSString stringWithFormat:@"%@%@%@", 
                                    [hostParts objectAtIndex:(hostParts.count - 2)],
                                    @".",
                                    [hostParts objectAtIndex:(hostParts.count - 1)]];
        
        if ([sitesArray containsObject:documentDomain]) {
            siteFound = YES;
        }
        
        if (!siteFound) {
            self.externalURL = [request URL];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Open external link in Safari?" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Cancel", nil];
            alert.tag = 2;
            [alert show];
            [alert release];
            return NO;
        }
    }
    return YES;
}

- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet.tag == 2) {
        if (buttonIndex == 0) {
            [[UIApplication sharedApplication] openURL:self.externalURL];
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.webViewIntermediaryDelegate = [[[WikiWebViewIntermediaryDelegate alloc] initWithWebView:self.webView delegate:self] autorelease];
    self.webViewIntermediaryDelegate.customHeaders = [NSDictionary dictionaryWithObjectsAndKeys:@"Wikipedia Mobile/2.2.1", @"Application_Version", nil];
	self.webView.scalesPageToFit = TRUE;
	self.webView.multipleTouchEnabled = TRUE;
	self.searchBar.showsScopeBar = NO;
	self.searchBar.frame = CGRectMake(0, 0, 320.0f, 44.0f);
	
        self.backButton.enabled = NO;
        self.forwardButton.enabled = NO;
    
    if ([self isDataSourceAvailable] == NO) {
		UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error: No Internet Connection", @"Error: No Internet Connection") message:NSLocalizedString(@"This application requires internet access.", @"This application requires internet access.") delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
		[errorAlert show];
        [errorAlert release];
	}
        
	[self loadStartPage];
	
	self.managedObjectContext = APP_DELEGATE.managedObjectContext;
	
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"RecentPage" inManagedObjectContext:managedObjectContext];
	[request setEntity:entity];
	
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"dateVisited" ascending:NO];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	[request setSortDescriptors:sortDescriptors];
	[sortDescriptor release];
	[sortDescriptors release];
	
	NSError *error = nil;
	NSMutableArray *mutableFetchResults = [[managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
	if (mutableFetchResults == nil) {
	}
	
	[mutableFetchResults release];
	[request release];
}

- (void)loadURL:(NSString *)url {
	NSURL *_url = [NSURL URLWithString:url];
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:_url];
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
	
	[self.webView loadRequest:request];
	[request release];
}

- (void)loadWikiEntry:(NSString *)query {
	query = [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	
	NSString *url = [NSString stringWithFormat:@"http://%@.m.wikipedia.org/wiki?search=%@", [APP_DELEGATE.settings stringForKey:@"languageKey"], query]; 
	NSURL *_url = [NSURL URLWithString:url];
		
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:_url];
	
	[self.webView loadRequest:request];
	[request release];
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	[self showLoadingHUD];
	
	[timer release];
	timer = [NSTimer scheduledTimerWithTimeInterval:0.05
											 target:self
										   selector:@selector(handleTimer:)
										   userInfo:nil
											repeats:YES];	
	[timer retain];
}

- (void)handleTimer:(NSTimer *)timer
{
	if (HUDvisible) {
		if (HUD.progress < 1.0f) {
			HUD.progress = HUD.progress + 0.01f;
		} else {
			HUD.progress = 0.0f;
		}
	}
}

#pragma mark WebViewDelegate

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	[timer invalidate];
	if (error != nil) {
		NSString *errorString = [NSString stringWithFormat:@"%@", error];
		NSLog(@"%@", errorString);
		
		if (error.code == -1003) {
			UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Can't find host", @"Can't find host") message:NSLocalizedString(@"Wikipedia could not be located. Please check your internet connection.", @"Wikipedia could not be located. Please check your internet connection.") delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
			[errorAlert show];
            [errorAlert release];
		}
		
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO; 
		[HUD hide:YES];
	}

        self.backButton.enabled = webView.canGoBack;
        self.forwardButton.enabled = webView.canGoForward;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
    NSString *fullTitle = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    
    NSString *workingTitle = fullTitle;
    
    workingTitle = [workingTitle stringByReplacingOccurrencesOfString:@"- Wikipedia, the free encyclopedia" withString:@""]; // For addons to most pages
    workingTitle = [workingTitle stringByReplacingOccurrencesOfString:@"Wikipedia, the free encyclopedia" withString:@"Wikipedia"]; // For title page text

	self.pageTitle = workingTitle;
    
	if (![self.pageTitle isEqualToString:@"Wikipedia"]) {
		self.searchBar.text = self.pageTitle;
	}
	
	[timer invalidate];
	if (HUDvisible) {
		[HUD hide:YES];
	}
	
	if (![self.pageTitle isEqualToString:@"Wikipedia"] && ![self.pageTitle isEqualToString:nil]) {
		[self addRecentPage:self.pageTitle];
	}
        
        self.backButton.enabled = webView.canGoBack;
        self.forwardButton.enabled = webView.canGoForward;
}

- (void)addRecentPage:(NSString *)pageName {
	RecentPage *recentPage = (RecentPage *)[NSEntityDescription insertNewObjectForEntityForName:@"RecentPage" inManagedObjectContext:managedObjectContext];
	
	[recentPage setValue:[NSDate date] forKey:@"dateVisited"];
	[recentPage setValue:pageName forKey:@"pageName"];
	
	[recentPage setValue:self.currentURL forKey:@"pageURL"];
	
	NSError *error;
	if (![managedObjectContext save:&error]) {
	}
}

- (NSString *)currentURL {
	NSString *locationString = [self.webView stringByEvaluatingJavaScriptFromString:@"location.href;"];
	if(!locationString)
		return nil;
	locationString = [locationString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	return locationString;
}

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/

/*
 // Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations.
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
 */

#pragma mark SearchBar stuff

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
	self.shade.alpha = 0.0;
	self.shade.hidden = NO;
	
    searchBar.text = nil;
	searchBar.showsScopeBar = YES;
	searchBar.selectedScopeButtonIndex = 0;
	searchBar.scopeButtonTitles = [NSArray arrayWithObjects:[APP_DELEGATE.settings stringForKey:@"languageName"], NSLocalizedString(@"Set Language", @"Set Language"), nil];
	
	[searchBar sizeToFit];
	searchBar.frame = CGRectMake(0, 0, 320.0f, 88.0f);

	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.3];	
	self.shade.alpha = 0.6;
	[UIView commitAnimations];
	
	if (self.webView.loading) {
		[self.webView stopLoading];
	}
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
	searchText = [searchText stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	
	NSString *urlString = [NSString stringWithFormat:@"http://%@.wikipedia.org/w/api.php?action=opensearch&search=%@&format=json", [APP_DELEGATE.settings stringForKey:@"languageKey"], searchText];
	NSURL *url = [NSURL URLWithString:urlString];
	
	NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
	NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	[connection release];
	[request release];
	
	if (searchText.length > 0) {
		self.tableView.alpha = 1.0;
		self.tableView.hidden = NO;
	} else {
		self.tableView.alpha = 0.0;
		self.tableView.hidden = YES;
	}
	[self.tableView setContentOffset:CGPointMake(0, 0) animated:YES];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data 
{
	NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	NSArray *results = [jsonString JSONValue];
        
	if (results && [results count] >= 1) {
            self.searchResults = [NSMutableArray arrayWithArray:[results objectAtIndex:1]];
        } else {
            self.searchResults = [NSMutableArray array];
        }
        [jsonString release];
        
       	[self.tableView reloadData];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	self.tableView.hidden = YES;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    if (searchBar.text == nil || [searchBar.text isEqualToString:@""]) {
//        self.pageTitle = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"]; 
        if (![self.pageTitle isEqualToString:@"Wikipedia"]) {
            searchBar.text = self.pageTitle;
        }
    }
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
	if (selectedScope == 1) {
		LanguageSwitcher *langSwitcher = [[LanguageSwitcher alloc] initWithNibName:@"LanguageSwitcher" bundle:nil];
		langSwitcher.returnView = self;
		[self.navigationController presentModalViewController:langSwitcher animated:YES];
		[langSwitcher release];
		if (self.webView.loading) {
			[self.webView stopLoading];
		}
	}
}

- (void)searchBarBookmarkButtonClicked:(UISearchBar *)searchBar {
	ModalViewController *modalView = [[ModalViewController alloc] initWithNibName:@"ModalViewController" bundle:nil];
	modalView.managedObjectContext = APP_DELEGATE.managedObjectContext;
	modalView.returnView = self;
	modalView.isBookmark = YES;
	[self.navigationController presentModalViewController:modalView animated:YES];
	[modalView release];
	if (self.webView.loading) {
		[self.webView stopLoading];
	}
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
	self.shade.alpha = 0.6;
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.2];
	self.shade.alpha = 0.0;
	[UIView commitAnimations];
	self.shade.hidden = YES;
	
	self.tableView.alpha = 0.0;
	self.tableView.hidden = YES;
	searchBar.showsScopeBar = NO;
	[searchBar sizeToFit];
	
	[searchBar resignFirstResponder];
	[self loadWikiEntry:searchBar.text];
}

- (IBAction)stopEditing {
	self.shade.alpha = 0.6;
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.2];
	self.shade.alpha = 0.0;
	[UIView commitAnimations];
	
	self.searchBar.showsScopeBar = NO;
	[self.searchBar sizeToFit];
	[self.searchBar resignFirstResponder];
}

#pragma mark table view

- (void)scrollViewWillBeginDragging:(UIScrollView *)_tableView {
	[self.searchBar resignFirstResponder];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)_tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)_tableView numberOfRowsInSection:(NSInteger)section {
	return [self.searchResults count];
}

- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
        static NSString *CellIdentifier = @"Cell";
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
	
	cell.textLabel.text = [self.searchResults objectAtIndex:indexPath.row];
	
    return [cell autorelease];
}

- (void)tableView:(UITableView *)_tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self loadWikiEntry:[self.searchResults objectAtIndex:indexPath.row]];
	
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	self.searchBar.showsScopeBar = NO;
	[self.searchBar setText:[self.searchResults objectAtIndex:indexPath.row]];
	[self.searchBar sizeToFit];
	[self.searchBar resignFirstResponder];
	
	self.tableView.alpha = 1.0;
	self.shade.alpha = 0.6;
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.2];
	self.shade.alpha = 0.0;
	self.tableView.alpha = 0.0;
	[UIView commitAnimations];
	self.tableView.hidden = YES;
}

#pragma mark toolbar

- (IBAction)showHistory {
	ModalViewController *modalView = [[ModalViewController alloc] initWithNibName:@"ModalViewController" bundle:nil];
	modalView.managedObjectContext = APP_DELEGATE.managedObjectContext;
	modalView.returnView = self;
	modalView.isBookmark = NO;
	[self.navigationController presentModalViewController:modalView animated:YES];
	[modalView release];
	if (self.webView.loading) {
		[self.webView stopLoading];
	}
}

- (IBAction)addBookmark {
	UIActionSheet *menu = [[UIActionSheet alloc]
						   initWithTitle:nil
						   delegate:self
						   cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel")
						   destructiveButtonTitle:nil
						   otherButtonTitles:NSLocalizedString(@"Add Bookmark", @"Add Bookmark"), nil];

	menu.actionSheetStyle = UIActionSheetStyleDefault;
	[menu showInView:self.view];
        [menu release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(int)buttonIndex
{		
	if(buttonIndex == 0)
	{
		self.pageTitle = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"]; 
		
		if (self.pageTitle != nil) {
			[self addBookmark:self.pageTitle];
		}
	}
}


- (void)addBookmark:(NSString *)pageName {
	Bookmark *bookmark = (Bookmark *)[NSEntityDescription insertNewObjectForEntityForName:@"Bookmark" inManagedObjectContext:managedObjectContext];
	
	[bookmark setValue:pageName forKey:@"pageName"];
	[bookmark setValue:self.currentURL forKey:@"pageURL"];
	
	NSError *error;
	if (![managedObjectContext save:&error]) {
	}
}

- (IBAction)goBack {
	[self.webView goBack];
}

- (IBAction)goForward {
	[self.webView goForward];
}

- (IBAction)nearbyButton {
	MapViewController *mapView = [[MapViewController alloc] initWithNibName:@"MapViewController" bundle:nil];
	[self.navigationController presentModalViewController:mapView animated:YES];
	[mapView release];
	if (self.webView.loading) {
		[self.webView stopLoading];
	}
}

- (void)reload {
	[self.webView reload];
}

/*
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	return UIInterfaceOrientationPortrait;
}
*/

#pragma mark HUD

- (void)showLoadingHUD {
	
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
	HUD.mode = MBProgressHUDModeDeterminate;
	
    [self.view addSubview:HUD];
	HUD.delegate = self;
	
    HUD.labelText = NSLocalizedString(@"Loading...", @"Loading...");
	
    [HUD show:YES];
	HUDvisible = YES;
	
	HUD.progress = 0.0f;
}

- (void)hudWasHidden:(MBProgressHUD *)hud {
    HUDvisible = NO;
    [hud removeFromSuperview];
}

#pragma mark memory/unload

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release anything that can be recreated in viewDidLoad or on demand.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
	[_webView release];
    [webViewIntermediaryDelegate release];
    [_searchResults release];
    
    self.externalURL = nil;
}


@end

