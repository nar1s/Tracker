//
//  TrackerCreationCells.swift
//  Tracker
//
//  Created by Павел Кузнецов on 31.01.2026.
//

import UIKit

// MARK: - EmojiCollectionViewCell

final class EmojiCollectionViewCell: UICollectionViewCell {
    
    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 32)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let backgroundSquare: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addSubview(backgroundSquare)
        contentView.addSubview(emojiLabel)
        
        NSLayoutConstraint.activate([
            backgroundSquare.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            backgroundSquare.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            backgroundSquare.widthAnchor.constraint(equalToConstant: 52),
            backgroundSquare.heightAnchor.constraint(equalToConstant: 52),
            
            emojiLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func configure(emoji: String, isSelected: Bool) {
        emojiLabel.text = emoji
        backgroundSquare.backgroundColor = isSelected ? UIColor(resource: .ypLightGray) : .clear
    }
}

// MARK: - ColorCollectionViewCell

final class ColorCollectionViewCell: UICollectionViewCell {
    
    private let colorView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let borderView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        view.layer.borderWidth = 3
        view.backgroundColor = .clear
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addSubview(borderView)
        contentView.addSubview(colorView)
        
        NSLayoutConstraint.activate([
            borderView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            borderView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            borderView.widthAnchor.constraint(equalToConstant: 52),
            borderView.heightAnchor.constraint(equalToConstant: 52),
            
            colorView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            colorView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            colorView.widthAnchor.constraint(equalToConstant: 40),
            colorView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    func configure(color: UIColor, isSelected: Bool) {
        colorView.backgroundColor = color
        
        if isSelected {
            borderView.isHidden = false
            borderView.layer.borderColor = color.withAlphaComponent(0.3).cgColor
        } else {
            borderView.isHidden = true
        }
    }
}
