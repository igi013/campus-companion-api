//
//  AnnouncementDTO.swift
//  CampusCompanion
//
//  Created by John Ronen Soriano on 10/14/26.
//

import Foundation

struct AnnouncementDTO: Decodable {
    let title: String
    let date: String
    let category: String
    let location: String
    let priorityLevel: String

    private enum CodingKeys: String, CodingKey {
        case title
        case date
        case category
        case location
        case priorityLevel
        case priority
        case priority_level
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        date = try container.decode(String.self, forKey: .date)
        category = try container.decode(String.self, forKey: .category)
        location = try container.decodeIfPresent(String.self, forKey: .location) ?? "Campus"
        priorityLevel = try container.decodeIfPresent(String.self, forKey: .priorityLevel)
        ?? container.decodeIfPresent(String.self, forKey: .priority)
        ?? container.decodeIfPresent(String.self, forKey: .priority_level)
        ?? "Normal"
    }
}
