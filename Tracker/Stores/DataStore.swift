//
//  DataStore.swift
//  Tracker
//
//  Created by Павел Кузнецов on 07.02.2026.
//

import UIKit
import CoreData

final class DataStore {
    
    // MARK: - Properties
    
    static let shared = DataStore()
    
    let trackerStore: TrackerStore
    let categoryStore: TrackerCategoryStore
    let recordStore: TrackerRecordStore
    
    private let context: NSManagedObjectContext
    
    // MARK: - Initialization
    
    private init() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("Unable to access AppDelegate")
        }
        
        self.context = appDelegate.persistentContainer.viewContext
        self.categoryStore = TrackerCategoryStore(context: context, trackerStore: nil)
        self.trackerStore = TrackerStore(context: context, categoryStore: categoryStore)
        self.recordStore = TrackerRecordStore(context: context)
    }
    
    // MARK: - Public Methods
    
    func addTracker(_ tracker: Tracker, to categoryName: String) throws {
        try trackerStore.add(tracker, toCategoryWithName: categoryName)
    }
    
    
    func fetchAllCategories() throws -> [TrackerCategory] {
        return trackerStore.fetchAll()
    }
    
    func completeTracker(id: UUID, date: Date) throws {
        let record = TrackerRecord(trackerId: id, date: date)
        try recordStore.addRecord(record)
    }
    
    func uncompleteTracker(id: UUID, date: Date) throws {
        let record = TrackerRecord(trackerId: id, date: date)
        try recordStore.deleteRecord(record)
    }
    
    func isTrackerCompleted(id: UUID, date: Date) throws -> Bool {
        return try recordStore.recordExists(trackerId: id, date: date)
    }
    
    func getCompletionCount(for trackerId: UUID) throws -> Int {
        return try recordStore.fetchCompletionCount(for: trackerId)
    }
    
    func togglePin(trackerId: UUID) throws {
        try trackerStore.togglePin(trackerId: trackerId)
    }
    
    func deleteTracker(trackerId: UUID) throws {
        try trackerStore.deleteTracker(trackerId: trackerId)
    }
    
    func updateTracker(_ tracker: Tracker, in categoryName: String) throws {
        try trackerStore.add(tracker, toCategoryWithName: categoryName)
    }
    
    func fetchCategoryName(for trackerId: UUID) -> String? {
        return trackerStore.fetchCategoryName(for: trackerId)
    }
    
    func fetchAllTrackers() throws -> [Tracker] {
        return try trackerStore.fetchAllTrackers()
    }
    
    func fetchAllRecords() throws -> [TrackerRecord] {
        return try recordStore.fetchAllRecords()
    }
}
