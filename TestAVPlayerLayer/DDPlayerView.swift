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
    private let bottomBar = DDPlayerControlBar()
    private var ddSuperView : UIView?
    private var frameInDDSuperView : CGRect?
    private var currentItemTotalTime : Double = 0
    private var indicatorView = UIActivityIndicatorView.init(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
    private var tapCount : Int = 0
    private var isBuffering : Bool = false
    var currentUrl : String?
    
    private var needRemoveObserver : Bool = false
    override func removeFromSuperview() {
        super.removeFromSuperview()
        self.playerLayer?.player?.pause()
        self.playerLayer = nil

    }
    override func layoutSubviews() {
        super.layoutSubviews()
        self.playerLayer?.frame = self.bounds
        bottomBar.frame = CGRect(x: 0, y: self.bounds.height - 40, width: self.bounds.width, height: 40)
        indicatorView.center = CGPoint(x: self.bounds.width/2, y: self.bounds.height/2)
        if let size = playerLayer?.player?.currentItem?.presentationSize , size != CGSize.zero{
            var realH = self.bounds.width * size.height / size.width
            if realH > self.bounds.height {//以宽为标准
                realH = self.bounds.height
            }
            self.bottomBar.frame = CGRect(x: 0, y: self.bounds.height / 2 + realH / 2 - 40, width: self.bounds.width, height: 40)
            self.bringSubview(toFront: self.bottomBar)
        }
        self.superview?.bringSubview(toFront: self)
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.black
        self.bottomBar.delegate = self
        addToWindow()
        _addsubViews()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5) {
            if !self.bottomBar.isHidden {
                UIView.animate(withDuration: 1, animations: {
                        self.bottomBar.isHidden = true
                })
            }
        }
    }
    func _addsubViews()  {
        self.addSubview(bottomBar)
        bottomBar.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        self.addSubview(indicatorView)
        indicatorView.hidesWhenStopped = true
        indicatorView.activityIndicatorViewStyle = .white
        self.bottomBar.isHidden = true
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
    deinit {
        removePlayerObserver()
    }

    convenience init(frame:CGRect  , superView:UIView? = nil,urlStr : String ){
        self.init(frame: frame)
        currentUrl = urlStr
        ddSuperView = superView
        frameInDDSuperView = frame
        self.addToSuperView()
        if let url = URL(string: urlStr){
            let playItem = AVPlayerItem.init(url: url)
            let player = AVPlayer.init(playerItem: playItem)
            playerLayer = AVPlayerLayer.init(player: player)
            self.addPlayerObserver()
            self.configPlayer()
        }
    }
    ///the only way to set movie url
    func replaceCurrentMovieItemWith(urlStr:String) {
        if let url = URL(string: urlStr){
            currentUrl = urlStr
            if needRemoveObserver{
                self.removePlayerObserver()
            }
            let item = AVPlayerItem.init(url: url)
            
            self.playerLayer?.player?.replaceCurrentItem(with: item)
            self.playerLayer?.player?.pause()
            self.bottomBar.configUIWhenPlayEnd()
            self.playerLayer?.player?.currentItem?.seek(to: kCMTimeZero, completionHandler: nil )
            self.addPlayerObserver()
            currentItemTotalTime = 0
            
        }
    }
    func removePlayerObserver() {//在更新item的地方移除通知再添加
        
        playerLayer?.player?.currentItem?.removeObserver(self , forKeyPath: "status")
        if #available(iOS 10.0, *) {
            playerLayer?.player?.removeObserver(self , forKeyPath: "timeControlStatus")
        }else{
            playerLayer?.player?.removeObserver(self , forKeyPath: "rate")
            playerLayer?.player?.currentItem?.removeObserver(self , forKeyPath: "playbackBufferEmpty")
            playerLayer?.player?.currentItem?.removeObserver(self , forKeyPath: "playbackLikelyToKeepUp")
        }
    }
    
    func addPlayerObserver()  {
        needRemoveObserver = true
        playerLayer?.player?.currentItem?.addObserver(self , forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil )
        //        playerLayer?.player?.addObserver(self , forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil )
        
        if #available(iOS 10.0, *) {
            playerLayer?.player?.addObserver(self , forKeyPath: "timeControlStatus", options: NSKeyValueObservingOptions.new, context: nil )
        }else{
            
            playerLayer?.player?.addObserver(self , forKeyPath: "rate", options: NSKeyValueObservingOptions.new, context: nil )
            
            playerLayer?.player?.currentItem?.addObserver(self , forKeyPath: "playbackBufferEmpty", options: NSKeyValueObservingOptions.new, context: nil )//缓冲中
            playerLayer?.player?.currentItem?.addObserver(self , forKeyPath: "playbackLikelyToKeepUp", options: NSKeyValueObservingOptions.new, context: nil )//缓冲完毕
            
        }
        
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
                        isBuffering = false
                        indicatorView.stopAnimating()
                        self.bottomBar.isHidden = false
                        if let duration = self.playerLayer?.player?.currentItem?.duration {
                            let seconds = duration.seconds
                            currentItemTotalTime = seconds
                            bottomBar.configSlider(minimumValue: 0.0, maximumValue: Float(seconds))
                        }else {
                            bottomBar.configSlider(minimumValue: 0.0, maximumValue: 0.0)
                        }
                        let value = Float((self.playerLayer?.player?.currentItem?.currentTime() ?? kCMTimeZero).seconds)
                        self.bottomBar.configSliderValue(value:value)
                        self.bringSubview(toFront: bottomBar)
                        layoutIfNeeded()
                        setNeedsLayout()
                        break
                    case .unknown:
                        print("未知")
                        break
                    }
                }
            }
        }else if keyPath ?? "" == "timeControlStatus"{
            if let statusRewValue = change?[NSKeyValueChangeKey.newKey] as? Int{
                configControlBar(statusRewValue:statusRewValue)
            }
        }else if keyPath ?? "" == "rate"{
            print("--->\(#line) ::: \(self.playerLayer?.player?.rate)")
            if self.playerLayer?.player?.rate ?? 0 == 0.0 {//暂停
                if let currentTime =  self.playerLayer?.player?.currentItem?.currentTime() {
                    if Int(currentItemTotalTime) == Int(currentTime.seconds) && currentItemTotalTime != 0{//播放完毕
                        ///重置界面到初始状态
                        self.bottomBar.configUIWhenPlayEnd()
                        self.playerLayer?.player?.currentItem?.seek(to: kCMTimeZero, completionHandler: nil )
                        currentItemTotalTime = 0
                    }else{//暂停
                        self.bottomBar.configUIWhenPause()
                    }
                }
            }else if self.playerLayer?.player?.rate ?? 0 == 1.0 {//播放
                self.bottomBar.configUIWhenPlaying()
                indicatorView.stopAnimating()
            }
        }else if keyPath ?? "" == "playbackBufferEmpty"{
            print("--->\(#line) ::: stop ?")
            isBuffering = true
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                    if self.isBuffering{//执行转圈, 更新播放按钮
                        self.indicatorView.startAnimating()
                        self.bringSubview(toFront: self.indicatorView)
                    }
            }
        }else if keyPath ?? "" == "playbackLikelyToKeepUp"{
            print("--->\(#line) ::: continue ?")
            isBuffering = false
            self.indicatorView.stopAnimating()
            
        } else{super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)}
        
    }
    
    func configControlBar(statusRewValue:Int?){//AVPlayerTimeControlStatus不兼容ios9
        if #available(iOS 10.0, *) {
            if let status  = AVPlayerTimeControlStatus.init(rawValue: statusRewValue ?? 0){
                switch status{
                case .paused:
                    print("暂停")//更新播放按钮
                    if let currentTime =  self.playerLayer?.player?.currentItem?.currentTime() {
                        if Int(currentItemTotalTime) == Int(currentTime.seconds) && currentItemTotalTime != 0{//播放完毕
                            ///重置界面到初始状态
                            self.bottomBar.configUIWhenPlayEnd()
                            self.playerLayer?.player?.currentItem?.seek(to: kCMTimeZero, completionHandler: nil )
                            currentItemTotalTime = 0
                        }else{//暂停
                            self.bottomBar.configUIWhenPause()
                        }
                    }
                case .playing:
                    print("播放中")//取消转圈并播放,更新播放按钮
                    self.bottomBar.configUIWhenPlaying()
                    indicatorView.stopAnimating()
                    break
                case .waitingToPlayAtSpecifiedRate:
                    print("等待 到特定的比率去播放")//
                    self.bottomBar.configUIWhenPause()
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                        if #available(iOS 10.0, *) {
                            if let tempStatus = self.playerLayer?.player?.timeControlStatus , tempStatus == .waitingToPlayAtSpecifiedRate{//执行转圈, 更新播放按钮
                                self.indicatorView.startAnimating()
                                self.bringSubview(toFront: self.indicatorView)
                            }
                        } else {
                            // Fallback on earlier versions
                        }
                    }
                    break
                }
            }
        }else{
            
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        print("touches")
        self.bottomBar.perfomrTap()
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
        let interval = CMTime(seconds: 1,
                              preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        // Queue on which to invoke the callback
        let mainQueue = DispatchQueue.main
        // Add time observer
        let timeObserverToken =
            playerLayer?.player?.addPeriodicTimeObserver(forInterval: interval, queue: mainQueue) {
                [weak self] time in
                // update player transport UI
                print("\(#line)")
                if let isAnimating = self?.indicatorView.isAnimating , isAnimating  {self?.indicatorView.stopAnimating()}
                let value = Float((self?.playerLayer?.player?.currentItem?.currentTime() ?? kCMTimeZero).seconds)
                self?.bottomBar.configSliderValue(value:value)
                
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
}

extension DDPlayerView : DDPlayerControlDelegate{
    func screenChanged(isFullScreen: Bool) {
        if isFullScreen {
            if let window = UIApplication.shared.keyWindow{
                window.addSubview(self)
                UIView.animate(withDuration: 0.25) {
                    self.bounds = CGRect(x: 0, y: 0, width: window.bounds.height, height: window.bounds.width)
                    self.center = CGPoint(x: window.bounds.width/2, y: window.bounds.height/2)
                    
                    self.transform = CGAffineTransform.init(rotationAngle: CGFloat(Double.pi/2))
                }
                self.playerLayer?.frame = self.bounds
//                self.configControlViews()
                
            }
        }else{
            if let _superView = ddSuperView{
                _superView.addSubview(self)
                UIView.animate(withDuration: 0.25) {
                    self.transform = CGAffineTransform.identity
                    self.frame = self.frameInDDSuperView ?? CGRect.zero
                    self.playerLayer?.frame = self.bounds
                    
                }
//                self.configControlViews()
                
            }
        }
    }
    
    func sliderChanged(sender: DDSlider) {
        let seconds = sender.value
        //        CMTimeMakeWithSeconds
        let targetTime =  CMTimeMakeWithSeconds(Float64(seconds), self.playerLayer?.player?.currentItem?.currentTime().timescale ?? Int32(0));
        self.playerLayer?.player?.seek(to: targetTime, completionHandler: { (bool ) in
            
        })
    }
    
    func pressToPlay() {
        self.playerLayer?.player?.play()
    }
    
    func pressToPause() {
        self.playerLayer?.player?.pause()
    }
    
    
}



/*
 
 
 class DDPlayerView: UIView {
 var playerLayer : AVPlayerLayer?
 private let bottomBar = UIView()
 private let playButton = UIButton()
 private var ddSuperView : UIView?
 private var frameInDDSuperView : CGRect?
 private let slider = DDSlider()
 private var currentItemTotalTime : Double = 0
 private var indicatorView = UIActivityIndicatorView.init(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
 private let fullScreenButton = UIButton()
 private var tapCount : Int = 0
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
 self.backgroundColor = UIColor.black
 addToWindow()
 _addsubViews()
 DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5) {
 if !self.bottomBar.isHidden {
 UIView.animate(withDuration: 1, animations: {
 self.bottomBar.isHidden = true
 })
 }
 }
 }
 func _addsubViews()  {
 
 self.addSubview(bottomBar)
 bottomBar.addSubview(playButton)
 bottomBar.addSubview(slider)
 bottomBar.addSubview(fullScreenButton)
 slider.addTarget(self , action: #selector(sliderChanged(sender:)), for: UIControlEvents.valueChanged)
 fullScreenButton.setTitle("全屏", for: UIControlState.normal)
 fullScreenButton.setTitle("小屏", for: UIControlState.selected)
 playButton.setTitle("播放", for: UIControlState.normal)
 playButton.setTitle("暂停", for: UIControlState.selected)
 playButton.addTarget(self , action: #selector(playButtonAction(sender:)), for: UIControlEvents.touchUpInside)
 bottomBar.backgroundColor = UIColor.white.withAlphaComponent(0.3)
 fullScreenButton.addTarget(self , action: #selector(fullScreenButtonAction(sender:)), for: UIControlEvents.touchUpInside)
 self.addSubview(indicatorView)
 indicatorView.hidesWhenStopped = true
 indicatorView.activityIndicatorViewStyle = .white
 configControlViews()
 }
 func configControlViews() {
 bottomBar.frame = CGRect(x: 0, y: self.bounds.height - 40, width: self.bounds.width, height: 40)
 playButton.frame = CGRect(x: 0, y: 0,width: 40, height: 40)
 fullScreenButton.frame = CGRect(x: bottomBar.bounds.width - 44, y: 0,width: 40, height: 40)
 let sliderLeftRightMargin : CGFloat = 10
 slider.bounds =  CGRect(x: 0, y: 0,width: self.bounds.width - (fullScreenButton.frame.width + playButton.frame.maxX + sliderLeftRightMargin * 2), height: 40)
 slider.center = CGPoint(x:self.bounds.width/2  , y : bottomBar.bounds.height/2)
 print("size : \(playerLayer?.player?.currentItem?.presentationSize)")
 indicatorView.center = self.center
 
 if let size = playerLayer?.player?.currentItem?.presentationSize , size != CGSize.zero{
 var realH = self.bounds.width * size.height / size.width
 if realH > self.bounds.height {//以宽为标准
 realH = self.bounds.height
 }
 self.bottomBar.frame = CGRect(x: 0, y: self.bounds.height / 2 + realH / 2 - 40, width: self.bounds.width, height: 40)
 self.bringSubview(toFront: self.bottomBar)
 }
 self.superview?.bringSubview(toFront: self)
 print("/////////////")
 print(self.frame)
 print(self.bottomBar.frame)
 
 self.layoutIfNeeded()
 self.setNeedsLayout()
 }
 @objc func fullScreenButtonAction(sender:UIButton){
 sender.isSelected = !sender.isSelected
 if sender.isSelected{//全屏
 if let window = UIApplication.shared.keyWindow{
 window.addSubview(self)
 UIView.animate(withDuration: 0.25) {
 self.bounds = CGRect(x: 0, y: 0, width: window.bounds.height, height: window.bounds.width)
 self.center = CGPoint(x: window.bounds.width/2, y: window.bounds.height/2)
 
 self.transform = CGAffineTransform.init(rotationAngle: CGFloat(Double.pi/2))
 }
 self.playerLayer?.frame = self.bounds
 self.configControlViews()
 
 }
 }else{//小屏
 if let _superView = ddSuperView{
 _superView.addSubview(self)
 UIView.animate(withDuration: 0.25) {
 self.transform = CGAffineTransform.identity
 self.frame = self.frameInDDSuperView ?? CGRect.zero
 self.playerLayer?.frame = self.bounds
 
 }
 self.configControlViews()
 
 }
 }
 }
 @objc func sliderChanged(sender:UISlider){
 print(sender.value)
 let seconds = sender.value
 //        CMTimeMakeWithSeconds
 let targetTime =  CMTimeMakeWithSeconds(Float64(seconds), self.playerLayer?.player?.currentItem?.currentTime().timescale ?? Int32(0));
 self.playerLayer?.player?.seek(to: targetTime, completionHandler: { (bool ) in
 
 })
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
 frameInDDSuperView = frame
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
 var realH = self.bounds.width * size.height / size.width
 if realH > self.bounds.height {realH = self.bounds.height}
 self.bottomBar.frame = CGRect(x: 0, y: self.bounds.height / 2 + realH / 2 - 40, width: self.bounds.width, height: 40)
 self.bringSubview(toFront: self.bottomBar)
 }
 self.configControlViews()
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
 override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
 super.touchesBegan(touches, with: event)
 print("touches")
 if self.bottomBar.isHidden{
 tapCount += 1
 }
 showBottomBar(self.bottomBar.isHidden)
 }
 func showBottomBar(_ isShow : Bool) {
 if isShow{
 UIView.animate(withDuration: 1, animations: {
 self.bottomBar.isHidden = false
 })
 DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5) {
 if !self.bottomBar.isHidden {
 self.tapCount -= 1
 if self.tapCount == 0{
 UIView.animate(withDuration: 1, animations: {
 self.bottomBar.isHidden = true
 })
 }
 
 }
 }
 }else{
 UIView.animate(withDuration: 1, animations: {
 self.bottomBar.isHidden = true
 })
 }
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

 
 
 */
