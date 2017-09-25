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
	
	var categoryInfo: CategoryInfo?
	
	private var mediaList = [MediaInfo]()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.tableView.backgroundColor = UIColor.clear
		
		makeInitialRequests()
		
		// refresh control
		let refreshControl = UIRefreshControl()
		refreshControl.addTarget(self, action: #selector(refreshRequestedHandler), for: .valueChanged)
		refreshControl.tintColor = UIColor(0xCCCCCC)
		self.refreshControl = refreshControl
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard segue.identifier == "MediaToPlayer",
			let index = (tableView.indexPathForSelectedRow as NSIndexPath?)?.row,
			index < mediaList.count
		else { return }
		
		(segue.destination as! PlayerViewController).mediaInfo = mediaList[index]
	}
	
	override func tableView(_ tableView: UITableView?, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "MediaCell"
		let cell = tableView!.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! MediaCell
		
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
		Helpers.requestURLJson("https://api.myjson.com/bins/15yyvl") { json in
			guard let json = json as? [AnyObject] else {
				// hides fetching data info
				self.refreshControl?.endRefreshing()
				return
			}
			
			for jsonNode in json {
				var isAudio = false
				var env = SambaEnvironment.prod
				let params = jsonNode["params"] as AnyObject
				var backupUrls = [String]()
				
				// skip non video or audio media
				switch (jsonNode["qualifier"] as? String ?? "").lowercased() {
				case "audio": isAudio = true
				default: break
				}
				
				switch (jsonNode["env"] as? String ?? "").lowercased() {
				case "prod": env = .prod
				case "staging": env = .staging
				case "dev": fallthrough
				case "web1-13000": env = .test
				default: break
				}
				
				if let backupUrl = params["backupLive"] as? String {
					backupUrls.append(backupUrl)
				}

				let m = MediaInfo(
					title: jsonNode["title"] as? String ?? "Unknown",
					description: jsonNode["description"] as? String,
					thumb: isAudio ? "https://cdn4.iconfinder.com/data/icons/defaulticon/icons/png/256x256/media-volume-2.png" : jsonNode["thumbnail"] as? String,
					projectHash: jsonNode["ph"] as? String,
					// tries to get VOD or Live ID
					mediaId: jsonNode["id"] as? String ?? jsonNode["liveChannelId"] as? String,
					mediaAd: params["ad_program"] as? String,
					// WORKAROUND: to identify which project has DRM
					validationRequest: (jsonNode["drm"] as? Bool ?? false) ? ValidationRequest() : nil,
					isLive: jsonNode["liveChannelId"] != nil,
					isAudio: isAudio,
					env: env,
					mediaUrl: params["primaryLive"] as? String,
					backupUrls)
				
				self.mediaList.append(m)
			}
			
			DispatchQueue.main.async {
				self.tableView.reloadData()
				// hides fetching data info
				self.refreshControl?.endRefreshing()
			}
		}
	}
	
	@objc private func refreshRequestedHandler() {
		mediaList = [MediaInfo]()
		makeInitialRequests()
	}
}

class MediaInfo {
	
	let title: String
	let projectHash: String?
	let mediaId: String?
	var mediaAd: String?
	var description: String?
	let isLive: Bool
	let isAudio: Bool
	let isLiveAudio: Bool?
	let isDvr: Bool
	var isAutoStart = true
	var validationRequest: ValidationRequest?
	var environment: SambaEnvironment?
	var mediaUrl: String?
	var backupUrls: [String]
	
	var thumb: UIImage? {
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
	
	init(title: String, description: String? = nil, thumb: String? = nil, projectHash: String? = nil, mediaId: String? = nil,
	     mediaAd: String? = nil, validationRequest: ValidationRequest?, isLive: Bool = false, isAudio: Bool = false, isLiveAudio: Bool? = false,
	     isDvr: Bool = false, env: SambaEnvironment? = nil, mediaUrl: String? = nil, _ backupUrls: [String]? = nil) {
		self.title = title
		self.description = description
		self.projectHash = projectHash
		self.mediaId = mediaId
		self.validationRequest = validationRequest
		self.mediaAd = mediaAd
		self.isLive = isLive
		self.isAudio = isAudio
		self.isLiveAudio = isLiveAudio
		self.isDvr = isDvr
		self.environment = env
		self.mediaUrl = mediaUrl
		self.backupUrls = backupUrls ?? [String]()
		
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
	let contentId: String?
	var media: SambaMediaConfig?
	var policy: Int = 0
	
	init(contentId: String? = nil) {
		self.contentId = contentId
	}
	
	convenience init(contentId: String? = nil, policy: Int) {
		self.init(contentId: contentId)
		self.policy = policy
	}
}
