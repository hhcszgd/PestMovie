//
//  ViewController.swift
//  TestAVPlayerLayer
//
//  Created by WY on 2018/6/2.
//  Copyright © 2018年 HHCSZGD. All rights reserved.
//

import UIKit
import AVKit
class ViewController: UIViewController {
    var playerLayer : DDPlayerView?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let url = "http://devimages.apple.com/iphone/samples/bipbop/gear1/prog_index.m3u8"
       self.playerLayer =  DDPlayerView.init(frame: self.view.bounds, superView: self.view , urlStr: url)
    }

}

