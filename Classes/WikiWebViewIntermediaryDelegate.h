//
//  WikiWebView.h
//  Wikipedia Mobile
//
//  Created by Patrick Reilly on 1/5/12.
//  Copyright Wikimedia Foundation 2012. All rights reserved.
//
//  This used to be subclassing from UIWebView. Apple doesn't want you to do that.
//  (See subclassing notes on UIWebView in official documentation)
//  Now it sits between UIWebView and a proper delegate, which is still wonky but legal.
//

@interface WikiWebViewIntermediaryDelegate : NSObject <UIWebViewDelegate>

@property (nonatomic, assign) UIWebView *webView;
@property (nonatomic, retain) NSDictionary *customHeaders;
@property (nonatomic, assign) id<UIWebViewDelegate> delegate;

- (id) initWithWebView:(UIWebView *)webView delegate:(id<UIWebViewDelegate>)delegate;

@end