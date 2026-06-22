import Foundation

/// Minimal self-contained geohash encoder.
///
/// The schema stores a `geohash` string alongside every `location` GeoPoint so radius queries
/// can be approximated with a string-range scan on the geohash prefix. This encoder is used
/// when writing location updates from the app. For live radius queries, replace with GeoFire.
enum Geohash {
    private static let base32 = Array("0123456789bcdefghjkmnpqrstuvwxyz")

    /// Encodes a lat/lng pair as a geohash string.
    /// - Parameters:
    ///   - latitude: Latitude in degrees (-90…90).
    ///   - longitude: Longitude in degrees (-180…180).
    ///   - length: Number of characters (precision). 9 ≈ ±2.4 m. Default is 9.
    static func encode(latitude: Double, longitude: Double, length: Int = 9) -> String {
        var minLat = -90.0, maxLat = 90.0
        var minLon = -180.0, maxLon = 180.0
        var result = ""
        var isLon = true      // even bits → longitude, odd bits → latitude
        var charBits = 0
        var bitCount = 0

        while result.count < length {
            if isLon {
                let mid = (minLon + maxLon) / 2
                if longitude >= mid { charBits = (charBits << 1) | 1; minLon = mid }
                else { charBits = charBits << 1; maxLon = mid }
            } else {
                let mid = (minLat + maxLat) / 2
                if latitude >= mid { charBits = (charBits << 1) | 1; minLat = mid }
                else { charBits = charBits << 1; maxLat = mid }
            }
            isLon.toggle()
            bitCount += 1

            if bitCount == 5 {
                result.append(base32[charBits])
                charBits = 0
                bitCount = 0
            }
        }
        return result
    }
}
