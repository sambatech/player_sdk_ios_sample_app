//
//  ViewController.m
//  TestObjC
//
//  Created by Leandro Zanol on 6/27/16.
//  Copyright © 2016 Samba Tech. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	SambaPlayer *p = [[SambaPlayer alloc] initWithParentViewController:self];
	SambaMedia *media = [[SambaMedia alloc] init:@"http://pvbps-sambavideos.akamaized.net/account/100/6/2015-12-09/video/354849d292e105b3937e262f7caa9ed0/Wildlife_240p.mp4"];
	
	p.media = media;
	p.delegate = self;

	[p play];
}

- (void)onLoad {
	NSLog(@"load");
}
- (void)onProgress {
	//NSLog(@"progress");
}
- (void)onDestroy {
	NSLog(@"destroy");
}
- (void)onFinish {
	NSLog(@"finish");
}
- (void)onResume {
	NSLog(@"resume");
}
- (void)onPause {
	NSLog(@"pause");
}
- (void)onStart {
	NSLog(@"start");
}

@end
