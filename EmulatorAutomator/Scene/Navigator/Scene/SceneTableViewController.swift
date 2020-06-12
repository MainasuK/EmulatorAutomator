//
//  SceneTableViewController.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-3-29.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import os
import Cocoa
import Combine

final class SceneTableViewModel: NSObject {

    var disposeBag = Set<AnyCancellable>()
    let scenes = CurrentValueSubject<[Scene], Never>([])
    
    override init() {
        super.init()
    
//        SceneService.shared.scenes
//            .assign(to: \.value, on: scenes)
//            .store(in: &disposeBag)
    }
    
}

// MARK: - NSTableViewDataSource
extension SceneTableViewModel: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return scenes.value.count
    }
    
}

final class SceneTableViewController: NSViewController {
    
    struct NotificationName {
        static let didSelectScene = Notification.Name(rawValue: "SceneTableViewController.didSelectScene")
    }
    
    
    var disposeBag = Set<AnyCancellable>()
    var observers = Set<NSKeyValueObservation>()
    let viewModel = SceneTableViewModel()
    
    let tableView: NSTableView = {
        let tableView = NSTableView()
        let nameColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("name"))
        tableView.addTableColumn(nameColumn)
        tableView.focusRingType = .none
        return tableView
    }()
    
    private(set) lazy var addButton: NSButton = {
        let button = NSButton(image: NSImage(named: NSImage.addTemplateName)!, target: self, action: #selector(SceneTableViewController.addButtonPressed(_:)))
        button.isBordered = false
        button.setButtonType(.momentaryPushIn)
        return button
    }()
    
    private(set) lazy var removeButton: NSButton = {
        let button = NSButton(image: NSImage(named: NSImage.removeTemplateName)!, target: self, action: #selector(SceneTableViewController.removeButtonPressed(_:)))
        button.isBordered = false
        button.setButtonType(.momentaryPushIn)
        return button
    }()
    
    override func loadView() {
        view = NSView()
    }
    
}

extension SceneTableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let bottomToolbarStackView = NSStackView()
        bottomToolbarStackView.alignment = .centerY
        bottomToolbarStackView.spacing = 0
        
        bottomToolbarStackView.addArrangedSubview(addButton)
        bottomToolbarStackView.addArrangedSubview(removeButton)
        
        bottomToolbarStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomToolbarStackView)
        NSLayoutConstraint.activate([
            bottomToolbarStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomToolbarStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomToolbarStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            addButton.widthAnchor.constraint(equalToConstant: 22),
            addButton.heightAnchor.constraint(equalTo: addButton.widthAnchor, multiplier: 1.0),
            removeButton.widthAnchor.constraint(equalToConstant: 22),
            removeButton.heightAnchor.constraint(equalTo: removeButton.widthAnchor, multiplier: 1.0),
        ])

        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomToolbarStackView.topAnchor.constraint(equalTo: scrollView.bottomAnchor),
        ])
        scrollView.documentView = tableView
        
        tableView.dataSource = viewModel
        tableView.delegate = self
        
        viewModel.scenes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
                NotificationCenter.default.post(name: SceneTableViewController.NotificationName.didSelectScene, object: nil)
            }
            .store(in: &disposeBag)
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        
//        let index = tableView.selectedRow
//        guard index != -1 else { return }
//        let rowView = tableView.rowView(atRow: index, makeIfNecessary: false) as? NoEmphasizedRowView
//        rowView?.isPreviousSelected = true
    }
    
//    override func viewDidAppear() {
//        super.viewDidAppear()
//
//        let index = tableView.selectedRow
//        guard index != -1 else { return }
//        let rowView = tableView.rowView(atRow: index, makeIfNecessary: false) as? NoEmphasizedRowView
//        rowView?.shouldResign = false
//    }
    
}

extension SceneTableViewController {
    
    @objc private func addButtonPressed(_ sender: NSButton) {
        os_log(.info, log: .interaction, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        
        //SceneService.shared.createScene()
    }
    
    @objc private func removeButtonPressed(_ sender: NSButton) {
        os_log(.info, log: .interaction, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

class NoEmphasizedRowView: NSTableRowView {
    override var isSelected: Bool {
        didSet {
            
        }
    }
}

// MARK: - NSTableViewDelegate
extension SceneTableViewController: NSTableViewDelegate {
    
//    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
//        let identifier = tableColumn!.identifier
//
//        return NoEmphasizedRowView()
//    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let identifier = tableColumn!.identifier
        let cell = (tableView.makeView(withIdentifier: identifier, owner: self) as? LabelTableCellView) ?? LabelTableCellView.new(identifier: identifier)
        
        let asset = viewModel.scenes.value[row]
        cell.nameTextField.stringValue = asset.name

        return cell
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let first = tableView.selectedRowIndexes.first else {
            NotificationCenter.default.post(name: SceneTableViewController.NotificationName.didSelectScene, object: nil)
            return
        }

        let row = Int(first)
        let scene = viewModel.scenes.value[row]

        NotificationCenter.default.post(name: SceneTableViewController.NotificationName.didSelectScene, object: scene)
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}
