//
//  WikiLandmarksService.swift
//  WhereTo
//
//  Created by Allan Constanza on 11/30/25.
//

import Foundation
import CoreLocation

struct WikiLandmark: Identifiable, Codable {
    let id: Int
    let name: String
    let imageURL: URL?
    let description: String?
}

final class WikiLandmarksService {

    func fetchLandmarks(near coord: CLLocationCoordinate2D) async throws -> [WikiLandmark] {

        let geoURL =
        """
        https://en.wikipedia.org/w/api.php?action=query&list=geosearch&gscoord=\(coord.latitude)|\(coord.longitude)&gsradius=10000&gslimit=12&format=json
        """

        let geoData = try await fetch(urlString: geoURL)
        let geoResult = try JSONDecoder().decode(WikiGeoResponse.self, from: geoData)

        let ids = geoResult.query.geosearch.map { String($0.pageid) }.joined(separator: "|")
        if ids.isEmpty { return [] }

        let detailURL =
        """
        https://en.wikipedia.org/w/api.php?action=query&pageids=\(ids)&prop=pageimages|description&piprop=thumbnail&pithumbsize=400&format=json
        """

        let detailData = try await fetch(urlString: detailURL)
        let detailResult = try JSONDecoder().decode(WikiDetailResponse.self, from: detailData)

        let landmarks = detailResult.query.pages.values.map { page in
            WikiLandmark(
                id: page.pageid,
                name: page.title,
                imageURL: page.thumbnail?.source.flatMap(URL.init),
                description: page.description
            )
        }

        return landmarks.sorted { $0.name < $1.name }
    }

    private func fetch(urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "WhereTo", code: -1, userInfo: [NSLocalizedDescriptionKey: "Bad URL"])
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw NSError(
                domain: "WhereTo",
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "Wikipedia error \(http.statusCode)"])
        }

        return data
    }
}

private struct WikiGeoResponse: Codable {
    let query: GeoQuery

    struct GeoQuery: Codable {
        let geosearch: [GeoItem]

        struct GeoItem: Codable {
            let pageid: Int
            let title: String
        }
    }
}

private struct WikiDetailResponse: Codable {
    let query: PageQuery

    struct PageQuery: Codable {
        let pages: [String: Page]

        struct Page: Codable {
            let pageid: Int
            let title: String
            let description: String?
            let thumbnail: Thumbnail?

            struct Thumbnail: Codable {
                let source: String?
            }
        }
    }
}

