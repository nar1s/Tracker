//
//  TrackerCategoryStore.swift
//  Tracker
//
//  Created by Павел Кузнецов on 07.02.2026.
//

import CoreData
import UIKit

final class TrackerCategoryStore: NSObject {
    
    // MARK: - Constants
    
    private enum CategoryEntity {
        static let name = "TrackerCategoryCD"
        static let title = "name"
        static let trackers = "trackers"
    }
    
    // MARK: - Properties
    
    var onDidUpdate: (() -> Void)?
    
    private let context: NSManagedObjectContext
    private weak var trackerStore: TrackerStore?
    
    private lazy var fetchedResultsController: NSFetchedResultsController<NSManagedObject> = {
        let request = NSFetchRequest<NSManagedObject>(entityName: CategoryEntity.name)
        request.sortDescriptors = [
            NSSortDescriptor(key: CategoryEntity.title, ascending: true)
        ]
        return NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
    }()
    
    // MARK: - Initialization
    
    init(context: NSManagedObjectContext, trackerStore: TrackerStore?) {
        self.context = context
        self.trackerStore = trackerStore
        super.init()
        configureFetchedResultsController()
    }
    
    // MARK: - Public Methods
    
    func fetchAllCategoryObjects() -> [NSManagedObject] {
        let request = NSFetchRequest<NSManagedObject>(entityName: CategoryEntity.name)
        request.sortDescriptors = [NSSortDescriptor(key: CategoryEntity.title, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            assertionFailure("Failed to fetch categories: \(error)")
            return []
        }
    }
    
    func fetchOrCreateCategory(withName name: String) throws -> NSManagedObject {
        if let existingCategory = try fetchCategoryObject(by: name) {
            return existingCategory
        }
        
        return try addCategory(name: name)
    }
    
    func addCategory(name: String) throws -> NSManagedObject {
        let categoryObject = NSEntityDescription.insertNewObject(
            forEntityName: CategoryEntity.name,
            into: context
        )
        categoryObject.setValue(name, forKey: CategoryEntity.title)
        
        saveContext()
        return categoryObject
    }
    
    func fetchCategoryObject(by name: String) throws -> NSManagedObject? {
        let request = NSFetchRequest<NSManagedObject>(entityName: CategoryEntity.name)
        request.predicate = NSPredicate(format: "%K == %@", CategoryEntity.title, name)
        request.fetchLimit = 1
        
        return try context.fetch(request).first
    }
    
    func fetchCategoryNames() -> [String] {
        fetchAllCategoryObjects().compactMap {
            $0.value(forKey: CategoryEntity.title) as? String
        }
    }
    
    func renameCategory(from oldName: String, to newName: String) throws {
        guard let categoryObject = try fetchCategoryObject(by: oldName) else { return }
        categoryObject.setValue(newName, forKey: CategoryEntity.title)
        saveContext()
    }

    func deleteCategory(_ categoryName: String) throws {
        guard let categoryObject = try fetchCategoryObject(by: categoryName) else {
            return
        }
        
        context.delete(categoryObject)
        saveContext()
    }
    
    // MARK: - Private Methods
    
    private func configureFetchedResultsController() {
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            assertionFailure("Failed to fetch categories: \(error)")
        }
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

extension TrackerCategoryStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
        onDidUpdate?()
    }
}


