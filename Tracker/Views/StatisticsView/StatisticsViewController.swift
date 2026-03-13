//
//  StatisticsViewController.swift
//  Tracker
//
//  Created by Павел Кузнецов on 25.01.2026.
//

import UIKit

final class StatisticsViewController: UIViewController {
    
    // MARK: - Types

    private struct StatisticsItem {
        let value: Int
        let title: String
    }

    // MARK: - Properties

    private let dataStore = DataStore.shared
    private var statisticsItems: [StatisticsItem] = []

    // MARK: - UI Elements

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Statistics.title", comment: "")
        label.font = .systemFont(ofSize: 34, weight: .bold)
        label.textColor = UIColor(resource: .ypBlack)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(StatisticsCell.self, forCellReuseIdentifier: StatisticsCell.reuseIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    private let placeholderStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isHidden = true
        return stack
    }()

    private let placeholderImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(resource: .statisticsPlaceholder)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Statistics.placeholder", comment: "")
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor(resource: .ypBlack)
        label.textAlignment = .center
        return label
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(resource: .ypWhite)
        setupUI()
        subscribeToUpdates()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadStatistics()
    }

    // MARK: - Setup

    private func setupUI() {
        placeholderStackView.addArrangedSubview(placeholderImageView)
        placeholderStackView.addArrangedSubview(placeholderLabel)

        view.addSubview(titleLabel)
        view.addSubview(tableView)
        view.addSubview(placeholderStackView)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 44),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 77),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            placeholderStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholderStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    private func subscribeToUpdates() {
        dataStore.recordStore.onDidUpdate = { [weak self] in
            self?.reloadStatistics()
        }
    }

    // MARK: - Statistics Calculation

    private func reloadStatistics() {
        guard
            let allRecords = try? dataStore.fetchAllRecords()
        else {
            statisticsItems = []
            updatePlaceholderVisibility()
            return
        }

        let completedTrackers = allRecords.count
        let averageValue = calculateAveragePerDay(records: allRecords)

        statisticsItems = [
            StatisticsItem(value: completedTrackers, title: NSLocalizedString("Statistics.completedTrackers", comment: "")),
            StatisticsItem(value: averageValue, title: NSLocalizedString("Statistics.averageValue", comment: ""))
        ]

        tableView.reloadData()
        updatePlaceholderVisibility()
    }

    private func calculateAveragePerDay(records: [TrackerRecord]) -> Int {
        guard !records.isEmpty else { return 0 }
        let calendar = Calendar.current
        let uniqueDays = Set(records.map { calendar.startOfDay(for: $0.date) })
        return records.count / uniqueDays.count
    }

    // MARK: - Helpers

    private func updatePlaceholderVisibility() {
        let hasData = statisticsItems.contains { $0.value > 0 }
        tableView.isHidden = !hasData
        placeholderStackView.isHidden = hasData
    }
}

// MARK: - UITableViewDataSource

extension StatisticsViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        statisticsItems.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: StatisticsCell.reuseIdentifier,
            for: indexPath
        ) as? StatisticsCell else {
            return UITableViewCell()
        }
        let item = statisticsItems[indexPath.section]
        cell.configure(value: "\(item.value)", description: item.title)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension StatisticsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        90
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        UIView()
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        12
    }
}

// MARK: - StatisticsCell

private final class StatisticsCell: UITableViewCell {

    static let reuseIdentifier = "StatisticsCell"

    // MARK: - UI Elements

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 34, weight: .bold)
        label.textColor = UIColor(resource: .ypBlack)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor(resource: .ypBlack)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(valueLabel)
        contentView.addSubview(descriptionLabel)

        NSLayoutConstraint.activate([
            valueLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            valueLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            valueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),

            descriptionLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 7),
            descriptionLabel.leadingAnchor.constraint(equalTo: valueLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: valueLabel.trailingAnchor),
            descriptionLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12),
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.addGradientBorder(
            colors: [.systemRed, .green, .systemBlue],
            lineWidth: 1,
            cornerRadius: 16
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    // MARK: - Configuration

    func configure(value: String, description: String) {
        valueLabel.text = value
        descriptionLabel.text = description
    }
}

private extension UIView {
    func addGradientBorder(
        colors: [UIColor] = [.systemRed, .green, .systemBlue],
        lineWidth: CGFloat = 1,
        cornerRadius: CGFloat = 16
    ) {
        layer.sublayers?.removeAll(where: { $0.name == "GradientBorderLayer" })
        layer.cornerRadius = cornerRadius

        let gradientLayer = CAGradientLayer()
        gradientLayer.name = "GradientBorderLayer"
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = cornerRadius
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = CGPoint(x: 0, y: 1)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0)

        let shapeLayer = CAShapeLayer()
        shapeLayer.lineWidth = lineWidth
        shapeLayer.path = UIBezierPath(
            roundedRect: bounds.insetBy(dx: lineWidth / 2, dy: lineWidth / 2),
            cornerRadius: cornerRadius
        ).cgPath
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.black.cgColor

        gradientLayer.mask = shapeLayer
        layer.addSublayer(gradientLayer)
    }
}
