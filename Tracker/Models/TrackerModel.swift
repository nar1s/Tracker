//
//  TrackerModel.swift
//  Tracker
//
//  Created by Павел Кузнецов on 26.01.2026.
//

import UIKit

struct Tracker {
    let id: UUID
    let name: String
    let color: String
    let emoji: String
    let schedule: Schedule?
    let createdAt: Date
    
    init(id: UUID, name: String, color: String, emoji: String, schedule: Schedule?, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.color = color
        self.emoji = emoji
        self.schedule = schedule
        self.createdAt = createdAt
    }
    var uiColor: UIColor {
        return UIColor(named: color) ?? .systemBlue
    }
}
