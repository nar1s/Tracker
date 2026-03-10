//
//  TrackerViewController.swift
//  Tracker
//
//  Created by Павел Кузнецов on 25.01.2026.
//

import UIKit

final class TrackersListViewController: UIViewController {
    
    // MARK: - Properties
    
    private var currentDate: Date = Date()
    private var categories: [TrackerCategory] = []
    private var visibleCategories: [TrackerCategory] = []
    private var searchText: String = ""
    private var currentFilter: TrackerFilter = .all
    
    private let dataStore = DataStore.shared
    
    // MARK: - UI
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy"
        return formatter
    }()
    
    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.textColor = .black
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = false
        return label
    }()
    
    private lazy var datePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .compact
        datePicker.date = currentDate
        
        datePicker.locale = Locale.current
        datePicker.calendar = Calendar(identifier: .gregorian)
        
        datePicker.addTarget(self, action: #selector(datePickerValueChanged(_:)), for: .valueChanged)
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.widthAnchor.constraint(equalToConstant: 100).isActive = true
        datePicker.heightAnchor.constraint(equalToConstant: 34).isActive = true
        return datePicker
    }()
    
    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.placeholder = NSLocalizedString("common.search", comment: "")
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchResultsUpdater = self
        return searchController
    }()
    
    private let emptyStateImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(resource: .placeholder)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("trackersList.emptyState", comment: "")
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor(resource: .ypBlack)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.contentInset.bottom = 70
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    private lazy var filterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("trackersList.filter", comment: ""), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
        button.setTitleColor(UIColor(resource: .ypWhite), for: .normal)
        button.backgroundColor = UIColor(resource: .ypBlue)
        button.layer.cornerRadius = 16
        button.layer.masksToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(filterButtonTapped), for: .touchUpInside)
        
        return button
    }()
    
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadCategories()
        updateVisibleCategories()
        updateEmptyState()
        collectionView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AnalyticsService.report(event: "open", params: ["screen": "Main"])
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        AnalyticsService.report(event: "close", params: ["screen": "Main"])
    }
    
    // MARK: - Private Methods
    
    private func loadCategories() {
        do {
            categories = try dataStore.fetchAllCategories()
        } catch {
            print("Failed to load categories: \(error)")
            categories = []
        }
    }
    
    private func updateVisibleCategories() {
        let calendar = Calendar.current
        let filterWeekday = calendar.component(.weekday, from: currentDate)
        let lowercasedSearch = searchText.lowercased()
        
        var pinnedTrackers: [Tracker] = []
        var regularCategories: [TrackerCategory] = []
        
        for category in categories {
            let filteredTrackers = category.trackers.filter { tracker in
                let matchesSchedule: Bool
                if let schedule = tracker.schedule {
                    matchesSchedule = schedule.weekdays.contains(where: { $0.rawValue == filterWeekday })
                } else {
                    matchesSchedule = true
                }
                
                let matchesSearch = lowercasedSearch.isEmpty || tracker.name.lowercased().contains(lowercasedSearch)
                
                let matchesFilter: Bool
                switch currentFilter {
                case .all:
                    matchesFilter = true
                case .today:
                    matchesFilter = true
                case .completed:
                    matchesFilter = isTrackerCompleted(trackerId: tracker.id, on: currentDate)
                case .uncompleted:
                    matchesFilter = !isTrackerCompleted(trackerId: tracker.id, on: currentDate)
                }
                
                return matchesSchedule && matchesSearch && matchesFilter
            }
            
            let pinned = filteredTrackers.filter { $0.isPinned }
            let unpinned = filteredTrackers.filter { !$0.isPinned }
            
            pinnedTrackers.append(contentsOf: pinned)
            
            if !unpinned.isEmpty {
                regularCategories.append(TrackerCategory(name: category.name, trackers: unpinned))
            }
        }
        
        var result: [TrackerCategory] = []
        if !pinnedTrackers.isEmpty {
            let pinnedCategoryName = NSLocalizedString("trackersList.pinned", comment: "")
            result.append(TrackerCategory(name: pinnedCategoryName, trackers: pinnedTrackers))
        }
        result.append(contentsOf: regularCategories)
        
        visibleCategories = result
    }
    
    private func updateEmptyState() {
        let hasVisibleTrackers = !visibleCategories.isEmpty
        
        emptyStateImageView.isHidden = hasVisibleTrackers
        emptyStateLabel.isHidden = hasVisibleTrackers
        collectionView.isHidden = !hasVisibleTrackers
        
        if !hasVisibleTrackers && (!searchText.isEmpty || currentFilter != .all) {
            emptyStateImageView.image = UIImage(resource: .findPlaceholder)
            emptyStateLabel.text = NSLocalizedString("trackersList.filterEmptyState", comment: "")
        } else {
            emptyStateImageView.image = UIImage(resource: .placeholder)
            emptyStateLabel.text = NSLocalizedString("trackersList.emptyState", comment: "")
        }
        
        updateFilterButtonVisibility()
    }
    
    private func updateFilterButtonVisibility() {
        let hasTrackersForDay = hasTrackersForCurrentDay()
        filterButton.isHidden = !hasTrackersForDay
    }
    
    private func hasTrackersForCurrentDay() -> Bool {
        let calendar = Calendar.current
        let filterWeekday = calendar.component(.weekday, from: currentDate)
        
        for category in categories {
            for tracker in category.trackers {
                if let schedule = tracker.schedule {
                    if schedule.weekdays.contains(where: { $0.rawValue == filterWeekday }) {
                        return true
                    }
                } else {
                    return true
                }
            }
        }
        return false
    }
    
    private func addTracker(_ tracker: Tracker, to categoryTitle: String) {
        do {
            try dataStore.addTracker(tracker, to: categoryTitle)
            loadCategories()
        } catch {
            print("Failed to add tracker: \(error)")
        }
    }
    
    private func completeTracker(with trackerId: UUID, on date: Date) {
        do {
            try dataStore.completeTracker(id: trackerId, date: date)
        } catch {
            print("Failed to complete tracker: \(error)")
        }
    }
    
    private func uncompleteTracker(with trackerId: UUID, on date: Date) {
        do {
            try dataStore.uncompleteTracker(id: trackerId, date: date)
        } catch {
            print("Failed to uncomplete tracker: \(error)")
        }
    }
    
    private func isTrackerCompleted(trackerId: UUID, on date: Date) -> Bool {
        do {
            return try dataStore.isTrackerCompleted(id: trackerId, date: date)
        } catch {
            print("Failed to check tracker completion: \(error)")
            return false
        }
    }
    
    private func completionCount(for trackerId: UUID) -> Int {
        do {
            return try dataStore.getCompletionCount(for: trackerId)
        } catch {
            print("Failed to get completion count: \(error)")
            return 0
        }
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor(resource: .ypWhite)
        
        setupNavigationBar()
        
        view.addSubview(emptyStateImageView)
        view.addSubview(emptyStateLabel)
        view.addSubview(collectionView)
        view.addSubview(filterButton)
        
        collectionView.register(TrackerCollectionViewCell.self, forCellWithReuseIdentifier: "TrackerCell")
        collectionView.register(TrackersSectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "header")
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        NSLayoutConstraint.activate([
            emptyStateImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateImageView.widthAnchor.constraint(equalToConstant: 80),
            emptyStateImageView.heightAnchor.constraint(equalToConstant: 80),
            
            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateImageView.bottomAnchor, constant: 8),
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            filterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            filterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            filterButton.widthAnchor.constraint(equalToConstant: 114),
            filterButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupNavigationBar() {
        navigationItem.title = NSLocalizedString("trackersList.title", comment: "")
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.largeTitleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 34, weight: .bold),
            .foregroundColor: UIColor(resource: .ypBlack)
        ]
        
        guard let navigationBar = navigationController?.navigationBar else { return }
        
        let addTrackerButton = UIButton(type: .system)
        addTrackerButton.setImage(UIImage(resource: .addTracker), for: .normal)
        addTrackerButton.tintColor = UIColor(resource: .ypBlack)
        addTrackerButton.addTarget(self, action: #selector(addTrackerTapped), for: .touchUpInside)
        addTrackerButton.translatesAutoresizingMaskIntoConstraints = false
        
        navigationBar.addSubview(addTrackerButton)
        
        NSLayoutConstraint.activate([
            addTrackerButton.leadingAnchor.constraint(equalTo: navigationBar.leadingAnchor, constant: 6),
            addTrackerButton.widthAnchor.constraint(equalToConstant: 42),
            addTrackerButton.heightAnchor.constraint(equalToConstant: 42)
        ])
        
        let datePickerContainer = UIView()
        datePickerContainer.translatesAutoresizingMaskIntoConstraints = false
        
        datePickerContainer.addSubview(datePicker)
        datePickerContainer.addSubview(dateLabel)
        
        NSLayoutConstraint.activate([
            datePickerContainer.widthAnchor.constraint(equalToConstant: 77),
            datePickerContainer.heightAnchor.constraint(equalToConstant: 34),
            
            datePicker.leadingAnchor.constraint(equalTo: datePickerContainer.leadingAnchor),
            datePicker.trailingAnchor.constraint(equalTo: datePickerContainer.trailingAnchor),
            datePicker.topAnchor.constraint(equalTo: datePickerContainer.topAnchor),
            datePicker.bottomAnchor.constraint(equalTo: datePickerContainer.bottomAnchor),
            
            dateLabel.leadingAnchor.constraint(equalTo: datePickerContainer.leadingAnchor),
            dateLabel.trailingAnchor.constraint(equalTo: datePickerContainer.trailingAnchor),
            dateLabel.topAnchor.constraint(equalTo: datePickerContainer.topAnchor),
            dateLabel.bottomAnchor.constraint(equalTo: datePickerContainer.bottomAnchor)
        ])
        
        dateLabel.backgroundColor = UIColor(resource: .ypDatePicker)
        dateLabel.layer.cornerRadius = 8
        dateLabel.clipsToBounds = true
        dateLabel.text = dateFormatter.string(from: currentDate)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: datePickerContainer)
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    // MARK: - Actions
    
    @objc private func addTrackerTapped() {
        AnalyticsService.report(event: "click", params: ["screen": "Main", "item": "add_track"])
        let vc = NewTrackerViewController()
        vc.delegate = self
        vc.modalPresentationStyle = .pageSheet
        present(vc, animated: true)
    }
    
    @objc private func datePickerValueChanged(_ sender: UIDatePicker) {
        currentDate = sender.date
        dateLabel.text = dateFormatter.string(from: currentDate)
        loadCategories()
        updateVisibleCategories()
        updateEmptyState()
        collectionView.reloadData()
    }
    
    @objc private func filterButtonTapped() {
        AnalyticsService.report(event: "click", params: ["screen": "Main", "item": "filter"])
        let vc = FilterViewController(selectedFilter: currentFilter)
        vc.delegate = self
        vc.modalPresentationStyle = .pageSheet
        present(vc, animated: true)
    }
}

