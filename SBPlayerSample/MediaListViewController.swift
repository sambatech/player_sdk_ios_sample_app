//
//  MediaListViewControlller.swift
//  TesteMobileIOS
//
//  Created by Leandro Zanol on 3/3/16.
//  Copyright © 2016 Sambatech. All rights reserved.
//

import AVKit
import SambaPlayer

class MediaListViewController : UITableViewController {
	
	@IBOutlet var liveToggleButton: UIButton!
	@IBOutlet var dfpToggleButton: UIButton!
	@IBOutlet var dfpTextField: UITextField!
	
	private var mediaList = [MediaInfo]()
	private let defaultDfp: String = "4xtfj"
	private var dfpActive: Bool = false
	private var liveActive: Bool = false
	private var isAutoStart: Bool = true
	
	override func viewDidLoad() {
		self.tableView.backgroundColor = UIColor.clear
		makeInitialRequests()
		
		//Button dfp
		let dfpIcon = dfpToggleButton.currentBackgroundImage?.tintPhoto(UIColor.lightGray)
		dfpToggleButton.setImage(dfpIcon, for: UIControlState())
		
		//Button live
		let liveIcon = liveToggleButton.currentBackgroundImage?.tintPhoto(UIColor.lightGray)
		liveToggleButton.setImage(liveIcon, for: UIControlState())
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier != "ListItemToDetail" { return }
		
		let mediaInfo = mediaList[((tableView.indexPathForSelectedRow as NSIndexPath?)?.row)!]
		mediaInfo.isAutoStart = isAutoStart
		
		(segue.destination as! PlayerViewController).mediaInfo = mediaInfo
	}
	
