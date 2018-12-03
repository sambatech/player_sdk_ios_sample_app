//
//  OfflineViewController.swift
//  Player-swift
//
//  Created by Kesley Vaz on 28/11/18.
//  Copyright © 2018 Samba Tech. All rights reserved.
//

import UIKit
import SambaPlayer

class OfflineViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let TOKEN_DRM = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImY5NTRiMTIzLTI1YzctNDdmYy05MmRjLThkODY1OWVkNmYwMCJ9.eyJzdWIiOiJkYW1hc2lvLXVzZXIiLCJpc3MiOiJkaWVnby5kdWFydGVAc2FtYmF0ZWNoLmNvbS5iciIsImp0aSI6IklIRzlKZk1aUFpIS29MeHNvMFhveS1BZG83bThzWkNmNW5OVWdWeFhWSTg9IiwiZXhwIjoxNTQzNTE5MDMxLCJpYXQiOjE1NDM0MzMwMzEsImFpZCI6ImRhbWFzaW8ifQ.FqvQF0qRgiLsFdawSvqfeJVKfIp4obELjlOU7x64lug"
    
    
    @IBOutlet weak var containerPlayerView: UIView!
    
    @IBOutlet weak var mediasTableView: UITableView!
    
    @IBOutlet weak var progressContainer: UIView!
    
    @IBOutlet weak var progressView: UIActivityIndicatorView!
    
    var mediaList: [MediaInfo] = []
    
    var sambaPlayer: SambaPlayer?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.mediasTableView.tableFooterView = UIView(frame: CGRect.zero)
        sambaPlayer = SambaPlayer(parentViewController: self, andParentView: containerPlayerView)
        sambaPlayer?.delegate = self
        
        mediaList.append(MediaInfo(
            title: "Media DRM 1",
            projectHash: "f596f53018dc9150eee6661d891fb1d2",
            mediaId: "1171319f6347a0a9c19b0278c0956eb6",
            mediaAd: nil,
            validationRequest: nil,
            isLive: false,
            drmToken: TOKEN_DRM
        ))
        
        mediaList.append(MediaInfo(
            title: "Media DRM 2",
            projectHash: "f596f53018dc9150eee6661d891fb1d2",
            mediaId: "0fefcc50c47fdfe61f52b14c8ad62343",
            mediaAd: nil,
            validationRequest: nil,
            isLive: false,
            drmToken: TOKEN_DRM
        ))
        
        mediaList.append(MediaInfo(
            title: "Media Playplus",
            projectHash: "fad2b4a201ef2305d06cb817da1bd262",
            mediaId: "ca60065f62e83445a4c5ae91abd3eacf",
            mediaAd: nil,
            validationRequest: nil,
            isLive: false
        ))
        
        mediaList.append(MediaInfo(
            title: "Media Legenda",
            projectHash: "964b56b4b184c2a29e3c2065a7a15038",
            mediaId: "b4c134b2a297d9eacfe7c7852fa86312",
            mediaAd: nil,
            validationRequest: nil,
            isLive: false
        ))
        
        mediaList.append(MediaInfo(
            title: "Teste Audio",
            projectHash: "4f25046e52b1b4643efd8a328b78fbf3",
            mediaId: "bc6e1ec855f8f1142232f4282bfe5ed9",
            mediaAd: nil,
            validationRequest: nil,
            isLive: false
        ))
        
        mediasTableView.reloadData()
        
    }
    
    //MARK: - TableView
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mediaList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "mediaCellOffline") as! MediaOfflineCell
        
        cell.media = mediaList[indexPath.row]
        
        cell.delegate = self
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        let mediaInfo = mediaList[indexPath.row]
        
        SambaApi().requestMedia(SambaMediaRequest(projectHash: mediaInfo.projectHash!, mediaId: mediaInfo.mediaId!), onComplete: { [weak self] (sambaMedia) in
            
            guard let strongSelf = self else {return}
            
            if let sambaConfig = sambaMedia as? SambaMediaConfig, let drmRequest = sambaConfig.drmRequest {
                drmRequest.token = mediaInfo.drmToken
            }
            
            strongSelf.sambaPlayer?.destroy()
            strongSelf.sambaPlayer?.media = sambaMedia!
            strongSelf.sambaPlayer?.play()
            
        }) { [weak self] (error, response) in
            guard let strongSelf = self else {return}
            strongSelf.showErrorDialog("Erro ao carregar a media.")
        }
        
    }
    
    func showErrorDialog(_ error: String) {
        
        let alert = UIAlertController(title: "Atenção", message: error, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func enableProgress(_ enable: Bool) {
        
        if enable {
            progressContainer.isHidden = false
            progressView.startAnimating()
        } else {
            progressContainer.isHidden = true
            progressView.stopAnimating()
        }
        
    }
    
    func buildResolutionsDialog(with request: SambaDownloadRequest, onClick: @escaping (_ sambaTrack: SambaTrack) -> Void) {
        let alert = UIAlertController(title: "Download Media", message: "Escolha a resolução desejada.", preferredStyle: .alert)
        
        var tracks: [SambaTrack] = []
        
        tracks.append(contentsOf: request.sambaVideoTracks ?? [] as! [SambaTrack])
        tracks.append(contentsOf: request.sambaAudioTracks ?? [] as! [SambaTrack])
        
        tracks.forEach { (item) in
            alert.addAction(UIAlertAction(title: String(format: "\(item.title) - %.0f MB", item.sizeInMb), style: .default, handler: { (action) in
                onClick(item)
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Cancelar", style: .destructive, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

}


extension OfflineViewController: SambaPlayerDelegate {
    
    func onLoad() {
        
    }
    
    func onPause() {
        
    }
    
    func onFinish() {
        
    }
    
}

extension OfflineViewController: DownloadClickDelegate {
    
    func onDownloadClick(with mediaInfo: MediaInfo) {
        
        guard !SambaDownloadManager.sharedInstance.isDownloaded(mediaInfo.mediaId!) else {
            showErrorDialog("A media já foi baixada")
            return
        }
        
        guard !SambaDownloadManager.sharedInstance.isDownloading(mediaInfo.mediaId!) else {
            showErrorDialog("O download da media já está sendo realizado")
            return
        }
        
        enableProgress(true)
        
        let request = SambaDownloadRequest(mediaId: mediaInfo.mediaId!, projectHash: mediaInfo.projectHash!)

        if let token = mediaInfo.drmToken, !token.isEmpty {

            request.drmToken = token

        }
    
        SambaDownloadManager.sharedInstance.prepareDownload(with: request, successCallback: { [weak self](sambaDownloadRequest) in
            guard let strongSelf = self else {return}
            
            strongSelf.enableProgress(false)
            strongSelf.buildResolutionsDialog(with: request, onClick: { (sambaTrack) in
                
                request.sambaTrackForDownload = sambaTrack
                SambaDownloadManager.sharedInstance.performDownload(with: request)
            })
            
        }) { [weak self] (error, msg) in
            guard let strongSelf = self else {return}
            strongSelf.enableProgress(false)
            strongSelf.showErrorDialog("Error ao preparar o Download.")
        }
    
        
    }
    
}
