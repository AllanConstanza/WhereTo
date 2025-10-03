//
//  WikipediaImageService.swift
//  WhereTo
//
//  Created by Allan Constanza on 9/27/25.
//

import Foundation

final class WikipediaImageService {
    private struct Summary: Decodable {
        struct Media: Decodable { let source: String }
        let type: String?
        let originalimage: Media?
        let thumbnail: Media?
    }

    private let preferredTitles: [String: String] = [
        "new york": "New York City",
        "los angeles": "Los Angeles",
        "san francisco": "San Francisco"
    ]

    func fetchImageURL(title raw: String) async -> URL? {
        let title = normalize(raw)
        guard let url = URL(string: "https://en.wikipedia.org/api/rest_v1/page/summary/\(title)") else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let summary = try JSONDecoder().decode(Summary.self, from: data)
            if summary.type == "disambiguation" { return nil }
            if let s = summary.thumbnail?.source, let u = URL(string: s) { return u }
            if let s = summary.originalimage?.source, let u = URL(string: s) { return u }
        } catch {}
        return nil
    }

    func fetchCityImageURL(cityName: String) async -> URL? {
        let key = cityName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let preferred = preferredTitles[key] ?? cityName
        if let u = await fetchImageURL(title: preferred) { return u }
        return await fetchImageURL(title: cityName)
    }

    func fetchImageURL(wikipediaTag: String) async -> URL? {
        let parts = wikipediaTag.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return nil }
        let lang = parts[0]
        let title = parts[1]
        guard let url = URL(string: "https://\(lang).wikipedia.org/api/rest_v1/page/summary/\(title)") else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let summary = try JSONDecoder().decode(Summary.self, from: data)
            if summary.type == "disambiguation" { return nil }
            if let s = summary.thumbnail?.source, let u = URL(string: s) { return u }
            if let s = summary.originalimage?.source, let u = URL(string: s) { return u }
        } catch {}
        return nil
    }

    func fetchImageURL(wikidataID: String) async -> URL? {
        guard let url = URL(string: "https://www.wikidata.org/wiki/Special:EntityData/\(wikidataID).json") else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let entities = obj["entities"] as? [String: Any],
               let ent = entities[wikidataID] as? [String: Any],
               let claims = ent["claims"] as? [String: Any],
               let p18 = claims["P18"] as? [[String: Any]],
               let mainsnak = p18.first?["mainsnak"] as? [String: Any],
               let datav = mainsnak["datavalue"] as? [String: Any],
               let filename = datav["value"] as? String {
                let enc = filename.replacingOccurrences(of: " ", with: "_")
                return URL(string: "https://commons.wikimedia.org/wiki/Special:FilePath/\(enc)?width=480")
            }
        } catch {}
        return nil
    }

    private func normalize(_ title: String) -> String {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.replacingOccurrences(of: " ", with: "_").addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? t
    }
}
