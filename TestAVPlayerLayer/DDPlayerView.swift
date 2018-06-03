//
//  DDPlayerView.swift
//  TestAVPlayerLayer
//
//  Created by WY on 2018/6/2.
//  Copyright © 2018年 HHCSZGD. All rights reserved.
//

import UIKit
import AVKit
class DDPlayerView: UIView {
    var playerLayer : AVPlayerLayer?
    private let bottomBar = UIView()
    private let playButton = UIButton()
    private var ddSuperView : UIView?
    private let slider = UISlider()
    private var currentItemTotalTime : Double = 0
    private var indicatorView = UIActivityIndicatorView.init(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
    //"http://devimages.apple.com/iphone/samples/bipbop/gear1/prog_index.m3u8"
    
    override func removeFromSuperview() {
        super.removeFromSuperview()
        self.playerLayer?.player?.pause()
        self.playerLayer = nil
    }
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.orange
        addToWindow()
        configControlViews()
    }
    func configControlViews() {
        self.addSubview(bottomBar)
        bottomBar.addSubview(playButton)
        bottomBar.addSubview(slider)
        slider.addTarget(self , action: #selector(sliderChanged(sender:)), for: UIControlEvents.valueChanged)
        bottomBar.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        bottomBar.frame = CGRect(x: 0, y: self.bounds.height - 40, width: self.bounds.width, height: 40)
        playButton.frame = CGRect(x: 0, y: 0,width: 40, height: 40)
        let sliderLeftRightMargin : CGFloat = 10
        slider.bounds =  CGRect(x: 0, y: 0,width: self.bounds.width - (playButton.frame.maxX + sliderLeftRightMargin * 2), height: 40)
        slider.center = CGPoint(x:self.bounds.width/2 + playButton.bounds.maxX/2 , y : bottomBar.bounds.height/2)
        playButton.setTitle("播放", for: UIControlState.normal)
        playButton.setTitle("暂停", for: UIControlState.selected)
        playButton.addTarget(self , action: #selector(playButtonAction(sender:)), for: UIControlEvents.touchUpInside)
        print("size : \(playerLayer?.player?.currentItem?.presentationSize)")
        self.addSubview(indicatorView)
        indicatorView.hidesWhenStopped = true
        indicatorView.center = self.center
        indicatorView.activityIndicatorViewStyle = .white
    }
    @objc func sliderChanged(sender:UISlider){
        print(sender.value)
        let seconds = sender.value
//        CMTimeMakeWithSeconds
        let targetTime =  CMTimeMakeWithSeconds(Float64(seconds), self.playerLayer?.player?.currentItem?.currentTime().timescale ?? Int32(0));
        self.playerLayer?.player?.seek(to: targetTime, completionHandler: { (bool ) in
            
        })
//        if let duration = self.playerLayer?.player?.currentItem?.duration {
//            let seconds = duration.seconds
//            self.slider.maximumValue = Float(seconds)
//            let targeTime = sender.value/sender.maximumValue * Float(seconds)
//            let currentTime = CMTime.init(seconds: Double(targeTime), preferredTimescale: CMTimeScale.init(0))
////            self.playerLayer?.player?.currentItem?.seek(to: currentTime, completionHandler: { (bool) in
//////
////            })
//            self.playerLayer?.player?.seek(to: currentTime, completionHandler: { (bool ) in
//
//            })
//        }
    }
    @objc func playButtonAction(sender:UIButton)  {
        print("size : \(playerLayer?.player?.currentItem?.presentationSize)")
        sender.isSelected = !sender.isSelected
        if sender.isSelected{
            self.playerLayer?.player?.play()
        }else{
            self.playerLayer?.player?.pause()
        }

    }
    func addToWindow()  {
        if let window = UIApplication.shared.delegate?.window as? UIWindow {
            window.addSubview(self)
        }
    }
    func addToSuperView()  {
        if let ddsuperView = ddSuperView{
            self.removeFromSuperview()
            ddsuperView.addSubview(self )
        }
    }
    convenience init(frame:CGRect  , superView:UIView? = nil,urlStr : String ){
        self.init(frame: frame)
        ddSuperView = superView
        self.addToSuperView()
        if let url = URL(string: urlStr){
            let playItem = AVPlayerItem.init(url: url)
            let player = AVPlayer.init(playerItem: playItem)
            playerLayer = AVPlayerLayer.init(player: player)
            self.addPlayerObserver()
            self.configPlayer()
            
//            player.play()
        }
    }
    
    func addPlayerObserver()  {
//        playerLayer?.player?.timeControlStatus
//        AVPlayerTimeControlStatus
        playerLayer?.player?.currentItem?.addObserver(self , forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil )
//        playerLayer?.player?.addObserver(self , forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil )
        playerLayer?.player?.addObserver(self , forKeyPath: "timeControlStatus", options: NSKeyValueObservingOptions.new, context: nil )

    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath ?? "" == "status"{
            if let statusRewValue = change?[NSKeyValueChangeKey.newKey] as? Int{
                if let status  = AVPlayerItemStatus.init(rawValue: statusRewValue){
                    switch status{
                    case .failed:
                        print("失败")
                        break
                    case .readyToPlay:
                        print("准备播放")
                        ///config slider
                        self.slider.minimumValue = 0.0
                        if let duration = self.playerLayer?.player?.currentItem?.duration {
                            let seconds = duration.seconds
                            currentItemTotalTime = seconds
                            self.slider.maximumValue = Float(seconds)
                            print(Float(seconds))
                        }else {
                            self.slider.maximumValue = 0.0
                        }
                        ///config control compnents
                        if let size = playerLayer?.player?.currentItem?.presentationSize , size != CGSize.zero{
                            let realH = self.bounds.width * size.height / size.width
                            self.bottomBar.frame = CGRect(x: 0, y: self.bounds.height / 2 + realH / 2 - 40, width: self.bounds.width, height: 40)
                            self.bringSubview(toFront: self.bottomBar)
                        }
                        break
                    case .unknown:
                        print("未知")
                        break
                    }
                }
            }
        }else if keyPath ?? "" == "timeControlStatus"{
            if let statusRewValue = change?[NSKeyValueChangeKey.newKey] as? Int{
                if let status  = AVPlayerTimeControlStatus.init(rawValue: statusRewValue){
                    switch status{
                    case .paused:
                        print("暂停")//更新播放按钮
                        self.playButton.isSelected = false
                        if let currentTime =  self.playerLayer?.player?.currentItem?.currentTime() {
                            if Int(currentItemTotalTime) == Int(currentTime.seconds) && currentItemTotalTime != 0{//播放完毕
                                ///重置界面到初始状态
                                self.slider.value = 0.0
                                
                                self.playerLayer?.player?.currentItem?.seek(to: kCMTimeZero, completionHandler: nil )
                                currentItemTotalTime = 0
                            }else{//暂停
                                
                            }
                        }
                    case .playing:
                        print("播放中")//取消转圈并播放,更新播放按钮
                        self.playButton.isSelected = true
                        indicatorView.stopAnimating()
                        break
                    case .waitingToPlayAtSpecifiedRate:
                        print("等待 到特定的比率去播放")//
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                            if let tempStatus = self.playerLayer?.player?.timeControlStatus , tempStatus == .waitingToPlayAtSpecifiedRate{//执行转圈, 更新播放按钮
                                self.indicatorView.startAnimating()
                                self.bringSubview(toFront: self.indicatorView)
                            }
                        }
                        break
                    }
                }
            }
        }
        else{super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)}
        
    }
    
    
    
