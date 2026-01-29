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