// MARK: - UICollectionViewDataSource

extension TrackersListViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return visibleCategories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return visibleCategories[section].trackers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TrackerCell", for: indexPath) as? TrackerCollectionViewCell
        
        let tracker = visibleCategories[indexPath.section].trackers[indexPath.row]
        let isCompleted = isTrackerCompleted(trackerId: tracker.id, on: currentDate)
        let completedDays = completionCount(for: tracker.id)
        
        cell?.configure(with: tracker, isCompleted: isCompleted, completedDays: completedDays)
        
        let isFutureDate = Calendar.current.startOfDay(for: currentDate) > Calendar.current.startOfDay(for: Date())
        cell?.setCompleteButtonEnabled(!isFutureDate)
        
        cell?.onCompleteButtonTapped = { [weak self] in
            guard let self = self else { return }
            self.handleTrackerCompletion(at: indexPath)
        }
        
        guard let cell else {
            fatalError("Unwrapped cell is nil")
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }
        
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: "header",
            for: indexPath
        ) as! TrackersSectionHeader
        
        header.titleLabel.text = visibleCategories[indexPath.section].name
        
        return header
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension TrackersListViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let paddingSpace: CGFloat = 16 + 9 + 16
        let availableWidth = collectionView.bounds.width - paddingSpace
        let widthPerItem = availableWidth / 2
        return CGSize(width: widthPerItem, height: 148)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 9
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 12, left: 16, bottom: 16, right: 16)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 20)
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let tracker = visibleCategories[indexPath.section].trackers[indexPath.row]
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            guard let self = self else { return nil }
            
            let pinTitle = tracker.isPinned
            ? NSLocalizedString("trackersList.unpin", comment: "")
            : NSLocalizedString("trackersList.pin", comment: "")
            
            let pinAction = UIAction(title: pinTitle) { [weak self] _ in
                self?.togglePin(for: tracker)
            }
            
            let editAction = UIAction(title: NSLocalizedString("common.edit", comment: "")) { [weak self] _ in
                self?.editTracker(tracker)
            }
            
            let deleteAction = UIAction(
                title: NSLocalizedString("common.delete", comment: ""),
                attributes: .destructive
            ) { [weak self] _ in
                self?.showDeleteConfirmation(for: tracker)
            }
            
            return UIMenu(children: [pinAction, editAction, deleteAction])
        }
    }
}

