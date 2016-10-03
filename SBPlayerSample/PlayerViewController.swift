//
//  ViewController.swift
//  TesteMobileIOS
//
//  Created by Thiago Miranda on 25/02/16.
//  Copyright © 2016 Sambatech. All rights reserved.
//

import UIKit
import SambaPlayer

class PlayerViewController: UIViewController, SambaPlayerDelegate {
	
	@IBOutlet var playerContainer: UIView!
	@IBOutlet var eventName: UILabel!
	@IBOutlet var currentTime: UILabel!
	@IBOutlet var duration: UILabel!
	@IBOutlet var seekTo: UITextField!
	@IBOutlet var seekBy: UITextField!
	
	var mediaInfo: MediaInfo?
	
	fileprivate var sambaPlayer: SambaPlayer?
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		guard let m = mediaInfo else {
			print("Error: No media info found!")
			return
		}
		
		guard sambaPlayer == nil else { return }
		
		let callback = { (media: SambaMedia?) in
			guard let media = media else { return }
			self.initPlayer(media)
		}
		
		if m.mediaId != nil {
			SambaApi().requestMedia(SambaMediaRequest(
				projectHash: m.projectHash,
				mediaId: m.mediaId!), callback: callback)
		}
		else {
			SambaApi().requestMedia(SambaMediaRequest(
				projectHash: m.projectHash,
				streamUrl: m.mediaURL!, isLiveAudio: m.isLiveAudio), callback: callback)
		}
	}
	
	fileprivate func initPlayer(_ media: SambaMedia) {
		// if ad injection
		if let url = mediaInfo?.mediaAd {
			media.adUrl = url
		}

		if media.isAudio {
			var frame = playerContainer.frame
			frame.size.height = media.isLive ? 100 : 50
			playerContainer.frame = frame
		}
		
		let player = SambaPlayer(parentViewController: self, andParentView: playerContainer)
		player.delegate = self
		player.media = media
		
		if let mediaInfo = mediaInfo , mediaInfo.isAutoStart {
			player.play()
		}
		
		sambaPlayer = player
	}
	
	func onLoad() {
		if let time = sambaPlayer?.duration {
			duration.text = secondsToHoursMinutesSeconds(time)
		}
		
		eventName.text = "load"
	}
	
	func onStart() {
		eventName.text = "start"
	}
	
	func onResume() {
		eventName.text = "resume"
	}
	
	func onPause() {
		eventName.text = "pause"
	}
	
	func onProgress() {
		if let time = sambaPlayer?.currentTime {
			currentTime.text = secondsToHoursMinutesSeconds(time)
		}
		
		eventName.text = "progress"
	}
	
	func onFinish() {
		eventName.text = "finish"
	}
	
	func onDestroy() {}
	
	//MARK: actions
	
	@IBAction func playHandler() {
		sambaPlayer?.play()
	}
	
	@IBAction func pauseHandler() {
		sambaPlayer?.pause()
	}
	
	@IBAction func stopHandler() {
		sambaPlayer?.stop()
	}
	
	@IBAction func seekHandler() {
		guard let posStr = seekTo.text,
			let pos = Float(posStr) else { return }
		sambaPlayer?.seek(pos)
	}
	
	@IBAction func rwHandler() {
		guard let byStr = seekBy.text,
			let time = sambaPlayer?.currentTime,
			let by = Float(byStr) else { return }
		sambaPlayer?.seek(time - by)
	}
	
	@IBAction func fwHandler() {
		guard let byStr = seekBy.text,
			let time = sambaPlayer?.currentTime,
			let by = Float(byStr) else { return }
		sambaPlayer?.seek(time + by)
	}
	
	//MARK: utils
	
	fileprivate func secondsToHoursMinutesSeconds(_ seconds : Float) -> (String) {
		let s = Int(seconds)
		return String(format: "%02d:%02d:%02d", s/3600%60, s/60%60, s%60)
	}
}
