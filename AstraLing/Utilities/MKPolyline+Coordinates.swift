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

#if DEBUG
extension CLLocationCoordinate2D {
    func randomNearby(minMeters: Double = 500, maxMeters: Double = 1500) -> CLLocationCoordinate2D {
        let distance = Double.random(in: minMeters...maxMeters)
        let bearing = Double.random(in: 0 ..< (2 * .pi))
        let latRad = latitude * .pi / 180
        let newLat = latitude + (distance * cos(bearing)) / 111_320
        let newLng = longitude + (distance * sin(bearing)) / (111_320 * cos(latRad))
        return CLLocationCoordinate2D(latitude: newLat, longitude: newLng)
    }
}
#endif
