//
//  TrackerRecordStore.swift
//  Tracker
//
//  Created by Павел Кузнецов on 07.02.2026.
//

import CoreData
import UIKit

final class TrackerRecordStore: NSObject {
    
    // MARK: - Constants
    
    private enum RecordEntity {
        static let name = "TrackerRecordCD"
        static let id = "id"
        static let date = "date"
    }
    
    // MARK: - Properties
    
    var onDidUpdate: (() -> Void)?
    
    private let context: NSManagedObjectContext
    
    private lazy var fetchedResultsController: NSFetchedResultsController<NSManagedObject> = {
        let request = NSFetchRequest<NSManagedObject>(entityName: RecordEntity.name)
        request.sortDescriptors = [
            NSSortDescriptor(key: RecordEntity.date, ascending: false)
        ]
        return NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
    }()
    
    // MARK: - Initialization
    
    init(context: NSManagedObjectContext) {
        self.context = context
        super.init()
        configureFetchedResultsController()
    }
    
    // MARK: - Public Methods
    
    func addRecord(_ record: TrackerRecord) throws {
        // Проверяем, существует ли уже запись
        if try recordExists(trackerId: record.trackerId, date: record.date) {
            return
        }
        
        let recordObject = NSEntityDescription.insertNewObject(
            forEntityName: RecordEntity.name,
            into: context
        )
        recordObject.setValue(record.trackerId, forKey: RecordEntity.id)
        recordObject.setValue(record.date, forKey: RecordEntity.date)
        
        saveContext()
    }
    
    func deleteRecord(_ record: TrackerRecord) throws {
        guard let recordObject = try fetchRecordObject(trackerId: record.trackerId, date: record.date) else {
            return
        }
        
        context.delete(recordObject)
        saveContext()
    }
    
    func recordExists(trackerId: UUID, date: Date) throws -> Bool {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            throw TrackerRecordStoreError.invalidDate
        }
        
        let request = NSFetchRequest<NSManagedObject>(entityName: RecordEntity.name)
        request.predicate = NSPredicate(
            format: "%K == %@ AND %K >= %@ AND %K < %@",
            RecordEntity.id, trackerId as CVarArg,
            RecordEntity.date, startOfDay as NSDate,
            RecordEntity.date, endOfDay as NSDate
        )
        request.fetchLimit = 1
        
        let count = try context.count(for: request)
        return count > 0
    }
    
    func fetchCompletionCount(for trackerId: UUID) throws -> Int {
        let request = NSFetchRequest<NSManagedObject>(entityName: RecordEntity.name)
        request.predicate = NSPredicate(format: "%K == %@", RecordEntity.id, trackerId as CVarArg)
        
        return try context.count(for: request)
    }
    
    func fetchRecords(for trackerId: UUID) throws -> [TrackerRecord] {
        let request = NSFetchRequest<NSManagedObject>(entityName: RecordEntity.name)
        request.predicate = NSPredicate(format: "%K == %@", RecordEntity.id, trackerId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: RecordEntity.date, ascending: false)]
        
        let recordObjects = try context.fetch(request)
        return recordObjects.compactMap { mapRecord(from: $0) }
    }
    
    func fetchAllRecords() throws -> [TrackerRecord] {
        let request = NSFetchRequest<NSManagedObject>(entityName: RecordEntity.name)
        request.sortDescriptors = [NSSortDescriptor(key: RecordEntity.date, ascending: false)]
        
        let recordObjects = try context.fetch(request)
        return recordObjects.compactMap { mapRecord(from: $0) }
    }
    
    // MARK: - Private Methods
    
    private func configureFetchedResultsController() {
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            assertionFailure("Failed to fetch records: \(error)")
        }
    }
    
    private func fetchRecordObject(trackerId: UUID, date: Date) throws -> NSManagedObject? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            throw TrackerRecordStoreError.invalidDate
        }
        
        let request = NSFetchRequest<NSManagedObject>(entityName: RecordEntity.name)
        request.predicate = NSPredicate(
            format: "%K == %@ AND %K >= %@ AND %K < %@",
            RecordEntity.id, trackerId as CVarArg,
            RecordEntity.date, startOfDay as NSDate,
            RecordEntity.date, endOfDay as NSDate
        )
        request.fetchLimit = 1
        
        return try context.fetch(request).first
    }
    
    private func mapRecord(from recordObject: NSManagedObject) -> TrackerRecord? {
        guard
            let trackerId = recordObject.value(forKey: RecordEntity.id) as? UUID,
            let date = recordObject.value(forKey: RecordEntity.date) as? Date
        else {
            return nil
        }
        
        return TrackerRecord(trackerId: trackerId, date: date)
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
}

// MARK: - NSFetchedResultsControllerDelegate

extension TrackerRecordStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
        onDidUpdate?()
    }
}

// MARK: - TrackerRecordStoreError

enum TrackerRecordStoreError: Error {
    case invalidDate
    case recordNotFound
}
