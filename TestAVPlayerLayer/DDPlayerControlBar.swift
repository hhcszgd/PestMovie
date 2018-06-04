//
//  DDPlayerControlBar.swift
//  TestAVPlayerLayer
//
//  Created by WY on 2018/6/4.
//  Copyright © 2018年 HHCSZGD. All rights reserved.
//

import UIKit
enum DDPlayerControlBarStyle : Int  {
    case smallScreen = 0
    case fullScreen
}
protocol DDPlayerControlDelegate : NSObjectProtocol{
    func screenChanged(isFullScreen:Bool)
    func sliderChanged(sender:DDSlider)
    func pressToPlay()
    func pressToPause()
}
class DDPlayerControlBar: UIView {
    var style : DDPlayerControlBarStyle = .smallScreen{
        didSet{
            layoutIfNeeded()
            setNeedsLayout()
        }
    }
     let playButton = UIButton()
     let slider = DDSlider()
    private var currentItemTotalTime : Double = 0
    private let fullScreenButton = UIButton()
    private var tapCount : Int = 0
    weak var delegate : DDPlayerControlDelegate?
    private var hasPlayedTimeLabel : UILabel = UILabel()
    private var leftTimeLabel : UILabel = UILabel()
    private var fullScreenTimeLabel : UILabel = UILabel()
    override init(frame: CGRect) {
        super.init(frame: frame)
        _addsubViews()
    }
    func _addsubViews()  {
        
        self.addSubview(playButton)
        self.addSubview(slider)
        self.addSubview(fullScreenButton)
        
        self.addSubview(hasPlayedTimeLabel)
        self.addSubview(leftTimeLabel)
        self.addSubview(fullScreenTimeLabel)
//        hasPlayedTimeLabel.text = "11:11"
//        leftTimeLabel.text = "12:12"
//        fullScreenTimeLabel.text = "12:12/33:33"
        hasPlayedTimeLabel.font = UIFont.systemFont(ofSize: 14)
        leftTimeLabel.font = UIFont.systemFont(ofSize: 14)
        fullScreenTimeLabel.font = UIFont.systemFont(ofSize: 14)
        
        hasPlayedTimeLabel.textColor = UIColor.white
        leftTimeLabel.textColor = UIColor.white
        fullScreenTimeLabel.textColor = UIColor.white
        
        slider.addTarget(self , action: #selector(sliderChanged(sender:)), for: UIControlEvents.valueChanged)
//        fullScreenButton.setTitle("全屏", for: UIControlState.normal)//full screen
//        fullScreenButton.setTitle("小屏", for: UIControlState.selected)//not full screen
//        playButton.setTitle("播放", for: UIControlState.normal)//play
//        playButton.setTitle("暂停", for: UIControlState.selected)//pause
        fullScreenButton.setImage(UIImage(named:"fullscreenbutton"), for: UIControlState.normal)
        fullScreenButton.setImage(UIImage(named:"shrinkscreen"), for: UIControlState.selected)
        playButton.setImage(UIImage(named:"playbutton"), for: UIControlState.normal)
        playButton.setImage(UIImage(named:"stopbutton"), for: UIControlState.selected)
        playButton.addTarget(self , action: #selector(playButtonAction(sender:)), for: UIControlEvents.touchUpInside)
        self.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        fullScreenButton.addTarget(self , action: #selector(fullScreenButtonAction(sender:)), for: UIControlEvents.touchUpInside)
    }
    @objc func sliderChanged(sender:DDSlider){
        performDelayHidden()
        self.delegate?.sliderChanged(sender: sender)
    }
    @objc func playButtonAction(sender:UIButton)  {
        performDelayHidden()
        sender.isSelected = !sender.isSelected
        if sender.isSelected{
            self.delegate?.pressToPlay()
        }else{
            self.delegate?.pressToPause()
        }
        
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        let buttonToBorder : CGFloat = 10
        let buttonY = buttonToBorder
        let buttonH = self.bounds.height - buttonToBorder * 2
        let buttonToScreen : CGFloat = 20
        switch style {
        case .smallScreen:
            playButton.frame = CGRect(x: buttonToScreen, y: buttonY,width: buttonH, height: buttonH)
            fullScreenButton.frame = CGRect(x: self.bounds.width - (buttonToScreen + buttonH), y: buttonY,width: buttonH, height: buttonH)
            
            hasPlayedTimeLabel.sizeToFit()
            leftTimeLabel.sizeToFit()
            hasPlayedTimeLabel.frame = CGRect(x: playButton.frame.maxX + buttonToBorder, y: buttonY,width: hasPlayedTimeLabel.bounds.width, height: buttonH)
            leftTimeLabel.frame = CGRect(x: fullScreenButton.frame.minX - (buttonToScreen + leftTimeLabel.bounds.width), y: buttonY,width: leftTimeLabel.bounds.width, height: buttonH)
            fullScreenTimeLabel.isHidden = true
            hasPlayedTimeLabel.isHidden = false
            leftTimeLabel.isHidden = false
            let sliderLeftRightMargin : CGFloat = 10
            let sliderH : CGFloat = 26
            slider.frame =  CGRect(x: hasPlayedTimeLabel.frame.maxX + sliderLeftRightMargin, y: self.bounds.height/2 - sliderH/2,width: leftTimeLabel.frame.minX - (hasPlayedTimeLabel.frame.maxX + sliderLeftRightMargin * 2), height: sliderH)
//            slider.center = CGPoint(x:self.bounds.width/2  , y : self.bounds.height/2)
            
        case .fullScreen:
            fullScreenTimeLabel.isHidden = false
            hasPlayedTimeLabel.isHidden = true
            leftTimeLabel.isHidden = true
            playButton.frame = CGRect(x: buttonToScreen, y: buttonY,width: buttonH, height: buttonH)
            fullScreenButton.frame = CGRect(x: self.bounds.width - (buttonToScreen + buttonH), y: buttonY,width: buttonH, height: buttonH)
           
            let sliderLeftRightMargin : CGFloat = 10
            slider.bounds =  CGRect(x: 0, y: 0,width: fullScreenButton.frame.minX - (playButton.frame.maxX + sliderLeftRightMargin * 2), height: 40)
            slider.center = CGPoint(x:self.bounds.width/2  , y : playButton.frame.minY)
            fullScreenTimeLabel.sizeToFit()
            fullScreenTimeLabel.frame = CGRect(x: slider.frame.minX, y: playButton.frame.midY, width: fullScreenTimeLabel.bounds.width, height: playButton.bounds.height/2)
            
        }
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

    func configSlider(minimumValue:Float ,maximumValue : Float){
        slider.minimumValue = minimumValue
        slider.maximumValue = maximumValue
    }
    func configSliderValue(value : Float){
        slider.value = value
        let hasPlayHours = Int(value) / 3600
        let hasPlayMinuts = (Int(value) % 3600) / 60
        let hasPlaySeconds = (Int(value) % 60)
        
        let leftPlayHours = Int(slider.maximumValue - value) / 3600
        let leftPlayMinuts = (Int(slider.maximumValue - value) % 3600) / 60
        let leftPlaySeconds = (Int(slider.maximumValue - value) % 60)
        
        let totalPlayHours = Int(slider.maximumValue ) / 3600
        let totalPlayMinuts = (Int(slider.maximumValue) % 3600) / 60
        let totalPlaySeconds = (Int(slider.maximumValue) % 60)
        
        let hasPlayStr = hasPlayHours == 0 ? "\(hasPlayMinuts):\(hasPlaySeconds)" : "\(hasPlayHours):\(hasPlayMinuts):\(hasPlaySeconds)"
        let leftStr =  leftPlayHours == 0 ? "\(leftPlayMinuts):\(leftPlaySeconds)" : "\(leftPlayHours):\(leftPlayMinuts):\(leftPlaySeconds)"
        let totalStr =  totalPlayHours == 0 ? "\(totalPlayMinuts):\(totalPlaySeconds)" : "\(totalPlayHours):\(totalPlayMinuts):\(totalPlaySeconds)"
        self.hasPlayedTimeLabel.text = hasPlayStr
        self.leftTimeLabel.text = leftStr
        self.fullScreenTimeLabel.text = "\(hasPlayStr)/\(totalStr)"
        layoutIfNeeded()
        setNeedsLayout()
    }
    @objc func fullScreenButtonAction(sender:UIButton){
        sender.isSelected = !sender.isSelected
        performDelayHidden()
        if sender.isSelected{//全屏
            self.style = .fullScreen
            self.delegate?.screenChanged(isFullScreen: true )
        }else{//小屏
            self.style = .smallScreen
            self.delegate?.screenChanged(isFullScreen: false  )
        }
    }
    func updateTime(time:TimeInterval) {
        
    }
    func configUIWhenPause() {
        self.playButton.isSelected = false
    }
    func configUIWhenPlaying() {
        self.playButton.isSelected = true
    }
    func configUIWhenPlayEnd() {
        self.playButton.isSelected = false
        self.slider.value = 0.0
    }
    func perfomrTap() {

        if self.isHidden{
            performDelayHidden()
            UIView.animate(withDuration: 1, animations: {
                self.isHidden = false
            })
        }else{
            UIView.animate(withDuration: 1, animations: {
                self.isHidden = true
            })
        }
    }
    private func performDelayHidden(){
        tapCount += 1
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5) {
            if !self.isHidden {
                self.tapCount -= 1
                if self.tapCount == 0{
                    UIView.animate(withDuration: 1, animations: {
                        self.isHidden = true
                    })
                }
                
            }
        }
    }
    
    
}
