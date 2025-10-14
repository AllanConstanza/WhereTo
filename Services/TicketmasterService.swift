//
//  TicketmasterService.swift
//  WhereTo
//
//  Created by Allan Constanza on 10/13/25.
//

import Foundation
import CoreLocation

struct TMEvent: Identifiable {
    let id: String
    let name: String
    let date: Date?
    let venue: String?
    let url: URL?
    let imageURL: URL?
}

enum TicketmasterError: LocalizedError {
    case missingKey
    case http(Int, String)
    case decode(String)
    case noResults
    var errorDescription: String? {
        switch self {
        case .missingKey: return "Missing Ticketmaster API key."
        case let .http(code, body): return "Ticketmaster HTTP \(code): \(body.prefix(200))"
        case let .decode(sample):   return "Could not parse Ticketmaster response: \(sample.prefix(200))"
        case .noResults:            return "No events found."
        }
    }
}

final class TicketmasterService {
    private let key: String
    init(key: String) { self.key = key }

    func events(
        city: String,
        countryCode: String = "US",
        size: Int = 20,
        startDate: Date? = nil
    ) async throws -> [TMEvent] {
        guard !key.isEmpty else { throw TicketmasterError.missingKey }
        var comps = URLComponents(string: "https://app.ticketmaster.com/discovery/v2/events.json")!
        var q: [URLQueryItem] = [
            .init(name: "apikey", value: key),
            .init(name: "city", value: city),
            .init(name: "countryCode", value: countryCode),
            .init(name: "size", value: String(min(max(size, 1), 200))),
            .init(name: "sort", value: "date,asc")
        ]
        if let startDate { q.append(.init(name: "startDateTime", value: Self.tmZuluString(from: startDate))) }
        comps.queryItems = q
        return try await fetch(from: comps.url!)
    }

    func events(
        near coord: CLLocationCoordinate2D,
        radiusMiles: Int = 25,
        size: Int = 20,
        startDate: Date? = nil
    ) async throws -> [TMEvent] {
        guard !key.isEmpty else { throw TicketmasterError.missingKey }
        var comps = URLComponents(string: "https://app.ticketmaster.com/discovery/v2/events.json")!
        var q: [URLQueryItem] = [
            .init(name: "apikey", value: key),
            .init(name: "latlong", value: "\(coord.latitude),\(coord.longitude)"),
            .init(name: "radius", value: String(max(1, min(200, radiusMiles)))),
            .init(name: "unit", value: "miles"),
            .init(name: "size", value: String(min(max(size, 1), 200))),
            .init(name: "sort", value: "date,asc")
        ]
        if let startDate { q.append(.init(name: "startDateTime", value: Self.tmZuluString(from: startDate))) }
        comps.queryItems = q
        return try await fetch(from: comps.url!)
    }

    private func fetch(from url: URL) async throws -> [TMEvent] {
        let (data, resp) = try await URLSession.shared.data(from: url)
        guard let http = resp as? HTTPURLResponse else {
            throw TicketmasterError.http(-1, "No HTTP response")
        }
        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "<\(data.count) bytes>"
            throw TicketmasterError.http(http.statusCode, body)
        }

        do {
            let decoded = try JSONDecoder().decode(Root.self, from: data)
            let events = decoded._embedded?.events ?? []
            if events.isEmpty { throw TicketmasterError.noResults }

            let isoWithMs = ISO8601DateFormatter()
            isoWithMs.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            isoWithMs.timeZone = TimeZone(secondsFromGMT: 0)

            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime]
            iso.timeZone = TimeZone(secondsFromGMT: 0)

            func parseDate(_ s: String?) -> Date? {
                guard let s else { return nil }
                return isoWithMs.date(from: s) ?? iso.date(from: s)
            }

            return events.map { ev in
                TMEvent(
                    id: ev.id ?? UUID().uuidString,
                    name: ev.name ?? "Event",
                    date: parseDate(ev.dates?.start?.dateTime),
                    venue: ev._embedded?.venues?.first?.name,
                    url: ev.url.flatMap(URL.init(string:)),
                    imageURL: ev.images?
                        .sorted { ($0.width ?? 0) > ($1.width ?? 0) }
                        .first?.url.flatMap(URL.init(string:))
                )
            }
        } catch {
            let sample = String(data: data, encoding: .utf8) ?? "<\(data.count) bytes>"
            throw TicketmasterError.decode(sample)
        }
    }

    private static func tmZuluString(from date: Date) -> String {
        let t = Date(timeIntervalSince1970: floor(date.timeIntervalSince1970))
        return tmZuluFormatter.string(from: t)
    }
    private static let tmZuluFormatter: DateFormatter = {
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .iso8601)
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        return df
    }()

    private struct Root: Decodable {
        let _embedded: Embedded?
        struct Embedded: Decodable { let events: [Event]? }

        struct Event: Decodable {
            let id: String?
            let name: String?
            let url: String?
            let images: [Image]?
            let dates: Dates?
            let _embedded: VenuesEmb?
        }
        struct Image: Decodable { let url: String?; let width: Int? }
        struct Dates: Decodable { let start: Start? }
        struct Start: Decodable { let dateTime: String? }
        struct VenuesEmb: Decodable { let venues: [Venue]? }
        struct Venue: Decodable { let name: String? }
    }
}

