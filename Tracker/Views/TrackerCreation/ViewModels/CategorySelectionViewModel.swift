//
//  CategorySelectionViewModel.swift
//  Tracker
//
//  Created by Павел Кузнецов on 07.03.2026.
//

import Foundation

final class CategorySelectionViewModel {
    
    var onCategoriesUpdated: (([String]) -> Void)?
    var onCategorySelected: ((String) -> Void)?
    private(set) var categories: [String]
    private(set) var selectedCategory: String?
    private let store: TrackerCategoryStore
    
    init(categoryStore: TrackerCategoryStore, selectedCategory: String? = nil) {
        self.store = categoryStore
        self.categories = []
        self.selectedCategory = selectedCategory
        self.store.onDidUpdate = { [weak self] in
            self?.loadCategories()
        }
    }
    
    func loadCategories() {
        categories = store.fetchCategoryNames()
        onCategoriesUpdated?(categories)
    }
    
    func selectCategory(at index: Int) {
        selectedCategory = categories[index]
        onCategorySelected?(categories[index])
    }
    
    func numberOfCategories() -> Int {
        categories.count
    }
    
    func categoryName(at index: Int) -> String {
        categories[index]
    }
    
    func isCategorySelected(at index: Int) -> Bool {
        categories[index] == selectedCategory
    }
    
    func addCategory(name: String) {
        _ = try? store.addCategory(name: name)
    }
    
    func renameCategory(from oldName: String, to newName: String) {
        try? store.renameCategory(from: oldName, to: newName)
    }
    
    func deleteCategory(at index: Int) {
        let name = categories[index]
        try? store.deleteCategory(name)
    }
}
