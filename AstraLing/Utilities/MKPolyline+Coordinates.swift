//
//  MKPolyline+Coordinates.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 24/06/26.
//

import MapKit

extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var result = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        getCoordinates(&result, range: NSRange(location: 0, length: pointCount))
        return result
    }
}
