//
//  TrackerCreationProtocols.swift
//  Tracker
//
//  Created by Павел Кузнецов on 27.01.2026.
//

import Foundation

// MARK: - TrackerType

enum TrackerType {
    case habit
    case irregular
    
    var title: String {
        switch self {
        case .habit: return "Новая привычка"
        case .irregular: return "Новое нерегулярное событие"
        }
    }
}

// MARK: - Protocols

protocol CreateTrackerDelegate: AnyObject {
    func didCreateTracker(_ tracker: Tracker, category: String)
}

protocol CategorySelectionDelegate: AnyObject {
    func didSelectCategory(_ category: String)
}

protocol ScheduleSelectionDelegate: AnyObject {
    func didSelectSchedule(_ schedule: Set<Weekday>)
}

// MARK: - Weekday Extension

extension Weekday {
    var fullName: String {
        switch self {
        case .sunday: return "Воскресенье"
        case .monday: return "Понедельник"
        case .tuesday: return "Вторник"
        case .wednesday: return "Среда"
        case .thursday: return "Четверг"
        case .friday: return "Пятница"
        case .saturday: return "Суббота"
        }
    }
    
    var shortName: String {
        switch self {
        case .sunday: return "Вс"
        case .monday: return "Пн"
        case .tuesday: return "Вт"
        case .wednesday: return "Ср"
        case .thursday: return "Чт"
        case .friday: return "Пт"
        case .saturday: return "Сб"
        }
    }
}
