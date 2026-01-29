//
//  TrackerColors.swift
//  Tracker
//
//  Created by Павел Кузнецов on 26.01.2026.
//

import UIKit

enum TrackerColor: Int, CaseIterable {
    case color1 = 1
    case color2
    case color3
    case color4
    case color5
    case color6
    case color7
    case color8
    case color9
    case color10
    case color11
    case color12
    case color13
    case color14
    case color15
    case color16
    case color17
    case color18
    
    var colorName: String {
        "TrackerColor\(rawValue)"
    }
    
    var uiColor: UIColor {
        UIColor(named: colorName) ?? .systemBlue
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
        TrackerColor.allCases.map { $0.uiColor }
    }
}
