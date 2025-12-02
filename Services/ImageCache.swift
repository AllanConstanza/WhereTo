//
//  ImageCache.swift
//  WhereTo
//
//  Created by Allan Constanza on 11/17/25.
//

import Foundation

actor ImageCache {
    static let shared = ImageCache()
    private var cache: [String: URL] = [:]

    func get(_ key: String) -> URL? {
        cache[key]
    }

    func set(_ key: String, url: URL) {
        cache[key] = url
    }
}
