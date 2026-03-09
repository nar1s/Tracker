//
//  CreateTrackerViewController.swift
//  Tracker
//
//  Created by Павел Кузнецов on 27.01.2026.
//

import UIKit

final class CreateTrackerViewController: UIViewController {
    
    // MARK: - Properties
    
    private let trackerType: TrackerType
    private let dataStore: DataStore
    private let editingTracker: Tracker?
    private let editingCategory: String?
    
    private var trackerName: String = "" {
        didSet { updateCreateButtonState() }
    }
    
    var selectedCategory: String = "" {
        didSet {
            settingsTableView.reloadData()
            updateCreateButtonState()
        }
    }
    
    var selectedSchedule: Set<Weekday> = [] {
        didSet {
            settingsTableView.reloadData()
            updateCreateButtonState()
        }
    }
    
    var selectedColor: String = "" {
        didSet { updateCreateButtonState() }
    }

    var selectedEmoji: String = "" {
        didSet { updateCreateButtonState() }
    }
    
    private let maxNameLength = 38
    let emojis: [String] = [
        "🙂", "😻", "🌺", "🐶", "❤️", "😱",
        "😇", "😡", "🥶", "🤔", "🙌", "🍔",
        "🥦", "🏓", "🥇", "🎸", "🏝", "😪"
    ]
    
    let colors: [String] = TrackerColor.allCases.map { $0.colorName }
    
    weak var delegate: CreateTrackerDelegate?
    
    private var errorLabelTimer: Timer?
    private var contentStackView: UIStackView?
    
    // MARK: - Data Sources
    
    enum SettingsRow {
        case category
        case schedule
        
        var title: String {
            switch self {
            case .category: return NSLocalizedString("createTracker.category", comment: "")
            case .schedule: return NSLocalizedString("createTracker.schedule", comment: "")
            }
        }
    }
    
    var settingsRows: [SettingsRow] {
        trackerType == .habit ? [.category, .schedule] : [.category]
    }
    
