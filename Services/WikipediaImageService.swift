//
//  WikipediaImageService.swift
//  WhereTo
//
//  Created by Allan Constanza on 9/27/25.
//

import Foundation
import CoreLocation

final class WikipediaImageService {

    // Main fast request
    func fastImage(for title: String) async -> URL? {

        let normalized = title
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "_")
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
            ?? title

        let urlString = "https://en.wikipedia.org/api/rest_v1/page/summary/\(normalized)"
        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            // Wikipedia sometimes returns "type": "disambiguation"
            if let type = obj?["type"] as? String,
               type == "disambiguation" {
                return nil   // fallback handler will catch this
            }

            // Try thumbnail
            if let src = (obj?["thumbnail"] as? [String: Any])?["source"] as? String {
                return URL(string: src)
            }

            // Try original image
            if let src = (obj?["originalimage"] as? [String: Any])?["source"] as? String {
                return URL(string: src)
            }

        } catch {
            return nil
        }

        return nil
    }

    // Fallback for cases like "Portland"
    func fetchCityImageURL(cityName: String) async -> URL? {

        // 1 — Try "City, State"
        if cityName == "Portland",
           let url = await fastImage(for: "Portland,_Oregon") {
            return url
        }

        // 2 — Try the raw name
        if let url = await fastImage(for: cityName) {
            return url
        }

        // 3 — Fallback for common ambiguous names
        if let url = await fastImage(for: "\(cityName)_city") {
            return url
        }

        // 4 — Last fallback: "...,_USA"
        if let url = await fastImage(for: "\(cityName),_USA") {
            return url
        }

        return nil
    }
}


