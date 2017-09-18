//
//  MapVC.swift
//  PixelCity
//
//  Created by Stanley Pan on 18/09/2017.
//  Copyright © 2017 Stanley Pan. All rights reserved.
//

import UIKit
import MapKit

class MapVC: UIViewController {
    
    //  MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
    }
    
    @IBAction func centerMapButtonPressed(_ sender: UIButton) {
        
    }
}

extension MapVC: MKMapViewDelegate {
    
}
