//
//  CategorySelectionViewController.swift
//  Tracker
//
//  Created by Павел Кузнецов on 07.03.2026.
//

import UIKit

final class CategorySelectionViewController: UIViewController {
    
    // MARK: - Properties
    
    private let viewModel: CategorySelectionViewModel
    weak var delegate: CategorySelectionDelegate?
    
    // MARK: - UI
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("categorySelection.title", comment: "")
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        return tableView
    }()
    
    private lazy var placeholderImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(resource: .placeholder).withRenderingMode(.alwaysOriginal)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        return imageView
    }()
    
    private lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("categorySelection.placeholder", comment: "")
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor(resource: .ypBlack)
        label.numberOfLines = 2
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    private lazy var placeholderView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(placeholderLabel)
        view.addSubview(placeholderImageView)
        
        NSLayoutConstraint.activate([
            placeholderImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholderImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            placeholderLabel.topAnchor.constraint(equalTo: placeholderImageView.bottomAnchor, constant: 8),
            placeholderLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        return view
    }()
    
    private lazy var addCategoryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("categorySelection.addButton", comment: ""), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(UIColor(resource: .ypWhite), for: .normal)
        button.backgroundColor = UIColor(resource: .ypBlack)
        button.layer.cornerRadius = 16
        button.layer.masksToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(addCategoryTapped), for: .touchUpInside)
        
        return button
    }()
    
    // MARK: - Initializer
    
    init(viewModel: CategorySelectionViewModel) {
        self.viewModel = viewModel
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
        setupBindings()
        viewModel.loadCategories()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor(resource: .ypWhite)
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(CategoryTableViewCell.self, forCellReuseIdentifier: "CategoryCell")
        tableView.backgroundColor = UIColor(resource: .ypWhite)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.separatorColor = UIColor(resource: .ypGray)
        
        view.addSubview(titleLabel)
        view.addSubview(tableView)
        view.addSubview(placeholderView)
        view.addSubview(addCategoryButton)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 27),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: addCategoryButton.topAnchor, constant: -16),
            
            placeholderView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholderView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            addCategoryButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            addCategoryButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addCategoryButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            addCategoryButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    // MARK: - Bindings
    
    private func setupBindings() {
        viewModel.onCategoriesUpdated = { [weak self] categories in
            self?.tableView.reloadData()
            self?.placeholderView.isHidden = !categories.isEmpty
            self?.tableView.isHidden = categories.isEmpty
        }
        
        viewModel.onCategorySelected = { [weak self] category in
            self?.delegate?.didSelectCategory(category)
            self?.dismiss(animated: true)
        }
    }
    
    // MARK: - Actions
    
    @objc private func addCategoryTapped() {
        let editVC = CategoryEditViewController()
        editVC.onDone = { [weak self] name in
            self?.viewModel.addCategory(name: name)
        }
        editVC.modalPresentationStyle = .pageSheet
        present(editVC, animated: true)
    }
    
    private func showEditScreen(for categoryName: String) {
        let editVC = CategoryEditViewController(existingName: categoryName)
        editVC.onDone = { [weak self] newName in
            self?.viewModel.renameCategory(from: categoryName, to: newName)
        }
        editVC.modalPresentationStyle = .pageSheet
        present(editVC, animated: true)
    }
    
    private func showDeleteConfirmation(for index: Int) {
        let alert = UIAlertController(
            title: nil,
            message: NSLocalizedString("categorySelection.deleteConfirmation", comment: ""),
            preferredStyle: .actionSheet
        )
        
        let deleteAction = UIAlertAction(title: NSLocalizedString("common.delete", comment: ""), style: .destructive) { [weak self] _ in
            self?.viewModel.deleteCategory(at: index)
        }
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("common.cancel", comment: ""), style: .cancel)
        
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension CategorySelectionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfCategories()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "CategoryCell",
            for: indexPath
        ) as? CategoryTableViewCell else {
            return UITableViewCell()
        }
        
        let title = viewModel.categoryName(at: indexPath.row)
        let isSelected = viewModel.isCategorySelected(at: indexPath.row)
        cell.configure(title: title, isSelected: isSelected)
        
        let totalRows = viewModel.numberOfCategories()
        
        if totalRows == 1 {
            cell.layer.cornerRadius = 16
            cell.layer.maskedCorners = [
                .layerMinXMinYCorner, .layerMaxXMinYCorner,
                .layerMinXMaxYCorner, .layerMaxXMaxYCorner
            ]
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
        } else if indexPath.row == 0 {
            cell.layer.cornerRadius = 16
            cell.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else if indexPath.row == totalRows - 1 {
            cell.layer.cornerRadius = 16
            cell.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
        } else {
            cell.layer.cornerRadius = 0
        }
        
        cell.layer.masksToBounds = true
        
        return cell
    }
}
// MARK: - UITableViewDelegate

extension CategorySelectionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.selectCategory(at: indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        75
    }
    
    func tableView(
        _ tableView: UITableView,
        contextMenuConfigurationForRowAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        let categoryName = viewModel.categoryName(at: indexPath.row)
        
        return UIContextMenuConfiguration(actionProvider: { _ in
            let editAction = UIAction(title: NSLocalizedString("common.edit", comment: "")) { [weak self] _ in
                self?.showEditScreen(for: categoryName)
            }
            
            let deleteAction = UIAction(
                title: NSLocalizedString("common.delete", comment: ""),
                attributes: .destructive
            ) { [weak self] _ in
                self?.showDeleteConfirmation(for: indexPath.row)
            }
            
            return UIMenu(children: [editAction, deleteAction])
        })
    }
}