    // MARK: - UI Elements
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceVertical = true
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = editingTracker != nil
            ? NSLocalizedString("createTracker.edit.title", comment: "")
            : trackerType.title
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor(resource: .ypBlack)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var daysCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = UIColor(resource: .ypBlack)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    private lazy var nameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = NSLocalizedString("createTracker.namePlaceholder", comment: "")
        textField.font = .systemFont(ofSize: 17, weight: .regular)
        textField.backgroundColor = UIColor(resource: .ypBackground)
        textField.layer.cornerRadius = 16
        textField.layer.masksToBounds = true
        textField.clearButtonMode = .whileEditing
        textField.returnKeyType = .done
        textField.delegate = self
        textField.addTarget(self, action: #selector(nameTextFieldChanged), for: .editingChanged)
        
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: textField.frame.height))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: textField.frame.height))
        textField.rightViewMode = .always
        
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let errorLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("createTracker.nameLengthError", comment: "")
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.textColor = UIColor(resource: .ypRed)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    private lazy var settingsTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = UIColor(resource: .ypBackground)
        tableView.layer.cornerRadius = 16
        tableView.layer.masksToBounds = true
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.separatorColor = UIColor(resource: .ypGray)
        tableView.isScrollEnabled = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SubtitleTableViewCell.self, forCellReuseIdentifier: "SettingsCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("createTracker.emoji", comment: "")
        label.font = .systemFont(ofSize: 19, weight: .bold)
        label.textColor = UIColor(resource: .ypBlack)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var emojiLabelContainer: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(emojiLabel)
        
        NSLayoutConstraint.activate([
            emojiLabel.topAnchor.constraint(equalTo: container.topAnchor),
            emojiLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            emojiLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            emojiLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }()
    
    lazy var emojiCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 5
        layout.minimumLineSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 24, left: 0, bottom: 24, right: 0)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(EmojiCollectionViewCell.self, forCellWithReuseIdentifier: "EmojiCell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    private let colorLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("createTracker.color", comment: "")
        label.font = .systemFont(ofSize: 19, weight: .bold)
        label.textColor = UIColor(resource: .ypBlack)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var colorLabelContainer: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(colorLabel)
        
        NSLayoutConstraint.activate([
            colorLabel.topAnchor.constraint(equalTo: container.topAnchor),
            colorLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            colorLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            colorLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }()
    
    lazy var colorCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 5
        layout.minimumLineSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 24, left: 0, bottom: 24, right: 0)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ColorCollectionViewCell.self, forCellWithReuseIdentifier: "ColorCell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("common.cancel", comment: ""), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(UIColor(resource: .ypRed), for: .normal)
        button.backgroundColor = UIColor(resource: .ypWhite)
        button.layer.cornerRadius = 16
        button.layer.masksToBounds = true
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(resource: .ypRed).cgColor
        button.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var createButton: UIButton = {
        let button = UIButton(type: .system)
        let buttonTitle = editingTracker != nil
            ? NSLocalizedString("common.save", comment: "")
            : NSLocalizedString("common.create", comment: "")
        button.setTitle(buttonTitle, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(UIColor(resource: .ypWhite), for: .normal)
        button.backgroundColor = UIColor(resource: .ypGray)
        button.layer.cornerRadius = 16
        button.layer.masksToBounds = true
        button.isEnabled = false
        button.addTarget(self, action: #selector(createButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var buttonsStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [cancelButton, createButton])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // MARK: - Initialization
    
    init(trackerType: TrackerType, dataStore: DataStore = .shared, editingTracker: Tracker? = nil, editingCategory: String? = nil) {
        self.trackerType = trackerType
        self.dataStore = dataStore
        self.editingTracker = editingTracker
        self.editingCategory = editingCategory
        self.selectedColor = ""
        self.selectedEmoji = ""
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardObservers()
        
        if let tracker = editingTracker {
            prefillForEditing(tracker)
        }
    }
    
    deinit {
        removeKeyboardObservers()
        errorLabelTimer?.invalidate()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor(resource: .ypWhite)
        
        view.addSubview(titleLabel)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        view.addSubview(buttonsStackView)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        let tableHeight: CGFloat = CGFloat(settingsRows.count * 75)
        
        let stackView = UIStackView(arrangedSubviews: [
            daysCountLabel,
            nameTextField,
            errorLabel,
            settingsTableView,
            emojiLabelContainer,
            emojiCollectionView,
            colorLabelContainer,
            colorCollectionView
        ])
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.setCustomSpacing(40, after: daysCountLabel)
        stackView.setCustomSpacing(24, after: nameTextField)
        stackView.setCustomSpacing(0, after: errorLabel)
        stackView.setCustomSpacing(32, after: settingsTableView)
        stackView.setCustomSpacing(16, after: emojiCollectionView)
        
        contentView.addSubview(stackView)
        self.contentStackView = stackView
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 27),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: buttonsStackView.topAnchor, constant: -16),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            
            nameTextField.heightAnchor.constraint(equalToConstant: 75),
            settingsTableView.heightAnchor.constraint(equalToConstant: tableHeight),
            emojiCollectionView.heightAnchor.constraint(equalToConstant: 204),
            colorCollectionView.heightAnchor.constraint(equalToConstant: 204),
            
            buttonsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            buttonsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            buttonsStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            buttonsStackView.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    // MARK: - Keyboard Handling
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        let keyboardHeight = keyboardFrame.height
        scrollView.contentInset.bottom = keyboardHeight
        scrollView.verticalScrollIndicatorInsets.bottom = keyboardHeight
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Actions
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func createButtonTapped() {
        guard isFormValid else { return }
        
        let schedule: Schedule? = trackerType == .habit ? Schedule(weekdays: selectedSchedule) : nil
        let trackerId = editingTracker?.id ?? UUID()
        let isPinned = editingTracker?.isPinned ?? false
        
        let tracker = Tracker(
            id: trackerId,
            name: trackerName,
            color: selectedColor,
            emoji: selectedEmoji,
            schedule: schedule,
            isPinned: isPinned
        )
        
        do {
            if editingTracker != nil {
                try dataStore.updateTracker(tracker, in: selectedCategory)
            } else {
                try dataStore.addTracker(tracker, to: selectedCategory)
            }
            
            if editingTracker != nil {
                dismiss(animated: true) {
                    self.delegate?.didCreateTracker(tracker, category: self.selectedCategory)
                }
            } else {
                view.window?.rootViewController?.dismiss(animated: true) {
                    self.delegate?.didCreateTracker(tracker, category: self.selectedCategory)
                }
            }
        } catch {
            showError(error)
        }
    }
    
    @objc private func nameTextFieldChanged() {
        guard let text = nameTextField.text else {
            trackerName = ""
            hideErrorLabel()
            return
        }
        
        if text.count > maxNameLength {
            let truncated = String(text.prefix(38))
            nameTextField.text = truncated
            trackerName = truncated
            
            showErrorLabel()
        } else {
            hideErrorLabel()
            trackerName = text
        }
    }
    
    private func showErrorLabel() {
        guard let stackView = contentStackView else { return }
        
        errorLabel.isHidden = false
        errorLabelTimer?.invalidate()
        
        stackView.setCustomSpacing(8, after: nameTextField)
        stackView.setCustomSpacing(24, after: errorLabel)
    }
    
    private func hideErrorLabel() {
        guard let stackView = contentStackView else { return }
        
        errorLabel.isHidden = true
        
        stackView.setCustomSpacing(24, after: nameTextField)
        stackView.setCustomSpacing(0, after: errorLabel)
    }
    
    // MARK: - Validation
    
    private var isFormValid: Bool {
        !trackerName.isEmpty &&
        !selectedCategory.isEmpty &&
        !selectedEmoji.isEmpty &&
        !selectedColor.isEmpty &&
        (trackerType == .irregular || !selectedSchedule.isEmpty)
    }
    
    private func updateCreateButtonState() {
        let isValid = isFormValid
        createButton.isEnabled = isValid
        createButton.backgroundColor = isValid ? UIColor(resource: .ypBlack) : UIColor(resource: .ypGray)
    }
    
    // MARK: - Navigation
    
    func openCategorySelection() {
        let viewModel = CategorySelectionViewModel(
            categoryStore: dataStore.categoryStore,
            selectedCategory: selectedCategory.isEmpty ? nil : selectedCategory
        )
        let vc = CategorySelectionViewController(viewModel: viewModel)
        vc.delegate = self
        vc.modalPresentationStyle = .pageSheet
        present(vc, animated: true)
    }
    
    func openScheduleSelection() {
        let vc = ScheduleSelectionViewController(selectedDays: selectedSchedule)
        vc.delegate = self
        vc.modalPresentationStyle = .pageSheet
        present(vc, animated: true)
    }
    
    // MARK: - Helper Methods
    
    func scheduleDescription() -> String? {
        guard !selectedSchedule.isEmpty else { return nil }
        
        if selectedSchedule.count == 7 {
            return NSLocalizedString("createTracker.everyDay", comment: "")
        }
        
        let sortedDays = selectedSchedule.sorted { $0.rawValue < $1.rawValue }
        return sortedDays.map { $0.shortName }.joined(separator: ", ")
    }
    
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: NSLocalizedString("common.error", comment: ""),
            message: String(format: NSLocalizedString("createTracker.error", comment: ""), error.localizedDescription),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("common.ok", comment: ""), style: .default))
        present(alert, animated: true)
    }
    
    private func prefillForEditing(_ tracker: Tracker) {
        trackerName = tracker.name
        nameTextField.text = tracker.name
        selectedEmoji = tracker.emoji
        selectedColor = tracker.color
        
        if let category = editingCategory {
            selectedCategory = category
        }
        
        if let schedule = tracker.schedule {
            selectedSchedule = schedule.weekdays
        }
        
        let completedDays = (try? dataStore.getCompletionCount(for: tracker.id)) ?? 0
        daysCountLabel.text = String.localizedStringWithFormat(
            NSLocalizedString("daysCount", comment: ""),
            completedDays
        )
        daysCountLabel.isHidden = false
        
        emojiCollectionView.reloadData()
        colorCollectionView.reloadData()
        settingsTableView.reloadData()
        updateCreateButtonState()
    }
}

