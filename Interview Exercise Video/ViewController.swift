//
//  ViewController.swift
//  Interview Exercise Video
//
//  Created by Shubham Kamdi on 4/27/22.
//
import CoreLocation
import UIKit
import GoogleMaps
import AVFoundation

class ViewController: UIViewController, UINavigationControllerDelegate {
    var flagPickUp: Bool = false
    var locationDictionary: Dictionary<String,CLLocationCoordinate2D> = [:]
    var videoName: String = ""
    var pickerObj = VideoPickup()
    var playerContainerView: UIView!
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var videoEditor = VideoEditor()
    var videoUrl: NSURL?
    var mapView:GMSMapView?
    var locationManager = CLLocationManager()
    var imageView : UIImageView?
    @IBOutlet weak var gmsMap: GMSMapView!
    @IBOutlet weak var conatinerView: UIView!
    @IBOutlet weak var videoSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        videoSwitch.addTarget(self, action: #selector(self.switched(_:)), for: .valueChanged)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showSourceDialog()
        pickerObj.isVideo(self.videoSwitch.isOn)
        setUpGoogleMaps()
        locationManager = CLLocationManager()
        
        //Make sure to set the delegate, to get the call back when the user taps Allow option
        locationManager.delegate = self
    }
    
    //Switching logic for image or video
    @objc func switched(_ sender:UISwitch) {
        pickerObj.isVideo(self.videoSwitch.isOn)
        showSourceDialog()
    }
    
    //Converting the video to grayscale by calling the video conversion class
    @IBAction func convert() {
        guard let _ = videoUrl else { return }
        videoEditor.subscribe(self)
        videoEditor.toGray(videoUrl!.absoluteURL!)
    }
    
    @IBAction func rotateVideo() {
        rotateVideoMethod()
    }

    //Original video button logic
    @IBAction func originalVideo() {
        if let videoUrl = videoUrl {
            removePreviousPlayer()
            setUpPlayerContainerView(videoUrl)
        }
    }
}

//Conforming to Communication Delegate
extension ViewController: CommDelegate {
    //Picked up video
    func didPickupAVideo(_ url: NSURL?) {
        if let _ = url {
            removeImage()
            setUpFlag()
            self.videoUrl = url
            self.videoName = url!.relativeString
            setUpPlayerContainerView(url!)
        }
    }
    
    //Picked up image
    func didPickUpAImages(_ url: NSURL?) {
        if let _ = url {
            setUpFlag()
            self.videoName = url!.relativeString
            removePreviousPlayer()
            self.videoUrl = nil
            addImage(url!)
        }
    }
    
    //Presenting the media picker
    func startThePicker(picker: UIImagePickerController?) {
        if let picker = picker {
            DispatchQueue.main.async { [weak self] in
                self?.present(picker, animated: true, completion: nil)
            }
        }
    }
    
    //Dismissing the media Picker
    func dismissThePicker(picker: UIImagePickerController?) {
        if let picker = picker {
            DispatchQueue.main.async { [weak self] in
                picker.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    
    func setUpFlag() {
        flagPickUp = true
    }
    
    //Setting up the video player
    private func setUpPlayerContainerView(_ url: NSURL) {
        removeImage()
        removePreviousPlayer()
        guard let _ = videoUrl else { return }
        player = AVPlayer(url: url.absoluteURL!)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = self.conatinerView.bounds
        playerLayer?.videoGravity = .resizeAspect
        self.conatinerView.layer.addSublayer(playerLayer!)
        player!.play()
    }
    
    private func addImage(_ url: NSURL) {
        
        DispatchQueue.global().async { [weak self] in
            //Extracting image data from the URL
            if let data = try? Data(contentsOf: url.absoluteURL!) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        //Applying the data to UIImageView
                        let imageView = UIImageView(image: image)
                        imageView.frame = (self?.conatinerView.bounds)!
                        self?.conatinerView.addSubview(imageView)
                        self?.conatinerView.bringSubviewToFront(imageView)
                    }
                }
            }
        }
        
    }
   
}

