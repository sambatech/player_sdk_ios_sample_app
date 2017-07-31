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

- (void)viewDidLoad {
	[super viewDidLoad];
	
	if (p != nil) return;
	
	p = [[SambaPlayer alloc] initWithParentViewController:self andParentView:_container];
	//p.controlsVisible = NO;
	p.delegate = self;
	
	//[self loadVod];
	[self loadLive];
}
- (void)loadVod {
	SambaMedia *media = [[SambaMedia alloc] init:@"http://svbps-sambavideos.akamaized.net/voda/_definst_/amlst%3Astg.test%3B100243%2C530%2C24a89d4aa21fc48385d3412341df8cbd%3Bhidden32%3BWRDYQCD63MQ25BTVKRMEJXYREOJKRTB4OWNZJWDOLOZSNOKZ6QON6R6MPG2CEKS5JJBWBCNHHF4QIWNV6DC75KAABII4Y7T5UNN3W5RS56JJQX5TDS6GXSOH3EZINJFIC4HHUTOXOJFJ3LZWZE7G2WKT7T2FCWZYKVBGTRCEAHLS7XA7FKBA%3D%3D%3D%3D/playlist.m3u8"
										   title:@"Bla bla bla"
										   thumb:nil];
	media.adsSettings.mimeTypes = @[@"video/mp4", @"application/x-mpegURL"];
	media.adsSettings.maxRedirects = 1;
	media.adsSettings.playAdsAfterTime = 5;
	media.adsSettings.vastLoadTimeout = 20;
	p.media = media;
	[p play];
}
- (void)loadLive {
	SambaMediaRequest *request = [[SambaMediaRequest alloc] initWithProjectHash:@"bc6a17435f3f389f37a514c171039b75"
																	  streamUrl:@"http://slrp.sambavideos.sambatech.com/liveevent/tvdiario_7a683b067e5eee5c8d45e1asdfas9b9/livestream/wrong_url.m3u8"
																	 backupUrls:@[@"http://slrp.sambavideos.sambatech.com/liveevent/tvdiario_7a683b067e5eee5c8d45e1asdfas9b9/livestream/wrong_url2.m3u8",
																				  @"http://slrp.sambavideos.sambatech.com/liveevent/tvdiario_7a683b067e5eee5c8d45e1e1883f69b9/livestream/playlist.m3u8"]];
	
	
	[[[SambaApi alloc] init] requestMedia:request onComplete:^(SambaMedia *media) {
		p.media = media;
		[p play];
	}];
}
- (void)onLoad {
	self.eventName.text = @"load";
}
- (void)onProgress {
	self.eventName.text = @"progress";
	self.currentTime.text = [[NSNumber numberWithInt:(int)p.currentTime] stringValue];
}
- (void)onDestroy {
	self.eventName.text = @"destroy";
}
- (void)onFinish {
	self.eventName.text = @"finish";
}
- (void)onResume {
	self.eventName.text = @"resume";
}
- (void)onPause {
	self.eventName.text = @"pause";
}
- (void)onStart {
	self.eventName.text = @"start";
	self.duration.text = [[NSNumber numberWithInt:(int)p.duration] stringValue];
}
- (void)onError:(SambaPlayerError *)error {
	NSLog(@"%@", error.localizedDescription);
	//error.message = [NSString stringWithFormat:@"My custom error message with code #%ld!", (long)error.code];
}
- (IBAction)seekHandler {
	if (p == nil) return;
	[p seek:_seekTo.text.floatValue];
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
	float pos = p.currentTime - _seekBy.text.floatValue;
	[p seek:pos > 0 ? pos : 0];
}
- (IBAction)fwHandler {
	if (p == nil) return;
	float pos = p.currentTime + _seekBy.text.floatValue;
	[p seek:pos < p.duration ? pos : p.duration];
}

@end
