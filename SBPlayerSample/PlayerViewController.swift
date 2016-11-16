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
	@IBOutlet var status: UILabel!
	@IBOutlet var currentTime: UILabel!
	@IBOutlet var duration: UILabel!
	@IBOutlet var seekTo: UITextField!
	@IBOutlet var seekBy: UITextField!
	@IBOutlet var drmControlbar: UIView!
	
	var mediaInfo: MediaInfo?
	var valReq: ValidationRequest?
	
	private var sambaPlayer: SambaPlayer?
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		guard let m = mediaInfo else {
			print("Error: No media info found!")
			return
		}
		
		guard sambaPlayer == nil else { return }
		
		let callback = { (media: SambaMedia?) in
			guard let media = media else { return }
			
			// DRM media
			if let valReq = m.validationRequest {
				valReq.media = media as? SambaMediaConfig
				self.valReq = valReq
				
				DispatchQueue.main.async {
					self.drmControlbar.isHidden = false
					self.drmControlbar.setNeedsDisplay()
				}
			}
			else {
				self.initPlayer(media)
			}
		}
		
		guard let ph = m.projectHash else {
			if let url = m.mediaURL {
				let media = SambaMediaConfig()
				media.url = url
				media.title = m.title
				media.thumb = m.thumb
				callback(media)
			}
			
			return
		}
		
		let req: SambaMediaRequest

		if let mId = m.mediaId {
			req = SambaMediaRequest(
				projectHash: ph,
				mediaId: mId)
		}
		else {
			req = SambaMediaRequest(
				projectHash: ph,
				streamUrl: m.mediaURL!, isLiveAudio: m.isLiveAudio)
		}
		
		if let env = m.environment {
			req.environment = env
		}
		
		SambaApi().requestMedia(req, callback: callback)
	}
	
	private func initPlayer(_ media: SambaMedia) {
		// media URL injection
		if let url = mediaInfo?.mediaURL {
			media.url = url
			media.outputs?.removeAll()
		}
		
		// ad injection
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
		
		if let mediaInfo = mediaInfo, mediaInfo.isAutoStart {
			player.play()
		}
		
		sambaPlayer = player
	}
	
	func onLoad() {
		if let time = sambaPlayer?.duration {
			duration.text = secondsToHoursMinutesSeconds(time)
		}
		
		status.text = "load"
	}
	
	func onStart() {
		status.text = "start"
	}
	
	func onResume() {
		status.text = "resume"
	}
	
	func onPause() {
		status.text = "pause"
	}
	
	func onProgress() {
		if let time = sambaPlayer?.currentTime {
			currentTime.text = secondsToHoursMinutesSeconds(time)
		}
		
		status.text = "progress"
	}
	
	func onFinish() {
		status.text = "finish"
	}
	
	func onDestroy() {}
	
	func onError(error: SambaPlayerError) {
		status.text = error.localizedDescription
	}
	
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
	
	@IBAction func createSessionHandler() {
		guard let valReq = valReq,
			let drm = valReq.media?.drmRequest else {
			print("No validation request to create session for DRM media.")
			return
		}
		
		status.text = "Creating session..."
		
		var req = URLRequest(url: URL(string: "http://sambatech.stage.ott.irdeto.com/services/CreateSession?CrmId=sambatech&UserId=smbUserTest")!)
		req.httpMethod = "POST"
		req.addValue("app@sambatech.com", forHTTPHeaderField: "MAN-user-id")
		req.addValue("c5kU6DCTmomi9fU", forHTTPHeaderField: "MAN-user-password")
		
		let xmlToDrmDelegate: XmlToDrmDelegate = XmlToDrmDelegate() { (sessionId: String, ticket: String) in
			drm.licenseUrlParams["SessionId"] = sessionId
			drm.licenseUrlParams["Ticket"] = ticket
			
			DispatchQueue.main.async {
				self.status.text = "Session created: \(sessionId)"
			}
		}
		
		Helpers.requestURL(req) { (response: Data?) in
			guard let data = response else { return }
			
			let xml = XMLParser(data: data)
			xml.delegate = xmlToDrmDelegate
			xml.parse()
		}
	}
	
	@IBAction func authorizeHandler() {
		guard let valReq = valReq,
			let drm = valReq.media?.drmRequest,
			let sessionId = drm.licenseUrlParams["SessionId"],
			let ticket = drm.licenseUrlParams["Ticket"],
			valReq.contentId != nil || valReq.packageId != nil else {
			print("No validation request or session created to authorize DRM media.")
			return
		}
		
		status.text = "Authorizing..."
		
		var url = "http://sambatech.stage.ott.irdeto.com/services/Authorize?CrmId=sambatech&AccountId=sambatech&SessionId=\(sessionId)&Ticket=\(ticket)"
		
		if !valReq.policyOnly,
			let contentId = valReq.contentId {
			url += "&ContentId=\(contentId)"
		}
		
		if let packageId = valReq.packageId {
			url += "&\(valReq.contentId == nil ? "PackageId" : "OptionId")=\(packageId)"
		}
		
		var req = URLRequest(url: URL(string: url)!)
		req.httpMethod = "POST"
		req.addValue("app@sambatech.com", forHTTPHeaderField: "MAN-user-id")
		req.addValue("c5kU6DCTmomi9fU", forHTTPHeaderField: "MAN-user-password")
		print(req)
		Helpers.requestURL(req) { (response: String?) in
			DispatchQueue.main.async {
				self.status.text = "Authorized"
			}
		}
	}
	
	@IBAction func loadHandler() {
		guard let media = valReq?.media else {
			print("Invalid DRM media request.")
			return
		}
		
		status.text = "Loading..."
		
		initPlayer(media)
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
	
	private func secondsToHoursMinutesSeconds(_ seconds : Float) -> (String) {
		let s = Int(seconds)
		return String(format: "%02d:%02d:%02d", s/3600%60, s/60%60, s%60)
	}
}

class XmlToDrmDelegate : NSObject, XMLParserDelegate {
	
	let callback: (_: String, _: String) -> Void

	init(callback: @escaping (_: String, _: String) -> Void) {
		self.callback = callback
	}
	
	func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
		guard elementName == "Session",
			let sessionId = attributeDict["SessionId"],
			let ticket = attributeDict["Ticket"]
			else { return }
		
		callback(sessionId, ticket)
	}
}
