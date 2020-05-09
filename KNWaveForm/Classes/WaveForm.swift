//
//  WaveForm.swift
//  KNWaveForm
//
//  Created by Kayvan on 5/4/20.
//  Copyright © 2020 Kayvan. All rights reserved.
//

import UIKit
import AVFoundation

public enum WaveformPosition: Int {
    case top    = -1
    case middle =  0
    case bottom =  1
}


public enum WaveformStyle {
    case filled
    case striped(period:Int)
}


protocol WaveFormProtocol {
    func didFinishRendering()
    func renderingFailed()
}

public class WaveForm: UIView {
    
    private var config: WaveformConfiguration?
    private var delegate: WaveFormProtocol?
    
    lazy var waveformImageView: UIImageView = {
        let imageview = UIImageView(frame: CGRect.zero)
        imageview.contentMode = .scaleToFill
        imageview.tintColor = self.config?.color
        return imageview
    }()
    
    lazy var progressWaveformImageView: UIImageView = {
        let imageview = UIImageView(frame: CGRect.zero)
        imageview.contentMode = .scaleToFill
        imageview.tintColor = self.config?.progressColor
        return imageview
    }()
    
    /// A view which hides part of the highlighted image
    fileprivate let clipping: UIView = {
        let view = UIView(frame: CGRect.zero)
        view.clipsToBounds = true
        return view
    }()
    
    //private var
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        addSubview(waveformImageView)
        clipping.addSubview(progressWaveformImageView)
        addSubview(clipping)
        clipsToBounds = true
    }
    
    
    public func render(for asset: AVAsset, configuration: WaveformConfiguration, and identifier: String? = nil) {
        let audioTracks:[AVAssetTrack] = asset.tracks(withMediaType: AVMediaType.audio)

        if let track:AVAssetTrack = audioTracks.first {
            let timeRange:CMTimeRange? = nil
            
            let samplingStartTime = CFAbsoluteTimeGetCurrent()
            
            SamplesExtractor.samples(audioTrack: track, timeRange: timeRange, desiredNumberOfSamples: configuration.numberofSamples, onSuccess: { (samples, sampleMax, identifier) in
                
                let sampling = (samples: samples, sampleMax: sampleMax)
                let samplingDuration = CFAbsoluteTimeGetCurrent() - samplingStartTime
                
                let drawingStartTime = CFAbsoluteTimeGetCurrent()
                self.waveformImageView.frame.size = self.frame.size
                self.progressWaveformImageView.frame.size = self.frame.size
                self.clipping.frame.size = CGSize(width: CGFloat(0.0), height: self.frame.size.height)
                
                self.waveformImageView.image = WaveFormDrawer.image(with: sampling, and: configuration, isHighlight: false)
                self.progressWaveformImageView.image = WaveFormDrawer.image(with: sampling, and: configuration, isHighlight: true)
                let drawingDuration = CFAbsoluteTimeGetCurrent() - drawingStartTime
                
                print("\(configuration.numberofSamples)/\(sampling.samples.count)")
                print("Sampled in \(String(format:"%.3f s",samplingDuration))")
                print("Drawed in \(String(format:"%.3f s",drawingDuration))")
                
            }, onFailure: { (error, identifier) in
                
            }, identifiedBy: identifier)
        }
    }
    
    
    public func renderARandomSample(configuration: WaveformConfiguration) {
        let sampleMax: Float = 1.0
        var samples = [Float]()
        for _ in 0...configuration.numberofSamples {
            samples.append(Float.random(in: 0...1))
        }
        let sampling = (samples: samples, sampleMax: sampleMax)
        self.waveformImageView.frame.size = self.frame.size
        self.progressWaveformImageView.frame.size = self.frame.size
        self.clipping.frame.size = CGSize(width: CGFloat(0.0), height: self.frame.size.height)
        self.waveformImageView.image = WaveFormDrawer.image(with: sampling, and: configuration, isHighlight: false)
        self.progressWaveformImageView.image = WaveFormDrawer.image(with: sampling, and: configuration, isHighlight: true)
    }
    
    public func progress(to percentage: CGFloat) {
        let x: CGFloat = 0.0
        let y: CGFloat = 0.0
        let height = self.bounds.size.height
        let width = self.bounds.size.width * percentage
        UIView.animate(withDuration: 0.5) {
            self.clipping.frame = CGRect(x: x, y: y, width: width, height: height)
        }
    }
}



// MARK : - WaveformConfiguration

/// Allows customization of the waveform output image.
public struct WaveformConfiguration {
    let size: CGSize
    let color: UIColor
    let progressColor: UIColor
    let backgroundColor: UIColor
    let position: WaveformPosition
    let style: WaveformStyle
    let scale: CGFloat
    let borderWidth: CGFloat
    let borderColor: UIColor
    let paddingFactor: CGFloat?
    let numberofSamples: Int
    
    public var drawCentraLine: Bool = false
    public var centralLineWidth: CGFloat = 2 // The width of the central line
    public var centralLineColor: UIColor = UIColor.red // Its color

    public init(size: CGSize,
                color: UIColor = UIColor.gray,
                progressColor: UIColor = UIColor.red,
                backgroundColor: UIColor = UIColor.clear,
                position: WaveformPosition = .middle,
                style: WaveformStyle = .filled,
                scale: CGFloat = UIScreen.main.scale,
                borderWidth:CGFloat = 0,
                borderColor:UIColor = UIColor.white,
                paddingFactor: CGFloat? = nil
        ) {
        self.size = size
        self.color = color
        self.progressColor = progressColor
        self.backgroundColor = backgroundColor
        self.position = position
        self.scale = scale
        self.style = style
        self.borderWidth = borderWidth
        self.borderColor = borderColor
        self.paddingFactor = paddingFactor
        self.numberofSamples = Int(size.width)
    }
}