//Location Logic
extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //Capturing the coordinate if a new video or photo is picked
        if flagPickUp {
            if let cordinate = manager.location?.coordinate {
                //using hashmaps tos store the coordinates
                locationDictionary[videoName] = manager.location?.coordinate
                setUpLocationMarker(videoName)
                flagPickUp = false
                videoName = ""
            } else {
                //Error
            }
        }
    }
    
    //Checking for location permission Update
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if CLLocationManager.locationServicesEnabled()
            {
                switch(CLLocationManager.authorizationStatus())
                {
                case .authorizedAlways, .authorizedWhenInUse:
                    print("Authorize.")
                    locationManager.desiredAccuracy = kCLLocationAccuracyBest
                    locationManager.startUpdatingLocation()
                    locationManager.startMonitoringSignificantLocationChanges()
                    break
                case .notDetermined:
                    print("Not determined.")
                    locationManager.requestWhenInUseAuthorization()
                    break
                case .restricted:
                    print("Restricted.")
                    locationManager.requestWhenInUseAuthorization()
                    break
                case .denied:
                    print("Denied.")
                    locationManager.requestWhenInUseAuthorization()
                }
            }
    }
}

extension ViewController {
    //Presenting the dialog with option to select from Camera or Photo library
    func showSourceDialog() {
        pickerObj.subscribe(self)
        let alertViewController = UIAlertController(title: "Source", message: "Please Select a Source", preferredStyle: .actionSheet)
        let cameraAlert = UIAlertAction(title: "Camera", style: .default, handler: {
            [weak pickerObj] _ in
            pickerObj?.setSourceOfPicker(source: .Camera)
        })
        let photoLibraryAlert = UIAlertAction(title: "Photo Library", style: .default, handler: {
            [weak pickerObj] _ in
            pickerObj?.setSourceOfPicker(source: .PhotoLibrary)
        })
        let cancel = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)
        alertViewController.addAction(cameraAlert)
        alertViewController.addAction(photoLibraryAlert)
        alertViewController.addAction(cancel)
        alertViewController.popoverPresentationController?.sourceView = self.view
        self.present(alertViewController, animated: true, completion: nil)
    }
}

extension ViewController: CommVideoDelegate {
    
    
    func didRotateVideo(_ asset: AVAsset) {
    
    }
    
    //Applying the AVVideoComposition to the video
    func didConvertVideoToBlackAndWhite(_ output: AVVideoComposition,_ asset: AVAsset) {
        guard let _ = videoUrl else { return }
        removeImage()
        removePreviousPlayer()
        let playerItem = AVPlayerItem(asset: asset)
        playerItem.videoComposition = output
        self.player = AVPlayer(playerItem: playerItem)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = self.conatinerView.bounds
        playerLayer?.videoGravity = .resizeAspect
        self.conatinerView.layer.addSublayer(playerLayer!)
        player!.play()
    }
    
    
    //Rotating videos usig the player rotation
    func rotateVideoMethod() {
        removePreviousPlayer()
        guard let _ = videoUrl else { return }
        removeImage()
        self.player = AVPlayer(url: (videoUrl?.absoluteURL)!)
        playerLayer = AVPlayerLayer.init(player: self.player)
        playerLayer?.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(M_PI)))
        playerLayer?.frame = conatinerView.bounds
        playerLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        conatinerView.layer.addSublayer(playerLayer!)
        player!.play()
    }
    
    //Clearing the screen of previous Video
    func removePreviousPlayer() {
        if let layer = playerLayer {
            player!.pause()
            layer.removeFromSuperlayer()
        }
    }
    
    //Clearing the screen from previous Image
    func removeImage() {
        self.imageView?.removeFromSuperview()
    }
}


extension ViewController {
    
    //Setting Maps
    func setUpGoogleMaps() {
        if mapView == nil {
            mapView = GMSMapView.map(withFrame: CGRect(x: 100, y: 100, width: 200, height: 200), camera: GMSCameraPosition.camera(withLatitude: 51.050657, longitude: 10.649514, zoom: 5.5))
            mapView?.frame = self.gmsMap.bounds
            self.gmsMap.addSubview(mapView!)
        }
        
    }
    
    //Setting Markers
    func setUpLocationMarker(_ name: String) {
        DispatchQueue.main.async { [weak self] in
            if let  position = self?.locationDictionary[name] {
                let marker = GMSMarker(position: position)
                marker.title = name
                marker.map = self?.mapView
            }
        }
    }

}
