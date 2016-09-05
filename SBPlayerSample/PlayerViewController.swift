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
	
	private var sambaPlayer: SambaPlayer?
	
	override func viewDidAppear(animated: Bool) {
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
	
	private func initPlayer(media: SambaMedia) {
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
		
		if let mediaInfo = mediaInfo where mediaInfo.isAutoStart {
			player.play()
		}
		
		sambaPlayer = player
	}
	
	func onLoad() {
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
		guard let time = sambaPlayer?.currentTime else { return }
		currentTime.text = secondsToHoursMinutesSeconds(time)
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
			pos = Float(posStr) else { return }
		sambaPlayer?.seek(pos)
	}
	
	@IBAction func rwHandler() {
		guard let byStr = seekBy.text,
			time = sambaPlayer?.currentTime,
			by = Float(byStr) else { return }
		sambaPlayer?.seek(time - by)
	}
	
	@IBAction func fwHandler() {
		guard let byStr = seekBy.text,
			time = sambaPlayer?.currentTime,
			by = Float(byStr) else { return }
		sambaPlayer?.seek(time + by)
	}
	
	//MARK: utils
	
	private func secondsToHoursMinutesSeconds (seconds : Float) -> (String) {
		let hours = Int(seconds/3600) > 9 ? String(Int(seconds/3600)) : "0" + String(Int(seconds/3600))
		let minutes = Int((seconds % 3600) / 60) > 9 ? String(Int((seconds % 3600) / 60)) : "0" + String(Int((seconds % 3600) / 60))
		let second = Int((seconds % 3600) % 60) > 9 ? String(Int((seconds % 3600) % 60)) : "0" + String(Int((seconds % 3600) % 60))
		return hours + ":" + minutes + ":" + second
	}
}
