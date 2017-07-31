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
	@IBOutlet var rate: UITextField!
	@IBOutlet var drmControlbar: UIView!
	@IBOutlet var policy: UILabel!
	
	var mediaInfo: MediaInfo?
	
	private static let irdetoUrl = "http://sambatech.live.ott.irdeto.com/"
	
	private var sambaPlayer: SambaPlayer?
	private var valReq: ValidationRequest?
	
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
					self.policy.text = self.policies[valReq.policy]
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
				media.backupUrls = m.backupUrls
				media.title = m.title
				media.thumb = m.thumb
				callback(media)
			}
			
			return
		}
		
		let req: SambaMediaRequest

		// VoD
		if let mId = m.mediaId {
			req = SambaMediaRequest(
				projectHash: ph,
				mediaId: mId)
		}
		// Live
		else {
			req = SambaMediaRequest(
				projectHash: ph,
				isLiveAudio: m.isLiveAudio ?? false,
				streamUrl: m.mediaURL!,
				backupUrls: m.backupUrls)
		}
		
		if let env = m.environment {
			req.environment = env
		}
		
		req.apiProtocol = SambaProtocol.https
		
		SambaApi().requestMedia(req, onComplete: callback) { (error, response) in
			print("Erro ao requisitar mídia:", error ?? "no error obj", response ?? "no response obj")
		}
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
			//media.adsSettings.maxRedirects = 0
			//media.adsSettings.playAdsAfterTime = 5
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
	
	func onError(_ error: SambaPlayerError) {
		status.text = "\(error.code) (\(error.cause?.code)): \(error.cause?.localizedDescription ?? error.localizedDescription)"
		print(status.text!)
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
	
	@IBAction func fullscreenHandler() {
		sambaPlayer?.fullscreen = true
	}
	
	@IBAction func controlbarHandler() {
		guard let player = sambaPlayer else { return }
		player.controlsVisible = !player.controlsVisible
	}
	
	@IBAction func createSessionHandler() {
		guard let valReq = valReq,
			let drm = valReq.media?.drmRequest else {
			print("No validation request to create session for DRM media.")
			return
		}
		
		status.text = "Creating session..."
		
		//var req = URLRequest(url: URL(string: "\(PlayerViewController.irdetoUrl)services/CreateSession?CrmId=sambatech&UserId=feijao&CreateUser=true")!)
		var req = URLRequest(url: URL(string: "\(PlayerViewController.irdetoUrl)services/CreateSession?CrmId=sambatech&UserId=samba&CreateUser=true")!)
		req.httpMethod = "POST"
		req.addValue("app@sambatech.com", forHTTPHeaderField: "MAN-user-id")
		req.addValue("c5kU6DCTmomi9fU", forHTTPHeaderField: "MAN-user-password")
		
		let xmlToDrmDelegate: XmlToDrmDelegate = XmlToDrmDelegate() { (sessionId: String, ticket: String) in
			drm.addLicenseParam(key: "SessionId", value: sessionId)
			drm.addLicenseParam(key: "Ticket", value: ticket)
			
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
	
	private let policies = [
		"Aluguel 48h (p5)",
		"Ass. mensal (p6)",
		"Aluguel 48h/BR (p7)",
		"Ass. mensal/BR (p8)"
	]
	
	@IBAction func policyHandler(_ sender: UIButton) {
		guard let valReq = valReq else { return }
		
		let menu = UIAlertController(title: "Policies", message: "Choose a policy to authorize/deauthorize.", preferredStyle: .actionSheet)
		let getCallback = { (index: Int) in
			return { (action: UIAlertAction) in
				valReq.policy = index
				self.policy.text = self.policies[index]
			}
		}
		
		for (i, policy) in policies.enumerated() {
			menu.addAction(UIAlertAction(title: policy, style: .default, handler: getCallback(i)))
		}
		
		menu.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		menu.popoverPresentationController?.sourceView = sender
		menu.popoverPresentationController?.sourceRect = sender.bounds
		
		present(menu, animated: true, completion: nil)
	}
	
	@IBAction func outputHandler(_ sender: UIButton) {
		guard let player = sambaPlayer else { return }
		
		let outputs = player.outputs
		
		guard outputs.count > 1 else { return }
		
		let menu = UIAlertController(title: "Quality", message: "Choose an outputs to switch quality.", preferredStyle: .actionSheet)
		let getCallback = { (index: Int) in
			return { (action: UIAlertAction) in
				player.switchOutput(index)
			}
		}
		
		menu.addAction(UIAlertAction(title: "Auto", style: .default, handler: getCallback(-1)))
		
		for (i, output) in outputs.enumerated() {
			menu.addAction(UIAlertAction(title: output.label, style: .default, handler: getCallback(i)))
		}
		
		menu.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		menu.popoverPresentationController?.sourceView = sender
		menu.popoverPresentationController?.sourceRect = sender.bounds
		
		present(menu, animated: true, completion: nil)
	}
	
	@IBAction func authorizeHandler(_ sender: AnyObject) {
		guard let valReq = valReq,
			let media = valReq.media,
			let drm = media.drmRequest,
			let sessionId = drm.getLicenseParam(key: "SessionId"),
			let ticket = drm.getLicenseParam(key: "Ticket") else {
			print("No validation request or session created to authorize DRM media.")
			return
		}
		
		let deauth = (sender as? UIView)?.tag == 1
		let params: String
		
		switch valReq.policy {
		case 0: params = "&OptionId=6&ContentId=\(media.id)"
		case 1: params = "&PackageId=2"
		case 2: params = "&OptionId=7&ContentId=\(media.id)"
		case 3: params = "&PackageId=3"
		default: params = ""
		}
		
		status.text = deauth ? "Deauthorizing..." : "Authorizing..."
		
		let url = "\(PlayerViewController.irdetoUrl)services/\(deauth ? "Deauthorize" : "Authorize")?CrmId=sambatech&AccountId=sambatech" +
			"&SessionId=\(sessionId)&Ticket=\(ticket)&UserIp=\(AppDelegate.externalIp)\(params)"
		var req = URLRequest(url: URL(string: url)!)
		
		req.httpMethod = "POST"
		req.addValue("app@sambatech.com", forHTTPHeaderField: "MAN-user-id")
		req.addValue("c5kU6DCTmomi9fU", forHTTPHeaderField: "MAN-user-password")
		
		Helpers.requestURL(req) { (response: String?) in
			DispatchQueue.main.async {
				self.status.text = "\(deauth ? "Deauthorized" : "Authorized"): \(valReq.policy < self.policies.count ? self.policies[valReq.policy] : "unknown")"
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
	
	@IBAction func rateHandler() {
		guard let rateStr = self.rate.text,
			let rate = Float(rateStr) else { return }
		sambaPlayer?.rate = rate
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
