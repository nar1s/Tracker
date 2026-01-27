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
    
    var uiColor: UIColor {
        return UIColor(named: color) ?? .systemBlue
    }
}

struct Schedule: Codable {
    let weekdays: Set<Weekday>
}
enum Weekday: Int, Codable, CaseIterable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
}

