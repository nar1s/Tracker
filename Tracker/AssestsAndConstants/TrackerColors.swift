//
//  TrackerColors.swift
//  Tracker
//
//  Created by Павел Кузнецов on 26.01.2026.
//

import UIKit

enum TrackerColor: Int, CaseIterable {
    case color1 = 1
    case color2 = 2
    case color3 = 3
    case color4 = 4
    case color5 = 5
    case color6 = 6
    case color7 = 7
    case color8 = 8
    case color9 = 9
    case color10 = 10
    case color11 = 11
    case color12 = 12
    case color13 = 13
    case color14 = 14
    case color15 = 15
    case color16 = 16
    case color17 = 17
    case color18 = 18
    
    var uiColor: UIColor {
        return UIColor(named: "TrackerColor\(rawValue)") ?? .systemBlue
    }
    
    var colorName: String {
        return "TrackerColor\(rawValue)"
    }
    
    static func from(colorName: String) -> TrackerColor? {
        guard colorName.hasPrefix("TrackerColor"),
              let numberString = colorName.split(separator: "r").last,
              let number = Int(numberString),
              let color = TrackerColor(rawValue: number) else {
            return nil
        }
        return color
    }
    
    static var allUIColors: [UIColor] {
        return TrackerColor.allCases.map { $0.uiColor }
    }
}
