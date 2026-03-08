//
//  ScheduleModel.swift
//  Tracker
//
//  Created by Павел Кузнецов on 29.01.2026.
//

import Foundation

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
    
    var fullName: String {
        switch self {
        case .sunday: return NSLocalizedString("weekday.sunday", comment: "")
        case .monday: return NSLocalizedString("weekday.monday", comment: "")
        case .tuesday: return NSLocalizedString("weekday.tuesday", comment: "")
        case .wednesday: return NSLocalizedString("weekday.wednesday", comment: "")
        case .thursday: return NSLocalizedString("weekday.thursday", comment: "")
        case .friday: return NSLocalizedString("weekday.friday", comment: "")
        case .saturday: return NSLocalizedString("weekday.saturday", comment: "")
        }
    }
    
    var shortName: String {
        switch self {
        case .sunday: return NSLocalizedString("weekday.short.sunday", comment: "")
        case .monday: return NSLocalizedString("weekday.short.monday", comment: "")
        case .tuesday: return NSLocalizedString("weekday.short.tuesday", comment: "")
        case .wednesday: return NSLocalizedString("weekday.short.wednesday", comment: "")
        case .thursday: return NSLocalizedString("weekday.short.thursday", comment: "")
        case .friday: return NSLocalizedString("weekday.short.friday", comment: "")
        case .saturday: return NSLocalizedString("weekday.short.saturday", comment: "")
        }
    }
}
