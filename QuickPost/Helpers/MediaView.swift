//
//  MediaView.swift
//  QuickPost
//
//  Created by Tudor Ana on 8/9/18.
//  Copyright © 2018 Tudor Ana. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class MediaView: UIImageView {
    
    var overlayVideoView: UIView?
    var player: AVPlayer = AVPlayer()
    var playerLayer: AVPlayerLayer? = AVPlayerLayer()
    var allowSound: Bool = false
    var allowAutoplay: Bool = false
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        overlayVideoView = UIView(frame: self.bounds)
        overlayVideoView?.backgroundColor = .clear
        overlayVideoView?.isHidden = true
        self.addSubview(overlayVideoView!)
        
        self.playerLayer?.bounds = self.bounds
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.overlayVideoView?.frame = self.bounds
        self.playerLayer?.bounds = self.bounds
    }
    
    
    func show(mediaUrl: URL, thumbnailUrl: URL? = nil) {
        remove()
        
        
        if mediaUrl.pathExtension.lowercased() == "jpg" || mediaUrl.absoluteString.lowercased().contains("jpg") || mediaUrl.absoluteString.lowercased().contains("png") {
            self.overlayVideoView?.isHidden = true
            self.kf.setImage(with: mediaUrl)
        } else {
            
            
            
            if let _ = thumbnailUrl {
                self.kf.setImage(with: thumbnailUrl!)
            } else {
                self.image = nil
            }
            
            
            
            
            let md5Filename = String(format: "%ld", mediaUrl.absoluteString.hashValue)
            let fileName = String(format: "%@-video.mp4", md5Filename)
            var fileURL: URL? = nil
            do {
                fileURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(fileName)
            } catch {
                po(error)
            }
            
            guard let _ = fileURL else { return }
            
            if fileExistsAt(filename: fileName) {
                
                self.player.replaceCurrentItem(with: AVPlayerItem(url: fileURL!))
                
                if allowAutoplay {
                    self.playerLayer = AVPlayerLayer(player: self.player)
                    self.playerLayer?.frame = self.bounds
                    self.playerLayer?.videoGravity = .resizeAspectFill
                    self.playerLayer?.backgroundColor = UIColor.clear.cgColor
                    
                    
                    self.player.play()
                    self.player.isMuted = !self.allowSound
                    self.overlayVideoView?.layer.addSublayer(self.playerLayer!)
                    self.overlayVideoView?.isHidden = false
                }
            } else {
                
                download(dataCompletion: { (data) in
                    
                    DispatchQueue.main.safeAsync { [weak self] in
                        guard let _ = self else { return }
                        
                        do {
                            
                            if !self!.fileExistsAt(filename: fileName) {
                                try data.write(to: fileURL!, options: .atomic)
                            }
                            
                            self!.player.replaceCurrentItem(with: AVPlayerItem(url: fileURL!))
                            
                            if self!.allowAutoplay {
                                self!.playerLayer = AVPlayerLayer(player: self!.player)
                                self!.playerLayer?.frame = self!.bounds
                                self!.playerLayer?.videoGravity = .resizeAspectFill
                                self!.playerLayer?.backgroundColor = UIColor.clear.cgColor
                                
                                
                                self!.player.play()
                                self!.player.isMuted = !self!.allowSound
                                self!.overlayVideoView?.layer.addSublayer(self!.playerLayer!)
                                self!.overlayVideoView?.isHidden = false
                            }
                        } catch {
                            po(error)
                        }
                    }
                    
                }, from: mediaUrl)
            }
            
        }
    }
}

extension MediaView {
    
    
    func download(dataCompletion: @escaping (Data) -> (Void), from url: URL) {
        
        DispatchQueue.global(qos: .utility).async {
            URLSession.shared.dataTask(with: url) { (data, response, error) in
                guard let _ = data else { return }
                dataCompletion(data!)
                }.resume()
        }
    }
    
    
    func remove() {
        
        self.playerLayer?.player?.isMuted = true
        self.playerLayer?.player?.pause()
        self.playerLayer?.removeFromSuperlayer()
        self.playerLayer = nil
        self.overlayVideoView?.isHidden = true
        
        if let overlayVideoViewT = self.overlayVideoView {
            overlayVideoViewT.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        }
    }
    
    func fileExistsAt(filename: String) -> Bool {
        
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        let filePath = url.appendingPathComponent(filename)?.path
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: filePath!) {
            return true
        } else {
            return false
        }
    }
}
