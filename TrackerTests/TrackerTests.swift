//
//  TrackerTests.swift
//  TrackerTests
//
//  Created by Павел Кузнецов on 09.03.2026.
//

import XCTest
import SnapshotTesting
@testable import Tracker

final class TrackersListViewControllerSnapshotTests: XCTestCase {

    func testTrackersListViewControllerLightMode() {
        let tabBarController = TabBarViewController()
        tabBarController.loadViewIfNeeded()

        tabBarController.overrideUserInterfaceStyle = .light

        assertSnapshot(of: tabBarController, as: .image(traits: .init(userInterfaceStyle: .light)))
    }

    func testTrackersListViewControllerDarkMode() {
        let tabBarController = TabBarViewController()
        tabBarController.loadViewIfNeeded()

        tabBarController.overrideUserInterfaceStyle = .dark

        assertSnapshot(of: tabBarController, as: .image(traits: .init(userInterfaceStyle: .dark)))
    }
}