// MARK: - Tracker Completion Handling

private extension TrackersListViewController {
    
    func handleTrackerCompletion(at indexPath: IndexPath) {
        AnalyticsService.report(event: "click", params: ["screen": "Main", "item": "track"])
        let tracker = visibleCategories[indexPath.section].trackers[indexPath.row]
        
        let calendar = Calendar.current
        let startOfCurrentDate = calendar.startOfDay(for: currentDate)
        let startOfToday = calendar.startOfDay(for: Date())
        
        guard startOfCurrentDate <= startOfToday else {
            return
        }
        
        if isTrackerCompleted(trackerId: tracker.id, on: currentDate) {
            uncompleteTracker(with: tracker.id, on: currentDate)
        } else {
            completeTracker(with: tracker.id, on: currentDate)
        }
        
        if currentFilter == .completed || currentFilter == .uncompleted {
            updateVisibleCategories()
            updateEmptyState()
            collectionView.reloadData()
        } else {
            collectionView.reloadItems(at: [indexPath])
        }
    }
    
    func togglePin(for tracker: Tracker) {
        do {
            try dataStore.togglePin(trackerId: tracker.id)
            loadCategories()
            updateVisibleCategories()
            updateEmptyState()
            collectionView.reloadData()
        } catch {
            print("Failed to toggle pin: \(error)")
        }
    }
    
