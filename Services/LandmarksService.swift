//
//  LandmarksService.swift
//  WhereTo
//
//  Created by Allan Constanza on 9/27/25.
//


import Foundation
import CoreLocation

final class LandmarksService {
    private struct OverpassResponse: Decodable {
        struct Element: Decodable {
            let type: String
            let id: Int64
            let lat: Double?
            let lon: Double?
            let center: Center?
            let tags: [String:String]?
            struct Center: Decodable { let lat: Double; let lon: Double }
        }
        let elements: [Element]
    }

    func fetchLandmarks(near center: CLLocationCoordinate2D,
                        radiusMeters: Int = 12_000,
                        limit: Int = 18) async throws -> [Landmark] {
        let ql = overpassQL(lat: center.latitude, lon: center.longitude, radius: radiusMeters)
        var req = URLRequest(url: URL(string: "https://overpass-api.de/api/interpreter")!)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        req.setValue("WhereTo/1.0 (iOS) LandmarksService", forHTTPHeaderField: "User-Agent")
        req.httpBody = "data=\(ql)".data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: req)
        let decoded = try JSONDecoder().decode(OverpassResponse.self, from: data)

        var landmarks: [Landmark] = decoded.elements.compactMap { el in
            guard let tags = el.tags, let rawName = tags["name"]?.trimmingCharacters(in: .whitespacesAndNewlines), !rawName.isEmpty else { return nil }
            let coord: CLLocationCoordinate2D? = {
                if let lat = el.lat, let lon = el.lon { return .init(latitude: lat, longitude: lon) }
                if let c = el.center { return .init(latitude: c.lat, longitude: c.lon) }
                return nil
            }()
            let category = tags["tourism"] ?? tags["historic"] ?? tags["landmark"]
            var lm = Landmark(name: rawName, category: category, coord: coord, imageURL: nil)
            lm.osmID = "\(el.type):\(el.id)"
            lm.wikipedia = tags["wikipedia"]
            lm.wikidata = tags["wikidata"]
            return lm
        }

        var seen = Set<String>()
        landmarks = landmarks.filter { lm in
            let key = lm.name.lowercased()
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }

        let origin = CLLocation(latitude: center.latitude, longitude: center.longitude)
        func score(_ lm: Landmark) -> (Int, CLLocationDistance) {
            let cat = (lm.category ?? "").lowercased()
            let pri = (cat == "attraction" ? 0 : (cat.isEmpty ? 2 : 1))
            let d = lm.coord.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude).distance(from: origin) } ?? .greatestFiniteMagnitude
            return (pri, d)
        }
        landmarks.sort { a, b in
            let sa = score(a), sb = score(b)
            return sa.0 != sb.0 ? sa.0 < sb.0 : sa.1 < sb.1
        }

        if landmarks.count > limit { landmarks = Array(landmarks.prefix(limit)) }
        return landmarks
    }

    private func overpassQL(lat: Double, lon: Double, radius: Int) -> String {
        let parts = [
            #"node["tourism"="attraction"](around:\#(radius),\#(lat),\#(lon));"#,
            #"way["tourism"="attraction"](around:\#(radius),\#(lat),\#(lon));"#,
            #"relation["tourism"="attraction"](around:\#(radius),\#(lat),\#(lon));"#,
            #"node["historic"](around:\#(radius),\#(lat),\#(lon));"#,
            #"way["historic"](around:\#(radius),\#(lat),\#(lon));"#,
            #"relation["historic"](around:\#(radius),\#(lat),\#(lon));"#,
            #"node["landmark"](around:\#(radius),\#(lat),\#(lon));"#,
            #"way["landmark"](around:\#(radius),\#(lat),\#(lon));"#,
            #"relation["landmark"](around:\#(radius),\#(lat),\#(lon));"#
        ]
        let body = "[out:json][timeout:25];(" + parts.joined() + ");out center;"
        return body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? body
    }
}

