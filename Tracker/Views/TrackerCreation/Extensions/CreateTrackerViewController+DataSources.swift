//
//  CreateTrackerViewController+DataSources.swift
//  Tracker
//
//  Created by Павел Кузнецов on 31.01.2026.
//

import UIKit

// MARK: - UITableViewDataSource

extension CreateTrackerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingsRows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath) as! SubtitleTableViewCell
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        
        let row = settingsRows[indexPath.row]
        
        switch row {
        case .category:
            cell.configure(title: row.title, subtitle: selectedCategory)
        case .schedule:
            cell.configure(title: row.title, subtitle: scheduleDescription())
        }
        
        cell.accessoryType = .disclosureIndicator
        
        if indexPath.row == settingsRows.count - 1 {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension CreateTrackerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = settingsRows[indexPath.row]
        
        switch row {
        case .category:
            openCategorySelection()
        case .schedule:
            openScheduleSelection()
        }
    }
}

// MARK: - UICollectionViewDataSource

extension CreateTrackerViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == emojiCollectionView {
            return emojis.count
        } else if collectionView == colorCollectionView {
            return colors.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == emojiCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCell", for: indexPath) as! EmojiCollectionViewCell
            let emoji = emojis[indexPath.item]
            let isSelected = emoji == selectedEmoji
            cell.configure(emoji: emoji, isSelected: isSelected)
            return cell
            
        } else if collectionView == colorCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ColorCell", for: indexPath) as! ColorCollectionViewCell
            let colorName = colors[indexPath.item]
            let color = UIColor(named: colorName) ?? .clear
            let isSelected = colorName == selectedColor
            cell.configure(color: color, isSelected: isSelected)
            return cell
        }
        
        return UICollectionViewCell()
    }
}

// MARK: - UICollectionViewDelegate

extension CreateTrackerViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == emojiCollectionView {
            selectedEmoji = emojis[indexPath.item]
            emojiCollectionView.reloadData()
            
        } else if collectionView == colorCollectionView {
            selectedColor = colors[indexPath.item]
            colorCollectionView.reloadData()
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension CreateTrackerViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 52, height: 52)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

// MARK: - UITextFieldDelegate

extension CreateTrackerViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - ScheduleSelectionDelegate

extension CreateTrackerViewController: ScheduleSelectionDelegate {
    func didSelectSchedule(_ schedule: Set<Weekday>) {
        selectedSchedule = schedule
    }
}
