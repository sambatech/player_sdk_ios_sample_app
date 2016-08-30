//
//  ViewController.m
//  TestObjC
//
//  Created by Leandro Zanol on 6/27/16.
//  Copyright © 2016 Samba Tech. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (strong, nonatomic) IBOutlet UIView *container;
@property (strong, nonatomic) IBOutlet UITextField *seekTo;
@property (strong, nonatomic) IBOutlet UITextField *seekBy;
@property (strong, nonatomic) IBOutlet UILabel *eventName;
@property (strong, nonatomic) IBOutlet UILabel *currentTime;
@property (strong, nonatomic) IBOutlet UILabel *duration;

@end

@implementation ViewController

SambaPlayer *p;
BOOL asdf;

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	p = [[SambaPlayer alloc] initWithParentViewController:self andParentView:_container];
	SambaMedia *media = [[SambaMedia alloc] init:@"http://pvbps-sambavideos.akamaized.net/account/100/6/2015-12-09/video/354849d292e105b3937e262f7caa9ed0/Wildlife_240p.mp4"];
	
	p.media = media;
	//p.controlsVisible = NO;
	p.delegate = self;

	[p play];
}

- (void)onLoad {
	self.eventName.text = @"load";
	NSLog(@"load");
}
- (void)onProgress {
	self.eventName.text = @"progress";
	self.currentTime.text = [[NSNumber numberWithInt:(int)p.currentTime] stringValue];
	NSLog(@"progress");
}
- (void)onDestroy {
	self.eventName.text = @"destroy";
	NSLog(@"destroy");
}
- (void)onFinish {
	self.eventName.text = @"finish";
	NSLog(@"finish");
}
- (void)onResume {
	self.eventName.text = @"resume";
	NSLog(@"resume");
}
- (void)onPause {
	self.eventName.text = @"pause";
	NSLog(@"pause");
}
- (void)onStart {
	self.eventName.text = @"start";
	self.duration.text = [[NSNumber numberWithInt:(int)p.duration] stringValue];
	NSLog(@"start");
}
- (IBAction)seekHandler {
	if (p == nil) return;
	[p seek:_seekTo.text.integerValue];
}
- (IBAction)playHandler {
	if (p == nil) return;
	[p play];
}
- (IBAction)pauseHandler {
	if (p == nil) return;
	[p pause];
}
- (IBAction)stopHandler {
	if (p == nil) return;
	[p stop];
}
- (IBAction)rwHandler {
	if (p == nil) return;
	int pos = _seekBy.text.integerValue - p.currentTime;
	[p seek:pos > 0 ? pos : 0];
}
- (IBAction)fwHandler {
	if (p == nil) return;
	int pos = _seekBy.text.integerValue + p.currentTime;
	[p seek:pos < p.duration ? pos : p.duration];
}

@end