	override func tableView(_ tableView: UITableView?, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "MediaListTableViewCell"
		let cell = tableView!.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! MediaListTableViewCell
		
		let media = mediaList[(indexPath as NSIndexPath).row]
		
		cell.mediaTitle.text = media.title
        cell.mediaDesc.text = media.description ?? ""
		media.imageView = cell.mediaThumb
		
		cell.contentView.backgroundColor = UIColor((indexPath as NSIndexPath).row & 1 == 0 ? 0xEEEEEE : 0xFFFFFF)
		
		return cell
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return mediaList.count
	}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		self.tableView.deselectRow(at: indexPath, animated: false)
	}
	
	private func makeInitialRequests() {
		requestMediaSet([String.init(4421), String.init(4460)])
	}
	
	private func requestMediaSet(_ pids:[String]) {
		var i = 0

		// INJECTED MEDIA
		
		var m = MediaInfo(
			title: "DRM Irdeto (pol#7)",
			thumb: "http://pcgamingwiki.com/images/thumb/b/b3/DRM-free_icon.svg/120px-DRM-free_icon.svg.png",
			projectHash: "b00772b75e3677dba5a59e09598b7a0d",
			mediaId: "4a48d2ea922217a3d91771f2acf56fdf"
		)
		m.mediaURL = "http://52.32.88.36/sambatech/stage/MrPoppersPenguins.ism/MrPoppersPenguins.m3u8"
		m.validationRequest = ValidationRequest(packageId: 10)
		m.environment = .test
		mediaList.append(m)
		
		m = MediaInfo(
			title: "DRM Samba (pol#7)",
			thumb: "http://pcgamingwiki.com/images/thumb/b/b3/DRM-free_icon.svg/120px-DRM-free_icon.svg.png",
			projectHash: "b00772b75e3677dba5a59e09598b7a0d",
			mediaId: "4a48d2ea922217a3d91771f2acf56fdf"
		)
		m.mediaURL = "http://107.21.208.27/vodd/_definst_/mp4:myMovie.mp4/playlist.m3u8"
		m.validationRequest = ValidationRequest(packageId: 10)
		m.environment = .test
		mediaList.append(m)
		
		m = MediaInfo(
			title: "DRM Samba (pol#8)",
			thumb: "http://pcgamingwiki.com/images/thumb/b/b3/DRM-free_icon.svg/120px-DRM-free_icon.svg.png",
			projectHash: "b00772b75e3677dba5a59e09598b7a0d",
			mediaId: "4a48d2ea922217a3d91771f2acf56fdf"
		)
		m.mediaURL = "http://107.21.208.27/vodd/_definst_/mp4:chaves3_480p.mp4/playlist.m3u8"
		m.validationRequest = ValidationRequest(packageId: 10)
		m.environment = .test
		mediaList.append(m)
		
		m = MediaInfo(
			title: "DRM Samba (pol#9)",
			thumb: "http://pcgamingwiki.com/images/thumb/b/b3/DRM-free_icon.svg/120px-DRM-free_icon.svg.png",
			projectHash: "b00772b75e3677dba5a59e09598b7a0d",
			mediaId: "4a48d2ea922217a3d91771f2acf56fdf"
		)
		m.mediaURL = "http://107.21.208.27/vodd/_definst_/mp4:agdq.mp4/playlist.m3u8"
		m.validationRequest = ValidationRequest(packageId: 10)
		m.environment = .test
		mediaList.append(m)
		
		m = MediaInfo(
			title: "Geoblock (dev)",
			thumb: "https://www.wowza.com/uploads/blog/icon-geo-ip-blocking.png",
			projectHash: "90fe205bd667e40036dd56619d69359f",
			mediaId: "316acbc528936927423ffe066be0d05a"
		)
		m.environment = .test
		mediaList.append(m)
		
		func request() {
			let pid = pids[i]
			let url = "\(Helpers.settings["svapi_endpoint"]!)medias?access_token=\(Helpers.settings["svapi_token"]!)&pid=\(pid)&published=true"
			
			Helpers.requestURLJson(url) { json in
				guard let json = json as? [AnyObject] else { return }
				
				for jsonNode in json {
					var isAudio = false
					
					// skip non video or audio media
					switch (jsonNode["qualifier"] as? String ?? "").lowercased() {
					case "audio":
						isAudio = true
						fallthrough
					case "video": break
					default: continue
					}
					
					var thumbUrl = ""

					if let thumbs = jsonNode["thumbs"] as? [AnyObject] {
						for thumb in thumbs {
							if let url = thumb["url"] as? String {
								thumbUrl = url
							}
						}
					}

					let m = MediaInfo(
						title: jsonNode["title"] as? String ?? "",
						thumb: isAudio ? "https://cdn4.iconfinder.com/data/icons/defaulticon/icons/png/256x256/media-volume-2.png" : thumbUrl,
						projectHash: Helpers.settings["pid_" + pid]!,
						mediaId: jsonNode["id"] as? String ?? nil,
						isAudio: isAudio
					)
					
					self.mediaList.append(m)
				}
				
				i += 1
				
				if i == pids.count {
					DispatchQueue.main.async {
						self.tableView.reloadData()
					}
					return
				}
				
				request()
			}
		}
		
		if i < pids.count {
			request()
		}
	}
	
	private func requestAds(_ hash: String) {
		let url = "\(Helpers.settings["myjson_endpoint"]!)\(hash)"
		
		Helpers.requestURLJson(url) { json in
			DispatchQueue.main.async {
				guard let json = json as? [AnyObject] else {
					self.enableDfpButton(false)
					return
				}
				
				var dfpIndex = 0
				
				for media in self.mediaList where !media.isAudio {
					dfpIndex = dfpIndex < json.count - 1 ? dfpIndex + 1 : 0
					
					media.description = json[dfpIndex]["name"] as? String
					media.mediaAd = json[dfpIndex]["url"] as? String
				}
				
				self.tableView.reloadData()
			}
		}
	}
	
	private func enableDfpButton(_ state: Bool) {
		guard state != dfpActive else { return }
		
		// disabling ads
		if !state {
			for media in mediaList {
				media.description = nil
				media.mediaAd = nil
			}
			
			self.tableView.reloadData()
		}
		
		let dfpIcon = dfpToggleButton.currentBackgroundImage?.tintPhoto(state ? UIColor.clear : UIColor.lightGray)
		dfpToggleButton.setImage(dfpIcon, for: UIControlState())
		
		dfpActive = state
	}
	
	private func enableLiveButton(_ state: Bool) {
		guard state != liveActive else { return }
		
		mediaList = [MediaInfo]()
		if(!state) {
			makeInitialRequests()
			enableDfpButton(false)
		}
		
		let liveIcon = liveToggleButton.currentBackgroundImage?.tintPhoto(state ? UIColor.clear : UIColor.lightGray)
		liveToggleButton.setImage(liveIcon, for: UIControlState())
		
		liveActive = state
	}
	
	//Fill live
	private func fillLive() {
		let thumbURL = "http://www.impactmobile.com/files/2012/09/icon64-broadcasts.png"
		let ph = "bc6a17435f3f389f37a514c171039b75"
		
		let m = MediaInfo(
			title: "Live SBT (HLS)",
			thumb:  thumbURL,
			projectHash: ph,
			mediaId: nil,
			isAudio: false,
			mediaURL: "http://gbbrlive2.sambatech.com.br/liveevent/sbt3_8fcdc5f0f8df8d4de56b22a2c6660470/livestream/manifest.m3u8"
		)
		
		self.mediaList.append(m)
		
		let m1 = MediaInfo(
			title: "Live VEVO (HLS)",
			thumb: thumbURL,
			projectHash: ph,
			mediaId: nil,
			isAudio: false,
			mediaURL: "http://vevoplaylist-live.hls.adaptive.level3.net/vevo/ch1/appleman.m3u8"
		)
		
		self.mediaList.append(m1)
		
		let m2 = MediaInfo(
			title: "Live Denmark channel (HLS)",
			thumb: thumbURL,
			projectHash: ph,
			mediaId: nil,
			isAudio: false,
			mediaURL: "http://itv08.digizuite.dk/tv2b/ngrp:ch1_all/playlist.m3u8"
		)
		
		self.mediaList.append(m2)
		
		let m3 = MediaInfo(
			title: "Live Denmark channel (HDS: erro!)",
			thumb: thumbURL,
			projectHash: ph,
			mediaId: nil,
			isAudio: false,
			mediaURL: "http://itv08.digizuite.dk/tv2b/ngrp:ch1_all/manifest.f4m"
		)
		
		self.mediaList.append(m3)
		
		let m4 = MediaInfo(
			title: "Tv Diário",
			thumb: thumbURL,
			projectHash: ph,
			mediaId: nil,
			isAudio: false,
			mediaURL: "http://slrp.sambavideos.sambatech.com/liveevent/tvdiario_7a683b067e5eee5c8d45e1e1883f69b9/livestream/playlist.m3u8"
		)
		
		self.mediaList.append(m4)
		
		let m5 = MediaInfo(title: "Live áudio",
		                   thumb: "https://cdn4.iconfinder.com/data/icons/defaulticon/icons/png/256x256/media-volume-2.png",
		                   projectHash: ph,
		                   mediaId: nil,
		                  mediaURL: "http://slrp.sambavideos.sambatech.com/radio/pajucara4_7fbed8aac5d5d915877e6ec61e3cf0db/livestream/playlist.m3u8",
		                  isLiveAudio: true)
		
		self.mediaList.append(m5)
		
		self.tableView.reloadData()
	}
	
	@IBAction func dfpTapped() {
		enableDfpButton(!dfpActive)
		
		if dfpActive {
			requestAds((dfpTextField.text ?? "").isEmpty ? defaultDfp : dfpTextField.text!)
		}
	}
	
	@IBAction func dfpEditingChanged() {
		enableDfpButton(false)
	}
	
	@IBAction func liveTapped(_ sender: AnyObject) {
		enableLiveButton(!liveActive)
		
		if liveActive {
			fillLive()
		}
	}
	
	@IBAction func autoStartHandler(_ sender: UIButton) {
		sender.tintColor = isAutoStart ? UIColor.lightGray : UIColor(colorLiteralRed: 0, green: 0.4, blue: 1, alpha: 1)
		isAutoStart = !isAutoStart
	}
}

