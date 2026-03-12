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
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
    
    var fullName: String {
        switch self {
        case .sunday: NSLocalizedString("weekday.sunday", comment: "")
        case .monday: NSLocalizedString("weekday.monday", comment: "")
        case .tuesday: NSLocalizedString("weekday.tuesday", comment: "")
        case .wednesday: NSLocalizedString("weekday.wednesday", comment: "")
        case .thursday: NSLocalizedString("weekday.thursday", comment: "")
        case .friday: NSLocalizedString("weekday.friday", comment: "")
        case .saturday: NSLocalizedString("weekday.saturday", comment: "")
        }
    }
    
    var shortName: String {
        switch self {
        case .sunday: NSLocalizedString("weekday.short.sunday", comment: "")
        case .monday: NSLocalizedString("weekday.short.monday", comment: "")
        case .tuesday: NSLocalizedString("weekday.short.tuesday", comment: "")
        case .wednesday: NSLocalizedString("weekday.short.wednesday", comment: "")
        case .thursday: NSLocalizedString("weekday.short.thursday", comment: "")
        case .friday: NSLocalizedString("weekday.short.friday", comment: "")
        case .saturday: NSLocalizedString("weekday.short.saturday", comment: "")
        }
    }
}
