//
//  VideoEditor.swift
//  Interview Exercise Video
//
//  Created by Shubham Kamdi on 4/27/22.
//

import Foundation
import AVFoundation
import UIKit
class VideoEditor {
    
    private var listener: CommVideoDelegate?
    init() {
        print("Editor Init")
    }
    
    func subscribe(_ listener: CommVideoDelegate?) {
        if let listener = listener {
            self.listener = listener
        }
    }
    
    //Turn video to gray or black and white
    func toGray(_ url: URL) {
        let filter = CIFilter(name: "CIPhotoEffectNoir")!
        let asset = AVAsset(url: url)
        let composition = AVVideoComposition(asset: asset, applyingCIFiltersWithHandler: {
            request in
            let source = request.sourceImage.clampedToExtent()
            filter.setValue(source, forKey: "inputImage")
            let output = filter.outputImage
            request.finish(with: output!, context: nil)
        })
        listener?.didConvertVideoToBlackAndWhite(composition,asset)
    }
    
    //rotate video
    func rotateVideo(_ url: URL) {

    }
    
}

//Communication Delegate
protocol CommVideoDelegate {
    func didConvertVideoToBlackAndWhite(_ output: AVVideoComposition,_ asset: AVAsset)
    func didRotateVideo(_ asset: AVAsset)
}
