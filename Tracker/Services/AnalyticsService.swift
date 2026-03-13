//
//  AnalyticsService.swift
//  Tracker
//

import Foundation
import AppMetricaCore

final class AnalyticsService {
    static func report(event: String, params: [AnyHashable: Any]) {
        AppMetrica.reportEvent(name: event, parameters: params) { error in
            print("SEND EVENT FAILED: \(error)")
        }
    }
}
