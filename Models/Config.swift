//
//  Config.swift
//  WhereTo
//
//  Created by Allan Constanza on 10/10/25.
//


import Foundation

enum AppConfig {
    private static var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }


    static var ticketmasterKey: String {
        let raw = Bundle.main.object(forInfoDictionaryKey: "TicketmasterAPIKey") as? String
        return (raw ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    static var hasTicketmasterKey: Bool {
        !ticketmasterKey.isEmpty
    }
     
    
 
    static let foursquareKey   = "0KXVDI5RGGSEDVLLRVS5UZN12BERSGNYTK5XUOCECBLVIZV2"
    

    
    
}