class MediaInfo {
	
	let title:String
	let projectHash:String?
	let mediaId:String?
	let isAudio:Bool
	var mediaAd:String?
	var description:String?
	var mediaURL:String?
	let isLiveAudio: Bool?
	var isAutoStart = true
	var validationRequest: ValidationRequest?
	var environment: SambaMediaRequest.Environment?
	
	var thumb:UIImage? {
		didSet {
			if let imageView = imageView {
				self.imageView = imageView
			}
		}
	}
	
	var imageView: UIImageView? {
		didSet {
			guard let imageView = imageView else { return }
			
			if let thumb = thumb {
				DispatchQueue.main.async {
					imageView.image = thumb
				}
			}
		}
	}
	
	init(title:String, thumb:String? = nil, projectHash:String? = nil, mediaId:String? = nil,
	     isAudio:Bool = false, description:String? = nil, mediaAd:String? = nil,
	     mediaURL:String? = nil, isLiveAudio: Bool? = false) {
		self.title = title
		self.projectHash = projectHash
		self.mediaId = mediaId
		self.isAudio = isAudio
		self.description = description
		self.mediaAd = mediaAd
		self.mediaURL = mediaURL
		self.isLiveAudio = isLiveAudio
		
		load_image(thumb)
	}
	
	private func load_image(_ url: String?) {
		guard let url = url else { return }
		
		Helpers.requestURL(url) { (data: Data?) in
			if let data = data,
				let img = UIImage(data: data) {
				self.thumb = img
			}
		}
	}
}

class ValidationRequest {
	
	let packageId: Int
	var media: SambaMediaConfig?
	
	init(packageId: Int) {
		self.packageId = packageId
	}
}