    func editTracker(_ tracker: Tracker) {
        AnalyticsService.report(event: "click", params: ["screen": "Main", "item": "edit"])
        let categoryName = dataStore.fetchCategoryName(for: tracker.id) ?? ""
        let trackerType: TrackerType = tracker.schedule != nil ? .habit : .irregular
        let vc = CreateTrackerViewController(trackerType: trackerType, editingTracker: tracker, editingCategory: categoryName)
        vc.delegate = self
        vc.modalPresentationStyle = .pageSheet
        present(vc, animated: true)
    }
    
    func showDeleteConfirmation(for tracker: Tracker) {
        AnalyticsService.report(event: "click", params: ["screen": "Main", "item": "delete"])
        let alert = UIAlertController(
            title: nil,
            message: NSLocalizedString("trackersList.deleteConfirmation", comment: ""),
            preferredStyle: .actionSheet
        )
        
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("common.delete", comment: ""),
            style: .destructive
        ) { [weak self] _ in
            self?.deleteTracker(tracker)
        })
        
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("common.cancel", comment: ""),
            style: .cancel
        ))
        
        present(alert, animated: true)
    }
    
    func deleteTracker(_ tracker: Tracker) {
        do {
            try dataStore.deleteTracker(trackerId: tracker.id)
            loadCategories()
            updateVisibleCategories()
            updateEmptyState()
            collectionView.reloadData()
        } catch {
            print("Failed to delete tracker: \(error)")
        }
    }
}

// MARK: - CreateTrackerDelegate
extension TrackersListViewController: CreateTrackerDelegate {
    func didCreateTracker(_ tracker: Tracker, category: String) {
        loadCategories()
        updateVisibleCategories()
        updateEmptyState()
        collectionView.reloadData()
    }
}

// MARK: - FilterViewControllerDelegate

extension TrackersListViewController: FilterViewControllerDelegate {
    func didSelectFilter(_ filter: TrackerFilter) {
        currentFilter = filter
        
        if filter == .today {
            currentDate = Date()
            datePicker.date = currentDate
            dateLabel.text = dateFormatter.string(from: currentDate)
        }
        
        loadCategories()
        updateVisibleCategories()
        updateEmptyState()
        collectionView.reloadData()
    }
}

extension TrackersListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        searchText = searchController.searchBar.text ?? ""
        updateVisibleCategories()
        updateEmptyState()
        collectionView.reloadData()
    }
}
