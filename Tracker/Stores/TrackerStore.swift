//
//  TrackerStore.swift
//  Tracker
//
//  Created by Павел Кузнецов on 07.02.2026.
//

import CoreData
import UIKit

final class TrackerStore: NSObject {
    
    // MARK: - Constants
    
    private enum TrackerEntity {
        static let name = "TrackerCD"
        static let id = "id"
        static let title = "name"
        static let emoji = "emoji"
        static let color = "color"
        static let schedule = "schedule"
        static let createdAt = "createdAt"
        static let category = "category"
        static let isPinned = "isPinned"
    }
    
    private enum CategoryEntity {
        static let name = "name"
        static let trackers = "trackers"
    }
    
    // MARK: - Properties
    
    var onDidUpdate: (() -> Void)?
    
    private let context: NSManagedObjectContext
    private let categoryStore: TrackerCategoryStore
    
    private lazy var fetchedResultsController: NSFetchedResultsController<NSManagedObject> = {
        let request = NSFetchRequest<NSManagedObject>(entityName: TrackerEntity.name)
        request.sortDescriptors = [
            NSSortDescriptor(key: TrackerEntity.createdAt, ascending: true),
            NSSortDescriptor(key: TrackerEntity.title, ascending: true)
        ]
        return NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
    }()
    
    // MARK: - Initialization
    
    init(context: NSManagedObjectContext, categoryStore: TrackerCategoryStore) {
        self.context = context
        self.categoryStore = categoryStore
        super.init()
        bindCategoryStore()
        configureFetchedResultsController()
    }
    
    convenience init(context: NSManagedObjectContext) {
        self.init(
            context: context,
            categoryStore: TrackerCategoryStore(context: context, trackerStore: nil)
        )
    }
    
    // MARK: - Public Methods
    
    func fetchAll() -> [TrackerCategory] {
        categoryStore.fetchAllCategoryObjects().map { categoryObject in
            let name = (categoryObject.value(forKey: CategoryEntity.name) as? String) ?? ""
            let trackers = trackerObjects(from: categoryObject)
                .compactMap { trackerObject in
                    mapTracker(from: trackerObject)
                }
                .sorted { $0.createdAt < $1.createdAt }
            return TrackerCategory(name: name, trackers: trackers)
        }
    }
    
    func add(_ tracker: Tracker, toCategoryWithName categoryName: String) throws {
        let categoryObject = try categoryStore.fetchOrCreateCategory(withName: categoryName)
        let trackerObject = try fetchTrackerObject(by: tracker.id, in: context)
            ?? NSEntityDescription.insertNewObject(forEntityName: TrackerEntity.name, into: context)
        
        trackerObject.setValue(tracker.id, forKey: TrackerEntity.id)
        trackerObject.setValue(tracker.name, forKey: TrackerEntity.title)
        trackerObject.setValue(tracker.emoji, forKey: TrackerEntity.emoji)
        trackerObject.setValue(tracker.color, forKey: TrackerEntity.color)
        trackerObject.setValue(tracker.createdAt, forKey: TrackerEntity.createdAt)
        trackerObject.setValue(categoryObject, forKey: TrackerEntity.category)
        trackerObject.setValue(tracker.isPinned, forKey: TrackerEntity.isPinned)
        
        if let schedule = tracker.schedule {
            trackerObject.setValue(try encodeSchedule(schedule), forKey: TrackerEntity.schedule)
        } else {
            trackerObject.setValue(nil, forKey: TrackerEntity.schedule)
        }
        
        saveContext()
    }
    
    func fetchAllTrackers() throws -> [Tracker] {
        let request = NSFetchRequest<NSManagedObject>(entityName: TrackerEntity.name)
        let trackerObjects = try context.fetch(request)
        
        return trackerObjects.compactMap { mapTracker(from: $0) }
    }
    
    func togglePin(trackerId: UUID) throws {
        guard let trackerObject = try fetchTrackerObject(by: trackerId, in: context) else { return }
        let currentPinned = trackerObject.value(forKey: TrackerEntity.isPinned) as? Bool ?? false
        trackerObject.setValue(!currentPinned, forKey: TrackerEntity.isPinned)
        saveContext()
    }
    
    func deleteTracker(trackerId: UUID) throws {
        guard let trackerObject = try fetchTrackerObject(by: trackerId, in: context) else { return }
        context.delete(trackerObject)
        saveContext()
    }
    
    func fetchCategoryName(for trackerId: UUID) -> String? {
        guard let trackerObject = try? fetchTrackerObject(by: trackerId, in: context),
              let categoryObject = trackerObject.value(forKey: TrackerEntity.category) as? NSManagedObject,
              let categoryName = categoryObject.value(forKey: CategoryEntity.name) as? String
        else { return nil }
        return categoryName
    }
    
    // MARK: - Private Methods
    
    private func bindCategoryStore() {
        categoryStore.onDidUpdate = { [weak self] in
            self?.onDidUpdate?()
        }
    }
    
    private func configureFetchedResultsController() {
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            assertionFailure("Failed to fetch trackers: \(error)")
        }
    }
    
    private func fetchTrackerObject(by id: UUID, in context: NSManagedObjectContext) throws -> NSManagedObject? {
        let request = NSFetchRequest<NSManagedObject>(entityName: TrackerEntity.name)
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "%K == %@", TrackerEntity.id, id as CVarArg)
        return try context.fetch(request).first
    }
    
    private func mapTracker(from trackerObject: NSManagedObject) -> Tracker? {
        guard
            let id = trackerObject.value(forKey: TrackerEntity.id) as? UUID,
            let name = trackerObject.value(forKey: TrackerEntity.title) as? String,
            let emoji = trackerObject.value(forKey: TrackerEntity.emoji) as? String,
            let color = trackerObject.value(forKey: TrackerEntity.color) as? String,
            let createdAt = trackerObject.value(forKey: TrackerEntity.createdAt) as? Date
        else {
            return nil
        }
        
        var schedule: Schedule?
        if let scheduleData = trackerObject.value(forKey: TrackerEntity.schedule) as? Data {
            schedule = try? decodeSchedule(from: scheduleData)
        }
        
        let isPinned = trackerObject.value(forKey: TrackerEntity.isPinned) as? Bool ?? false
        
        return Tracker(
            id: id,
            name: name,
            color: color,
            emoji: emoji,
            schedule: schedule,
            createdAt: createdAt,
            isPinned: isPinned
        )
    }
    
    private func trackerObjects(from categoryObject: NSManagedObject) -> [NSManagedObject] {
        if let nsSet = categoryObject.value(forKey: CategoryEntity.trackers) as? NSSet {
            return nsSet.compactMap { $0 as? NSManagedObject }
        }
        if let set = categoryObject.value(forKey: CategoryEntity.trackers) as? Set<NSManagedObject> {
            return Array(set)
        }
        return []
    }
    
    private func saveContext() {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            assertionFailure("Failed to save context: \(error)")
            context.rollback()
        }
    }
    
    private func encodeSchedule(_ schedule: Schedule) throws -> Data {
        let encoder = JSONEncoder()
        return try encoder.encode(schedule)
    }
    
    private func decodeSchedule(from data: Data) throws -> Schedule {
        let decoder = JSONDecoder()
        return try decoder.decode(Schedule.self, from: data)
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension TrackerStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
        onDidUpdate?()
    }
}

