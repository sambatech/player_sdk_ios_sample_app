//
//  MediaOfflineCellTableViewCell.swift
//  Player-swift
//
//  Created by Kesley Vaz on 28/11/18.
//  Copyright © 2018 Samba Tech. All rights reserved.
//

import UIKit

class MediaOfflineCell: UITableViewCell {
    
    @IBOutlet weak var mediaTitleLabel: UILabel!
    
    @IBOutlet weak var progressContainer: UIView!
    
    @IBOutlet weak var progressView: UIProgressView!
    
    @IBOutlet weak var progressLabel: UILabel!
    
    @IBOutlet weak var indeterminateProgress: UIActivityIndicatorView!
    
    @IBOutlet weak var downloadButton: UIButton!
    
    
    weak var delegate: DownloadClickDelegate?
    
    var media: MediaInfo? {
        didSet {
            mediaTitleLabel.text = media?.title
        }
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let progresstap = UITapGestureRecognizer(target: self, action: #selector(progressContainerClick))
        self.progressContainer.addGestureRecognizer(progresstap)
        
    }
    
    @IBAction func downloadButtonClicked(_ sender: Any) {
        delegate?.onDownloadClick(with: media!)
    }
    
    @objc func progressContainerClick() {
        delegate?.onDownloadClick(with: media!)
    }
    

}


protocol DownloadClickDelegate: class {
    func onDownloadClick(with mediaInfo: MediaInfo)
}
