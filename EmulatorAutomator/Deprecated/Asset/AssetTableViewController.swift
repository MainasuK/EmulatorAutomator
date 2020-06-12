//
//  AssetTableViewController.swift
//  EmulatorAutomator
//
//  Created by Cirno MainasuK on 2020-3-30.
//  Copyright © 2020 MainasuK Cirno. All rights reserved.
//

import os
import Cocoa
import Combine

final class AssetTableViewModel: NSObject {
    
    var disposeBag = Set<AnyCancellable>()
    let assets = CurrentValueSubject<[Asset], Never>([])
    
    override init() {
        super.init()
        
//        AssetService.shared.assets
//            .assign(to: \.value, on: assets)
//            .store(in: &disposeBag)
    }
    
}

// MARK: - NSTableViewDataSource
extension AssetTableViewModel: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return assets.value.count
    }
    
}

final class AssetTableViewController: NSViewController {
    
    struct NotificationName {
        static let didSelectAsset = Notification.Name(rawValue: "AssetTableViewController.didSelectAsset")
    }
    
    var disposeBag = Set<AnyCancellable>()
    let viewModel = AssetTableViewModel()
    
    let tableView: NSTableView = {
        let tableView = NSTableView()
        let nameColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("name"))
        tableView.addTableColumn(nameColumn)
        tableView.focusRingType = .none
        return tableView
    }()
    
    override func loadView() {
        view = NSView()
    }
    
}

extension AssetTableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            view.bottomAnchor.constraint(greaterThanOrEqualTo: tableView.bottomAnchor),
        ])
        
        tableView.dataSource = viewModel
        tableView.delegate = self
        
        viewModel.assets
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &disposeBag)
    }
    
}


// MARK: - NSTableViewDelegate
extension AssetTableViewController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let identifier = tableColumn!.identifier
        let cell = (tableView.makeView(withIdentifier: identifier, owner: nil) as? LabelTableCellView) ?? LabelTableCellView.new(identifier: identifier)
        
        let asset = viewModel.assets.value[row]
        cell.nameTextField.stringValue = asset.name
        return cell
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let first = tableView.selectedRowIndexes.first else {
            return
        }
        
        let row = Int(first)
        let asset = viewModel.assets.value[row]
        
        NotificationCenter.default.post(name: AssetTableViewController.NotificationName.didSelectAsset, object: asset)
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

