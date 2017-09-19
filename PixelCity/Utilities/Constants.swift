//
//  Constants.swift
//  PixelCity
//
//  Created by Stanley Pan on 19/09/2017.
//  Copyright © 2017 Stanley Pan. All rights reserved.
//

import Foundation

let apiKey = "180f986d057edf2dcf26157daa5ba396"

func flickrURL(forApiKey key: String, withAnnotation annotation: DroppablePin, andNumberOfPhotos number: Int) -> String {
    
    let url = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(apiKey)&lat=\(annotation.coordinate.latitude)&lon=\(annotation.coordinate.longitude)&radius=1&radius_units=mi&per_page=\(number)&format=json&nojsoncallback=1"
    return url
}
