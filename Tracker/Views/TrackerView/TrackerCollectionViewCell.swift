//
//  TrackerCollectionViewCell.swift
//  Tracker
//
//  Created by Павел Кузнецов on 27.01.2026.
//

import UIKit

final class TrackerCollectionViewCell: UICollectionViewCell {
    
    // MARK: - Properties
    
    var onCompleteButtonTapped: (() -> Void)?
    
    // MARK: - UI Components
    
    private let coloredContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        label.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        label.layer.cornerRadius = 12
        label.layer.masksToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let daysCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor(resource: .ypBlack)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var completeButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 17
        button.layer.masksToBounds = true
        button.tintColor = .white
        button.addTarget(self, action: #selector(completeButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        contentView.backgroundColor = .clear
        
        contentView.addSubview(coloredContainerView)
        contentView.addSubview(daysCountLabel)
        contentView.addSubview(completeButton)
        
        coloredContainerView.addSubview(emojiLabel)
        coloredContainerView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            coloredContainerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            coloredContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            coloredContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            coloredContainerView.heightAnchor.constraint(equalToConstant: 90),
            
            emojiLabel.topAnchor.constraint(equalTo: coloredContainerView.topAnchor, constant: 12),
            emojiLabel.leadingAnchor.constraint(equalTo: coloredContainerView.leadingAnchor, constant: 12),
            emojiLabel.widthAnchor.constraint(equalToConstant: 24),
            emojiLabel.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.leadingAnchor.constraint(equalTo: coloredContainerView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: coloredContainerView.trailingAnchor, constant: -12),
            titleLabel.bottomAnchor.constraint(equalTo: coloredContainerView.bottomAnchor, constant: -12),
            
            daysCountLabel.topAnchor.constraint(equalTo: coloredContainerView.bottomAnchor, constant: 16),
            daysCountLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            
            completeButton.centerYAnchor.constraint(equalTo: daysCountLabel.centerYAnchor),
            completeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            completeButton.widthAnchor.constraint(equalToConstant: 34),
            completeButton.heightAnchor.constraint(equalToConstant: 34)
        ])
    }
    
    // MARK: - Configuration
    
    func configure(with tracker: Tracker, isCompleted: Bool, completedDays: Int) {
        coloredContainerView.backgroundColor = tracker.uiColor
        emojiLabel.text = tracker.emoji
        titleLabel.text = tracker.name
        
        daysCountLabel.text = formatDaysCount(completedDays)
        
        completeButton.backgroundColor = isCompleted ? tracker.uiColor.withAlphaComponent(0.3) : tracker.uiColor
        
        let imageName = isCompleted ? "checkmark" : "plus"
        let image = UIImage(systemName: imageName)?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 11, weight: .bold)
        )
        completeButton.setImage(image, for: .normal)
    }
    
    func setCompleteButtonEnabled(_ enabled: Bool) {
        completeButton.isEnabled = enabled
        completeButton.alpha = enabled ? 1.0 : 0.5
    }
    
    // MARK: - Private Methods
    
    private func formatDaysCount(_ count: Int) -> String {
        let lastDigit = count % 10
        let lastTwoDigits = count % 100
        
        if lastTwoDigits >= 11 && lastTwoDigits <= 14 {
            return "\(count) дней"
        }
        
        switch lastDigit {
        case 1:
            return "\(count) день"
        case 2, 3, 4:
            return "\(count) дня"
        default:
            return "\(count) дней"
        }
    }
    
    // MARK: - Actions
    
    @objc private func completeButtonTapped() {
        onCompleteButtonTapped?()
    }
}

