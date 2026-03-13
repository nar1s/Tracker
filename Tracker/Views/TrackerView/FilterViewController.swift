//
//  FilterViewController.swift
//  Tracker
//
//  Created by Павел Кузнецов on 09.03.2026.
//

import UIKit

enum TrackerFilter: Int, CaseIterable {
    case all = 0
    case today
    case completed
    case uncompleted

    var title: String {
        switch self {
        case .all:
            return NSLocalizedString("filter.allTrackers", comment: "")
        case .today:
            return NSLocalizedString("filter.today", comment: "")
        case .completed:
            return NSLocalizedString("filter.completed", comment: "")
        case .uncompleted:
            return NSLocalizedString("filter.uncompleted", comment: "")
        }
    }
}

protocol FilterViewControllerDelegate: AnyObject {
    func didSelectFilter(_ filter: TrackerFilter)
}

final class FilterViewController: UIViewController {

    // MARK: - Properties

    weak var delegate: FilterViewControllerDelegate?
    private var selectedFilter: TrackerFilter

    // MARK: - UI Elements

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Filters.title", comment: "")
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor(resource: .ypBlack)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = UIColor(resource: .ypWhite)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.separatorColor = UIColor(resource: .ypGray)
        tableView.isScrollEnabled = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(FilterCell.self, forCellReuseIdentifier: "FilterCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    // MARK: - Initialization

    init(selectedFilter: TrackerFilter) {
        self.selectedFilter = selectedFilter
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
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = UIColor(resource: .ypWhite)

        view.addSubview(titleLabel)
        view.addSubview(tableView)

        setupConstraints()
    }

    private func setupConstraints() {
        let tableHeight = CGFloat(TrackerFilter.allCases.count) * 75

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 27),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.heightAnchor.constraint(equalToConstant: tableHeight)
        ])
    }
}

// MARK: - UITableViewDataSource

extension FilterViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return TrackerFilter.allCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FilterCell", for: indexPath) as? FilterCell

        let filter = TrackerFilter.allCases[indexPath.row]
        let isSelected = filter == selectedFilter && filter != .all && filter != .today

        cell?.configure(title: filter.title, isSelected: isSelected)

        if indexPath.row == 0 {
            cell?.layer.cornerRadius = 16
            cell?.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            cell?.clipsToBounds = true
        } else if indexPath.row == TrackerFilter.allCases.count - 1 {
            cell?.layer.cornerRadius = 16
            cell?.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            cell?.clipsToBounds = true
            cell?.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
        } else {
            cell?.layer.cornerRadius = 0
        }

        guard let cell else {
            assertionFailure("Unwrapped cell is nil")
            return UITableViewCell()
        }
        return cell
    }
}

// MARK: - UITableViewDelegate

extension FilterViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let filter = TrackerFilter.allCases[indexPath.row]
        selectedFilter = filter
        delegate?.didSelectFilter(filter)
        dismiss(animated: true)
    }
}

// MARK: - Custom Cell

private final class FilterCell: UITableViewCell {

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.textColor = UIColor(resource: .ypBlack)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let checkmarkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "checkmark")
        imageView.tintColor = UIColor(resource: .ypBlue)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true
        return imageView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = UIColor(resource: .ypBackground)
        selectionStyle = .none

        contentView.addSubview(titleLabel)
        contentView.addSubview(checkmarkImageView)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            checkmarkImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            checkmarkImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 24),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func configure(title: String, isSelected: Bool) {
        titleLabel.text = title
        checkmarkImageView.isHidden = !isSelected
    }
}
