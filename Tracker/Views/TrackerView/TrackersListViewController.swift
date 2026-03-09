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
        return searchController
    }()
    
    private let emptyStateImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(resource: .placeholder).withRenderingMode(.alwaysOriginal)
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
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
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
        
        visibleCategories = categories.compactMap { category in
            let filteredTrackers = category.trackers.filter { tracker in
                guard let schedule = tracker.schedule else {
                    return true
                }
                
                return schedule.weekdays.contains(where: { $0.rawValue == filterWeekday })
            }
            
            if filteredTrackers.isEmpty {
                return nil
            }
            
            return TrackerCategory(name: category.name, trackers: filteredTrackers)
        }
    }
    
    private func updateEmptyState() {
        let hasVisibleTrackers = !visibleCategories.isEmpty
        
        emptyStateImageView.isHidden = hasVisibleTrackers
        emptyStateLabel.isHidden = hasVisibleTrackers
        collectionView.isHidden = !hasVisibleTrackers
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
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
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
}

// MARK: - Tracker Completion Handling

private extension TrackersListViewController {
    
    func handleTrackerCompletion(at indexPath: IndexPath) {
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
        
        collectionView.reloadItems(at: [indexPath])
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

