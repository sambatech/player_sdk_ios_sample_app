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

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	if (p != nil) return;
	
	p = [[SambaPlayer alloc] initWithParentViewController:self andParentView:_container];
	SambaMedia *media = [[SambaMedia alloc] init:@"http://svbps-sambavideos.akamaized.net/voda/_definst_/amlst%3Astg.test%3B100243%2C530%2C24a89d4aa21fc48385d3412341df8cbd%3Bhidden32%3BWRDYQCD63MQ25BTVKRMEJXYREOJKRTB4OWNZJWDOLOZSNOKZ6QON6R6MPG2CEKS5JJBWBCNHHF4QIWNV6DC75KAABII4Y7T5UNN3W5RS56JJQX5TDS6GXSOH3EZINJFIC4HHUTOXOJFJ3LZWZE7G2WKT7T2FCWZYKVBGTRCEAHLS7XA7FKBA%3D%3D%3D%3D/playlist.m3u8"];
	
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
	int pos = p.currentTime - _seekBy.text.integerValue;
	[p seek:pos > 0 ? pos : 0];
}
- (IBAction)fwHandler {
	if (p == nil) return;
	int pos = p.currentTime + _seekBy.text.integerValue;
	[p seek:pos < p.duration ? pos : p.duration];
}

@end
