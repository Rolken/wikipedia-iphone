//
//  WikiWebView.m
//  Wikipedia Mobile
//
//  Created by Patrick Reilly on 1/5/12.
//  Copyright Wikimedia Foundation 2012. All rights reserved.
//

#import "WikiWebViewIntermediaryDelegate.h"


@implementation WikiWebViewIntermediaryDelegate

@synthesize webView = _webView;
@synthesize customHeaders = _customHeaders;
@synthesize delegate = _delegate;

- (id) initWithWebView:(UIWebView *)webView delegate:(id<UIWebViewDelegate>)delegate {
	if((self = [super init])) {
        // This is the three-way interplay in question. Heh.
        self.webView = webView;
        webView.delegate = self;
        self.delegate = delegate;
	}
	
	return self;
}

- (void) setCustomHeaders:(NSDictionary *)cHeaders {
	
    // Property set is overridden to force all keys to be lowercase.
    
	NSMutableDictionary *newHeaders = [NSMutableDictionary dictionary];
	for(NSString *key in [cHeaders allKeys]) {
		NSString *lowercaseKey = [key lowercaseString];
		[newHeaders setObject:[cHeaders objectForKey:key] forKey:lowercaseKey];
	}
	
	[_customHeaders release];
	_customHeaders = [[NSDictionary dictionaryWithDictionary:newHeaders] retain];
}

- (void) dealloc {
	[_customHeaders release];
	[super dealloc];
}

#pragma mark -
#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)aRequest navigationType:(UIWebViewNavigationType)navigationType {	

	BOOL missingHeaders = NO;

	NSArray *currentHeaders = [[aRequest allHTTPHeaderFields] allKeys];
	NSMutableArray *lowercasedHeaders = [NSMutableArray array];
	for(NSString *key in currentHeaders) {
		[lowercasedHeaders addObject:[key lowercaseString]];
	}

	for(NSString *key in self.customHeaders) {
		if(![lowercasedHeaders containsObject:key]) {
			missingHeaders = YES;
			break;
		}
	}

	if(missingHeaders) {
		NSMutableURLRequest *newRequest = [aRequest mutableCopy];
		for(NSString *key in [self.customHeaders allKeys]) {
			[newRequest setValue:[self.customHeaders valueForKey:key] forHTTPHeaderField:key];
		}
		[self.webView loadRequest:newRequest];
		[newRequest release];
		return NO;
	}
	
	if([self.delegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]) {
		return [self.delegate webView:webView shouldStartLoadWithRequest:aRequest navigationType:navigationType];
	}
	
	return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
	if([self.delegate respondsToSelector:@selector(webViewDidStartLoad:)])
		[self.delegate webViewDidStartLoad:webView];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
	if([self.delegate respondsToSelector:@selector(webViewDidFinishLoad:)])
		[self.delegate webViewDidFinishLoad:webView];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	if([self.delegate respondsToSelector:@selector(webView:didFailLoadWithError:)])
		[self.delegate webView:webView didFailLoadWithError:error];
}

@end