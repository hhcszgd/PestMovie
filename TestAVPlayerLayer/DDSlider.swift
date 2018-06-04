//
//  DDSlider.swift
//  TestAVPlayerLayer
//
//  Created by WY on 2018/6/4.
//  Copyright © 2018年 HHCSZGD. All rights reserved.
//

import UIKit

class DDSlider: UISlider {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setThumbImage(UIImage(named:"playdragging"), for: UIControlState.normal)
        self.setThumbImage(UIImage(named:"playdragging"), for: UIControlState.highlighted)
        self.minimumTrackTintColor = UIColor.orange
        self.maximumTrackTintColor = UIColor.gray
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
//    open func minimumValueImageRect(forBounds bounds: CGRect) -> CGRect
    
//    open func maximumValueImageRect(forBounds bounds: CGRect) -> CGRect
    
    override func trackRect(forBounds bounds: CGRect) -> CGRect{
        let rect = super.trackRect(forBounds: bounds)
        return CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.size.width, height: 6)
    }
    
//    override func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect{
//        let tempTrackRect = self.trackRect(forBounds: bounds)
//        let tempBounds = CGRect(x: 0, y: 0, width: 1, height: 1)
//        return super.thumbRect(forBounds: tempBounds, trackRect: tempTrackRect, value: value)
////            return CGRect(x: 0, y: 0, width: 10, height: 10)
//    }
}