    func configPlayer() {
        if let playLayer = playerLayer{
            self.layer.addSublayer(playLayer)
            playLayer.frame = self.bounds
            playLayer.videoGravity = AVLayerVideoGravity.resizeAspect
            playLayer.contentsScale = UIScreen.main.scale
            self.addPeriodicTimeObserver()
            self.addBoundaryTimeObserver()
        }
    }
    

    func addPeriodicTimeObserver() {
        // Invoke callback every half second
        let interval = CMTime(seconds: 0.5,
                              preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        // Queue on which to invoke the callback
        let mainQueue = DispatchQueue.main
        // Add time observer
        let timeObserverToken =
            playerLayer?.player?.addPeriodicTimeObserver(forInterval: interval, queue: mainQueue) {
                [weak self] time in
                // update player transport UI
                print("\(#line)")
                
                self?.slider.value = Float((self?.playerLayer?.player?.currentItem?.currentTime() ?? kCMTimeZero).seconds)
                
        }
    }
    func addBoundaryTimeObserver() {
        
        let assetDuration = self.playerLayer?.player?.currentItem?.duration ?? kCMTimeZero
        var times = [NSValue]()
        // Set initial time to zero
        var currentTime = kCMTimeZero
        // Divide the asset's duration into quarters.
        let interval = CMTimeMultiplyByFloat64(assetDuration, 0.25)
        
        // Build boundary times at 25%, 50%, 75%, 100%
        while currentTime < assetDuration {
            currentTime = currentTime + interval
            times.append(NSValue(time:currentTime))
        }
        // Queue on which to invoke the callback
        let mainQueue = DispatchQueue.main
        // Add time observer
        let timeObserverToken =
            playerLayer?.player?.addBoundaryTimeObserver(forTimes: times, queue: mainQueue) {
                [weak self]  in
                // Update UI
                print("\(#line)")
        }

    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