// MARK : - WaveFormDrawer
open class WaveFormDrawer {
    
    public static func image(with sampling:(samples: [Float], sampleMax: Float), and configuration: WaveformConfiguration, isHighlight: Bool = false) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(configuration.size, false, configuration.scale)
        if let context = UIGraphicsGetCurrentContext(){
            context.setAllowsAntialiasing(true)
            context.setShouldAntialias(true)
            self._drawBackground(on: context, with: configuration)
            context.saveGState()
            self._drawGraph(from: sampling, on: context, with: configuration, isHighlight: isHighlight)
            context.restoreGState()
            if configuration.borderWidth > 0 {
                self._drawBorder(on: context, with: configuration)
            }
            self._drawTheCentralLine(on: context, with: configuration)
            let graphImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return graphImage
        }
        return nil
    }

    private static func _drawBackground(on context: CGContext, with configuration: WaveformConfiguration) {
        context.setFillColor(configuration.backgroundColor.cgColor)
        context.fill(CGRect(origin: CGPoint.zero, size: configuration.size))
    }

    private static func _drawBorder(on context: CGContext, with configuration: WaveformConfiguration) {
        let path = CGMutablePath()
        let radius:CGFloat = 0
        let rect = CGRect(origin: CGPoint.zero, size: configuration.size)
        context.setStrokeColor(configuration.borderColor.cgColor)
        context.setLineWidth(configuration.borderWidth)
        path.move(to:CGPoint(x:  rect.minX, y:  rect.maxY))
        path.addArc(tangent1End: CGPoint(x:  rect.minX, y:  rect.minY), tangent2End: CGPoint(x:  rect.midX, y:  rect.minY), radius: radius)
        path.addArc(tangent1End: CGPoint(x:  rect.maxX, y:  rect.minY), tangent2End: CGPoint(x:  rect.maxX, y:  rect.midY), radius: radius)
        path.addArc(tangent1End: CGPoint(x:  rect.maxX, y:  rect.maxY), tangent2End: CGPoint(x:  rect.midX, y:  rect.maxY), radius: radius)
        path.addArc(tangent1End: CGPoint(x:  rect.minX, y:  rect.maxY), tangent2End: CGPoint(x:  rect.minX, y:  rect.midY), radius: radius)
        context.addPath(path)
        context.drawPath(using: CGPathDrawingMode.stroke)
    }


    private static func _drawTheCentralLine(on context: CGContext, with configuration: WaveformConfiguration){
        guard configuration.drawCentraLine else { return }
        let path = CGMutablePath()
        let startingPoint = CGPoint(x: (CGFloat(context.width) / 2) - configuration.centralLineWidth, y: 0)
        let endPoint =  CGPoint(x: startingPoint.x , y: CGFloat(context.height))
        context.setStrokeColor(configuration.centralLineColor.cgColor)
        context.setLineWidth(configuration.centralLineWidth)
        path.move(to: startingPoint)
        path.addLine(to: endPoint)
        context.addPath(path)
        context.drawPath(using: CGPathDrawingMode.stroke)
    }

    private static func _drawGraph(from sampling:(samples: [Float], sampleMax: Float),
                                   on context: CGContext,
                                   with configuration: WaveformConfiguration, isHighlight: Bool = false) {
        let graphRect = CGRect(origin: CGPoint.zero, size: configuration.size)
        let graphCenter = graphRect.size.height / 2.0
        let positionAdjustedGraphCenter = graphCenter + CGFloat(configuration.position.rawValue) * graphCenter
        let verticalPaddingDivisor = configuration.paddingFactor ?? CGFloat(configuration.position == .middle ? 2.5 : 1.5)
        let drawMappingFactor = graphRect.size.height / verticalPaddingDivisor
        let minimumGraphAmplitude: CGFloat = 2 // we want to see at least a 1pt line for silence

        let path = CGMutablePath()
        var maxAmplitude: CGFloat = CGFloat(sampling.sampleMax / SamplesExtractor.noiseFloor ) // we know 1 is our max in normalized data, but we keep it 'generic'
        context.setLineWidth(1.0 / configuration.scale)
        for (x, sample) in sampling.samples.enumerated() {
            let xPos = CGFloat(x) / configuration.scale
            let invertedDbSample = 1 - CGFloat(sample) // sample is in dB, linearly normalized to [0, 1] (1 -> -50 dB)
            let drawingAmplitude = max(minimumGraphAmplitude, invertedDbSample * drawMappingFactor)
            let drawingAmplitudeUp = positionAdjustedGraphCenter - drawingAmplitude
            let drawingAmplitudeDown = positionAdjustedGraphCenter + drawingAmplitude
            maxAmplitude = max(drawingAmplitude, maxAmplitude)
            switch configuration.style {
            case .striped(let period):
                if (Int(xPos) % period == 0) {
                    path.move(to: CGPoint(x: xPos, y: drawingAmplitudeUp))
                    path.addLine(to: CGPoint(x: xPos, y: drawingAmplitudeDown))
                }
            default:
                path.move(to: CGPoint(x: xPos, y: drawingAmplitudeUp))
                path.addLine(to: CGPoint(x: xPos, y: drawingAmplitudeDown))
            }
        }
        context.addPath(path)
        let color = isHighlight ? configuration.progressColor.cgColor : configuration.color.cgColor
        context.setStrokeColor(color)
        context.strokePath()
    }
}


