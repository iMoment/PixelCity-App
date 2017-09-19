//
//  MapVC.swift
//  PixelCity
//
//  Created by Stanley Pan on 18/09/2017.
//  Copyright © 2017 Stanley Pan. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Alamofire
import AlamofireImage

class MapVC: UIViewController {
    
    //  MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var pullUpView: UIView!
    @IBOutlet weak var pullUpViewHeightConstraint: NSLayoutConstraint!
    
    //  MARK: Variables
    var locationManager = CLLocationManager()
    let authorizationStatus = CLLocationManager.authorizationStatus()
    let regionRadius: Double = 1000
    
    let screenSize = UIScreen.main.bounds
    
    var activitySpinner: UIActivityIndicatorView?
    var progressLabel: UILabel?
    
    var flowLayout = UICollectionViewFlowLayout()
    var photosCollectionView: UICollectionView?
    
    var imageUrlArray = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        configureLocationServices()
        addDoubleTap()
        
        photosCollectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        photosCollectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: "photoCell")
        photosCollectionView?.delegate = self
        photosCollectionView?.dataSource = self
        photosCollectionView?.backgroundColor = #colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1)
        
        pullUpView.addSubview(photosCollectionView!)
    }
    
    func addDoubleTap() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(dropPin(_:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        mapView.addGestureRecognizer(doubleTap)
    }
    
    func addSwipe() {
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(animateViewDown(_:)))
        swipeGesture.direction = .down
        pullUpView.addGestureRecognizer(swipeGesture)
    }
    
    func animateViewUp() {
        pullUpViewHeightConstraint.constant = 300
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func animateViewDown(_ swipeGesture: UISwipeGestureRecognizer) {
        pullUpViewHeightConstraint.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    func addSpinner() {
        activitySpinner = UIActivityIndicatorView()
        activitySpinner?.center = CGPoint(x: (screenSize.width / 2) - ((activitySpinner?.frame.width)! / 2), y: 150)
        activitySpinner?.activityIndicatorViewStyle = .whiteLarge
        activitySpinner?.color = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        activitySpinner?.startAnimating()
        photosCollectionView?.addSubview(activitySpinner!)
    }
    
    func removeSpinner() {
        if activitySpinner != nil {
            activitySpinner?.removeFromSuperview()
        }
    }
    
    func addProgressLabel() {
        progressLabel = UILabel()
        progressLabel?.frame = CGRect(x: (screenSize.width / 2) - 120, y: 175, width: 240, height: 40)
        progressLabel?.font = UIFont(name: "Avenir Next", size: 18)
        progressLabel?.textColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        progressLabel?.textAlignment = .center
        photosCollectionView?.addSubview(progressLabel!)
    }
    
    func removeProgressLabel() {
        if progressLabel != nil {
            progressLabel?.removeFromSuperview()
        }
    }
    
    @IBAction func centerMapButtonPressed(_ sender: UIButton) {
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            centerMapOnUserLocation()
        }
    }
}

extension MapVC: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let pinAnnotation = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "droppablePin")
        pinAnnotation.pinTintColor = #colorLiteral(red: 0.9647058824, green: 0.6509803922, blue: 0.137254902, alpha: 1)
        pinAnnotation.animatesDrop = true
        return pinAnnotation
    }
    
    func centerMapOnUserLocation() {
        guard let coordinate = locationManager.location?.coordinate else { return }
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    @objc func dropPin(_ gesture: UITapGestureRecognizer) {
        self.removePin()
        self.removeSpinner()
        self.removeProgressLabel()
        self.animateViewUp()
        self.addSwipe()
        self.addSpinner()
        self.addProgressLabel()
        
        let touchPoint = gesture.location(in: mapView)
        let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        let annotation = DroppablePin(coordinate: touchCoordinate, identifier: "droppablePin")
        mapView.addAnnotation(annotation)
        
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(touchCoordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
        
        self.retrieveUrls(forAnnotation: annotation) { (success) in
            if success {
                
            }
        }
    }
    
    func removePin() {
        for annotation in mapView.annotations {
            mapView.removeAnnotation(annotation)
        }
    }
    
    func retrieveUrls(forAnnotation annotation: DroppablePin, handler: @escaping CompletionHandler) {
        imageUrlArray.removeAll(keepingCapacity: false)
        let url = flickrURL(forApiKey: apiKey, withAnnotation: annotation, andNumberOfPhotos: 40)
        
        Alamofire.request(url).responseJSON { (response) in
            
            if response.result.error == nil {
                guard let json = response.result.value as? [String: AnyObject] else { return }
                let photosDictionary = json["photos"] as! [String: AnyObject]
                let photosArray = photosDictionary["photo"] as! [[String: AnyObject]]
                for photo in photosArray {
                    let postUrl = "https://farm\(photo["farm"]!).staticflickr.com/\(photo["server"]!)/\(photo["id"]!)_\(photo["secret"]!)_h_d.jpg"
                    self.imageUrlArray.append(postUrl)
                    
                }
                handler(true)
            } else {
                handler(false)
                debugPrint(response.result.error as Any)
            }
        }
    }
}

extension MapVC: CLLocationManagerDelegate {
    
    func configureLocationServices() {
        if authorizationStatus == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        } else {
            return
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        centerMapOnUserLocation()
    }
}

extension MapVC: UIGestureRecognizerDelegate {
    
}

extension MapVC: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //  TODO: number of items in Photo Array
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as? PhotoCell {
            return cell
        }
        return UICollectionViewCell()
    }
}

extension MapVC: UICollectionViewDelegate {
    
}










