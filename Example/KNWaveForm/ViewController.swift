//
//  ViewController.swift
//  KNWaveForm
//
//  Created by Kayvan Nouri on 05/08/2020.
//  Copyright (c) 2020 Kayvan Nouri. All rights reserved.
//

import UIKit
import AVFoundation
import KNWaveForm

class ViewController: UIViewController {
    
    @IBOutlet weak var waveform: WaveForm!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let url = Bundle.main.url(forResource: "eddy_-_01_-_Pure_Adrenaline", withExtension: "mp3")!
        let asset = AVAsset(url: url)
        let config = WaveformConfiguration(size: self.waveform.bounds.size, color: UIColor.gray, progressColor: UIColor.red, backgroundColor: UIColor.white, position: WaveformPosition.middle, style: WaveformStyle.striped(period: 3), scale: 1, borderWidth: 0, borderColor: UIColor.clear, paddingFactor: nil)
        waveform.render(for: asset, configuration: config)
    }
    
    
    @IBAction func randomProgress(_ sender: Any) {
        let random = Double.random(in: 0.0...1.0)
        self.waveform.progress(to: CGFloat(random))
    }

}

extension ViewController: WaveFormDelegate {
    func didScrollTo(percentage: CGFloat) {
        return
    }
    
    func didFinishRendering(identifier: String?) {
        return
    }
    
    func samplingFailed(error: Error, identifier: String?) {
        return
    }
    
    
}


