//
//  VideoPickup.swift
//  Interview Exercise Video
//
//  Created by Shubham Kamdi on 4/27/22.
//

import Foundation
import UIKit

class VideoPickup: NSObject {
    let imagePickerController = UIImagePickerController()
    private var isVideo: Bool = false
    var listener: CommDelegate?
    override init() {
        print("Video Class Init")
    }
    
    func isVideo(_ isVideo: Bool) {
        self.isVideo = isVideo
    }
    
    //Pick Up Video Files
    private func pickUpVideo() {
        imagePickerController.delegate = self
        imagePickerController.mediaTypes = ["public.movie"]
        if let listener = listener {
            listener.startThePicker(picker: imagePickerController)
        }
    }
    
    //Pick up Images
    private func pickUpPicture() {
        imagePickerController.delegate = self
        imagePickerController.mediaTypes = ["public.image"]
        if let listener = listener {
            listener.startThePicker(picker: imagePickerController)
        }
    }
    
    //Set Source
    func setSourceOfPicker(source : VideoSource) {
        switch source {
        case .Camera:
            imagePickerController.sourceType = .camera
            if isVideo {
                self.pickUpVideo()
            } else {
                self.pickUpPicture()
            }
            break
                
        case .PhotoLibrary:
            imagePickerController.sourceType = .photoLibrary
            if isVideo {
                self.pickUpVideo()
            } else {
                self.pickUpPicture()
            }
            break
        }
    }
    
    //Setting the protocol delegate
    func subscribe(_ listener: CommDelegate?) {
        if let listener = listener {
            self.listener = listener
        }
    }
    
    //Removing the Delegate 
    func unSubscribe() {
        if let _ = listener {
            self.listener = nil
        }
    }
}

extension VideoPickup: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(  didFinishPickingMediaWithInfo info:NSDictionary!) {
        let url = info[UIImagePickerController.InfoKey.mediaURL] as! NSURL?
        listener?.dismissThePicker(picker: imagePickerController)
        if isVideo {
            listener?.didPickupAVideo(url)
        } else {
            listener?.didPickUpAImages(url)
        }
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if isVideo {
            let url = info[UIImagePickerController.InfoKey.mediaURL] as! NSURL?
            listener?.didPickupAVideo(url)
        } else {
            let url = info[UIImagePickerController.InfoKey.imageURL] as! NSURL?
            listener?.didPickUpAImages(url)
        }
        listener?.dismissThePicker(picker: imagePickerController)
    }
}

//Communication Delegate
protocol CommDelegate {
    //Communication method for video
    func didPickupAVideo(_ url: NSURL?)
    //Communication method for Images
    func didPickUpAImages(_ url: NSURL?)
    //Start the picker
    func startThePicker(picker: UIImagePickerController?)
    //Dismiss the picker
    func dismissThePicker(picker: UIImagePickerController?)
}

//Enumeration for determining the source of the file
enum VideoSource {
    case Camera
    case PhotoLibrary
}
