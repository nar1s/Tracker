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
