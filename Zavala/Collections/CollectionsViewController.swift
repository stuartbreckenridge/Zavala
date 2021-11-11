//
//  CollectionsViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 11/5/20.
//

import UIKit
import UniformTypeIdentifiers
import RSCore
import Combine
import Templeton

protocol CollectionsDelegate: AnyObject {
	func documentContainerSelectionsDidChange(_: CollectionsViewController, documentContainers: [DocumentContainer], isNavigationBranch: Bool, animated: Bool, completion: (() -> Void)?)
}

enum CollectionsSection: Int {
	case search, localAccount, cloudKitAccount
}

class CollectionsViewController: UICollectionViewController, MainControllerIdentifiable {
	var mainControllerIdentifer: MainControllerIdentifier { return .collections }
	
	weak var delegate: CollectionsDelegate?
	
	var selectedAccount: Account? {
        selectedDocumentContainers?.uniqueAccount
	}
	
	var selectedTags: [Tag]? {
        return selectedDocumentContainers?.compactMap { ($0 as? TagDocuments)?.tag }
	}
	
	var selectedDocumentContainers: [DocumentContainer]? {
		guard let selectedIndexPaths = collectionView.indexPathsForSelectedItems else {
			return nil
		}
        
        return selectedIndexPaths.compactMap { indexPath in
            if let entityID = dataSource.itemIdentifier(for: indexPath)?.entityID {
                return AccountManager.shared.findDocumentContainer(entityID)
            }
            return nil
        }
	}

	var dataSource: UICollectionViewDiffableDataSource<CollectionsSection, CollectionsItem>!
	private let dataSourceQueue = MainThreadOperationQueue()
	private var applyChangesQueue = CoalescingQueue(name: "Apply Snapshot", interval: 0.5)
	private var reloadChangedQueue = CoalescingQueue(name: "Reload Visible", interval: 0.5)

	private var mainSplitViewController: MainSplitViewController? {
		return splitViewController as? MainSplitViewController
	}
	
	private var addBarButtonItem: UIBarButtonItem!
	private var importBarButtonItem: UIBarButtonItem!

    private var selectBarButtonItem: UIBarButtonItem!
    private var selectDoneBarButtonItem: UIBarButtonItem!

    override func viewDidLoad() {
		super.viewDidLoad()

		addBarButtonItem = UIBarButtonItem(image: AppAssets.createEntity, style: .plain, target: self, action: #selector(createOutline(_:)))
        addBarButtonItem.title = L10n.add

        importBarButtonItem = UIBarButtonItem(image: AppAssets.importDocument, style: .plain, target: self, action: #selector(importOPML(_:)))
        importBarButtonItem.title = L10n.importOPML

        selectBarButtonItem = UIBarButtonItem(title: L10n.select, style: .plain, target: self, action: #selector(multipleSelect))
        selectDoneBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(multipleSelectDone))
        
		if traitCollection.userInterfaceIdiom == .mac {
			navigationController?.setNavigationBarHidden(true, animated: false)
		} else {
			collectionView.refreshControl = UIRefreshControl()
			collectionView.alwaysBounceVertical = true
			collectionView.refreshControl!.addTarget(self, action: #selector(sync), for: .valueChanged)
		}
        
        if traitCollection.userInterfaceIdiom == .mac {
            collectionView.allowsMultipleSelection = true
        }

        if traitCollection.userInterfaceIdiom == .pad {
            navigationItem.rightBarButtonItem = selectBarButtonItem
        }

		if traitCollection.userInterfaceIdiom == .phone {
			navigationItem.rightBarButtonItems = [addBarButtonItem, importBarButtonItem]
		}
		
		NotificationCenter.default.addObserver(self, selector: #selector(accountManagerAccountsDidChange(_:)), name: .AccountManagerAccountsDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(accountDidInitialize(_:)), name: .AccountDidInitialize, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(accountMetadataDidChange(_:)), name: .AccountMetadataDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(accountTagsDidChange(_:)), name: .AccountTagsDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(outlineTagsDidChange(_:)), name: .OutlineTagsDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(cloudKitSyncDidComplete(_:)), name: .CloudKitSyncDidComplete, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(accountDocumentsDidChange(_:)), name: .AccountDocumentsDidChange, object: nil)
	}
	
	// MARK: API
	
	func startUp() {
		collectionView.remembersLastFocusedIndexPath = true
		collectionView.dragDelegate = self
		collectionView.dropDelegate = self
		collectionView.collectionViewLayout = createLayout()
		configureDataSource()
		applyInitialSnapshot()
	}
	
	func selectDocumentContainers(_ containers: [DocumentContainer]?, isNavigationBranch: Bool, animated: Bool, completion: (() -> Void)? = nil) {
        collectionView.deselectAll()
        
        if let containers = containers, containers.count > 1, traitCollection.userInterfaceIdiom == .pad {
            multipleSelect()
        }
        
        if let containers = containers, containers.count == 1, let search = containers.first as? Search {
			DispatchQueue.main.async {
				if let searchCellIndexPath = self.dataSource.indexPath(for: CollectionsItem.searchItem()) {
					if let searchCell = self.collectionView.cellForItem(at: searchCellIndexPath) as? CollectionsSearchCell {
						searchCell.setSearchField(searchText: search.searchText)
					}
				}
			}
		} else {
			clearSearchField()
		}

		updateSelections(containers, isNavigationBranch: isNavigationBranch, animated: animated, completion: completion)
	}
	
	// MARK: Notifications
	
	@objc func accountManagerAccountsDidChange(_ note: Notification) {
		queueApplyChangeSnapshot()
	}

	@objc func accountDidInitialize(_ note: Notification) {
		queueApplyChangeSnapshot()
	}
	
	@objc func accountMetadataDidChange(_ note: Notification) {
		queueApplyChangeSnapshot()
	}
	
	@objc func accountTagsDidChange(_ note: Notification) {
		queueApplyChangeSnapshot()
		queueReloadChangeSnapshot()
	}

	@objc func outlineTagsDidChange(_ note: Notification) {
		queueReloadChangeSnapshot()
	}

	@objc func accountDocumentsDidChange(_ note: Notification) {
		queueReloadChangeSnapshot()
	}

	@objc func cloudKitSyncDidComplete(_ note: Notification) {
		collectionView?.refreshControl?.endRefreshing()
	}
	
	// MARK: Actions
	
	@objc func sync() {
		if AccountManager.shared.isSyncAvailable {
			AccountManager.shared.sync()
		} else {
			collectionView?.refreshControl?.endRefreshing()
		}
	}
	
	@IBAction func showSettings(_ sender: Any) {
		mainSplitViewController?.showSettings()
	}
	
	@objc func importOPML(_ sender: Any) {
		mainSplitViewController?.importOPML()
	}

    @objc func createOutline(_ sender: Any) {
        mainSplitViewController?.createOutline()
    }
    
    @objc func multipleSelect() {
        selectDocumentContainers(nil, isNavigationBranch: true, animated: true)
        collectionView.allowsMultipleSelection = true
        navigationItem.rightBarButtonItem = selectDoneBarButtonItem
    }

    @objc func multipleSelectDone() {
        selectDocumentContainers(nil, isNavigationBranch: true, animated: true)
        collectionView.allowsMultipleSelection = false
        navigationItem.rightBarButtonItem = selectBarButtonItem
    }

	// MARK: API
	
	func beginDocumentSearch() {
		if let searchCellIndexPath = self.dataSource.indexPath(for: CollectionsItem.searchItem()) {
			if let searchCell = self.collectionView.cellForItem(at: searchCellIndexPath) as? CollectionsSearchCell {
				searchCell.setSearchField(searchText: "")
			}
		}
	}
	
}

// MARK: Collection View

extension CollectionsViewController {
	
	override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
		// If we don't force the text view to give up focus, we get its additional context menu items
		if let textView = UIResponder.currentFirstResponder as? UITextView {
			textView.resignFirstResponder()
		}
		
		if !(collectionView.indexPathsForSelectedItems?.contains(indexPath) ?? false) {
			collectionView.deselectAll()
		}
		
		let items: [CollectionsItem]
		if let selected = collectionView.indexPathsForSelectedItems, !selected.isEmpty {
			items = selected.compactMap { dataSource.itemIdentifier(for: $0) }
		} else {
			if let item = dataSource.itemIdentifier(for: indexPath) {
				items = [item]
			} else {
				items = [CollectionsItem]()
			}
		}
		
		guard let mainItem = dataSource.itemIdentifier(for: indexPath) else { return nil }
		return makeDocumentContainerContextMenu(mainItem: mainItem, items: items)
	}
    
	override func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
		return false
	}
		
	override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        updateSelections()
    }

	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		clearSearchField()
        updateSelections()
	}
    
    private func updateSelections() {
        guard let selectedIndexes = collectionView.indexPathsForSelectedItems else { return }
        let items = selectedIndexes.compactMap { dataSource.itemIdentifier(for: $0) }
		let containers = items.toContainers()
        
        delegate?.documentContainerSelectionsDidChange(self, documentContainers: containers, isNavigationBranch: true, animated: true, completion: nil)
    }
    
	private func createLayout() -> UICollectionViewLayout {
		let layout = UICollectionViewCompositionalLayout() { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
			var configuration = UICollectionLayoutListConfiguration(appearance: .sidebar)
			configuration.showsSeparators = false
			configuration.headerMode = .firstItemInSection
			return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
		}
		return layout
	}
	
	private func configureDataSource() {
		let searchRegistration = UICollectionView.CellRegistration<CollectionsSearchCell, CollectionsItem> { (cell, indexPath, item) in
			var contentConfiguration = CollectionsSearchContentConfiguration(searchText: nil)
			contentConfiguration.delegate = self
			cell.contentConfiguration = contentConfiguration
		}

		let headerRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, CollectionsItem> {	(cell, indexPath, item) in
			var contentConfiguration = UIListContentConfiguration.sidebarHeader()
			
			contentConfiguration.text = item.id.name
			contentConfiguration.textProperties.font = .preferredFont(forTextStyle: .subheadline)
			contentConfiguration.textProperties.color = .secondaryLabel
			
			cell.contentConfiguration = contentConfiguration
			cell.accessories = [.outlineDisclosure()]
		}
		
		let rowRegistration = UICollectionView.CellRegistration<ConsistentCollectionViewListCell, CollectionsItem> { (cell, indexPath, item) in
			var contentConfiguration = UIListContentConfiguration.sidebarSubtitleCell()
			
			if case .documentContainer(let entityID) = item.id, let container = AccountManager.shared.findDocumentContainer(entityID) {
				contentConfiguration.text = container.name
				contentConfiguration.image = container.image
				if let count = container.itemCount {
					contentConfiguration.secondaryText = String(count)
				}
			}

			contentConfiguration.prefersSideBySideTextAndSecondaryText = true
			cell.contentConfiguration = contentConfiguration
		}
		
		dataSource = UICollectionViewDiffableDataSource<CollectionsSection, CollectionsItem>(collectionView: collectionView) { (collectionView, indexPath, item) -> UICollectionViewCell in
			switch item.id {
			case .search:
				return collectionView.dequeueConfiguredReusableCell(using: searchRegistration, for: indexPath, item: item)
			case .header:
				return collectionView.dequeueConfiguredReusableCell(using: headerRegistration, for: indexPath, item: item)
			default:
				return collectionView.dequeueConfiguredReusableCell(using: rowRegistration, for: indexPath, item: item)
			}
		}
	}
	
	private func searchSnapshot() -> NSDiffableDataSourceSectionSnapshot<CollectionsItem> {
		var snapshot = NSDiffableDataSourceSectionSnapshot<CollectionsItem>()
		snapshot.append([CollectionsItem.searchItem()])
		return snapshot
	}
	
	private func localAccountSnapshot() -> NSDiffableDataSourceSectionSnapshot<CollectionsItem>? {
		let localAccount = AccountManager.shared.localAccount
		
		guard localAccount.isActive else { return nil }
		
		var snapshot = NSDiffableDataSourceSectionSnapshot<CollectionsItem>()
		let header = CollectionsItem.item(id: .header(.localAccount))
		
		let items = localAccount.documentContainers.map { CollectionsItem.item($0) }
		
		snapshot.append([header])
		snapshot.expand([header])
		snapshot.append(items, to: header)
		return snapshot
	}
	
	private func cloudKitAccountSnapshot() -> NSDiffableDataSourceSectionSnapshot<CollectionsItem>? {
		guard let cloudKitAccount = AccountManager.shared.cloudKitAccount else { return nil }
		
		var snapshot = NSDiffableDataSourceSectionSnapshot<CollectionsItem>()
		let header = CollectionsItem.item(id: .header(.cloudKitAccount))
		
		let items = cloudKitAccount.documentContainers.map { CollectionsItem.item($0) }
		
		snapshot.append([header])
		snapshot.expand([header])
		snapshot.append(items, to: header)
		return snapshot
	}
	
	private func applyInitialSnapshot() {
		if traitCollection.userInterfaceIdiom == .mac {
			applySnapshot(searchSnapshot(), section: .search, animated: false)
		}
		applyChangeSnapshot()
	}
	
	private func applyChangeSnapshot() {
		if let snapshot = localAccountSnapshot() {
			applySnapshot(snapshot, section: .localAccount, animated: true)
		} else {
			applySnapshot(NSDiffableDataSourceSectionSnapshot<CollectionsItem>(), section: .localAccount, animated: true)
		}

		if let snapshot = self.cloudKitAccountSnapshot() {
			applySnapshot(snapshot, section: .cloudKitAccount, animated: true)
		} else {
			applySnapshot(NSDiffableDataSourceSectionSnapshot<CollectionsItem>(), section: .cloudKitAccount, animated: true)
		}
	}
	
	func applySnapshot(_ snapshot: NSDiffableDataSourceSectionSnapshot<CollectionsItem>, section: CollectionsSection, animated: Bool) {
		let selectedItems = collectionView.indexPathsForSelectedItems?.compactMap({ dataSource.itemIdentifier(for: $0) })
		
		let operation = ApplySnapshotOperation(dataSource: dataSource, section: section, snapshot: snapshot, animated: animated)

		operation.completionBlock = { [weak self] _ in
			guard let self = self else { return }
			let selectedIndexPaths = selectedItems?.compactMap { self.dataSource.indexPath(for: $0) }
			for selectedIndexPath in selectedIndexPaths ?? [IndexPath]() {
				self.collectionView.selectItem(at: selectedIndexPath, animated: false, scrollPosition: [])
			}
		}
		
		dataSourceQueue.add(operation)
	}
	
	func updateSelections(_ containers: [DocumentContainer]?, isNavigationBranch: Bool, animated: Bool, completion: (() -> Void)?) {
        let items = containers?.map { CollectionsItem.item($0) } ?? [CollectionsItem]()
		dataSourceQueue.add(UpdateSelectionOperation(dataSource: dataSource, collectionView: collectionView, items: items, animated: animated))
        
		let containers = items.toContainers()
		delegate?.documentContainerSelectionsDidChange(self, documentContainers: containers, isNavigationBranch: isNavigationBranch, animated: animated, completion: completion)
	}
	
	func reloadVisible() {
		dataSourceQueue.add(ReloadVisibleItemsOperation(dataSource: dataSource, collectionView: collectionView))
	}
	
}

// MARK: CollectionsSearchCellDelegate

extension CollectionsViewController: CollectionsSearchCellDelegate {

	func collectionsSearchDidBecomeActive() {
		selectDocumentContainers([Search(searchText: "")], isNavigationBranch: false, animated: false)
	}

	func collectionsSearchDidUpdate(searchText: String?) {
		if let searchText = searchText {
			selectDocumentContainers([Search(searchText: searchText)], isNavigationBranch: false, animated: true)
		} else {
			selectDocumentContainers([Search(searchText: "")], isNavigationBranch: false, animated: false)
		}
	}
	
}

// MARK: Helpers

extension CollectionsViewController {
	
	private func clearSearchField() {
		if let searchCellIndexPath = dataSource.indexPath(for: CollectionsItem.searchItem()) {
			if let searchCell = collectionView.cellForItem(at: searchCellIndexPath) as? CollectionsSearchCell {
				searchCell.clearSearchField()
			}
		}
	}
	
	private func queueApplyChangeSnapshot() {
		applyChangesQueue.add(self, #selector(applyQueuedChangeSnapshot))
	}
	
	@objc private func applyQueuedChangeSnapshot() {
		applyChangeSnapshot()
	}
	
	private func queueReloadChangeSnapshot() {
		reloadChangedQueue.add(self, #selector(reloadQueuedChangeSnapshot))
	}
	
	@objc private func reloadQueuedChangeSnapshot() {
		reloadVisible()
	}
	
	private func makeDocumentContainerContextMenu(mainItem: CollectionsItem, items: [CollectionsItem]) -> UIContextMenuConfiguration {
		return UIContextMenuConfiguration(identifier: mainItem as NSCopying, previewProvider: nil, actionProvider: { [weak self] suggestedActions in
			guard let self = self else { return nil }

			let containers: [DocumentContainer] = items.compactMap { item in
				if case .documentContainer(let entityID) = item.id {
					return AccountManager.shared.findDocumentContainer(entityID)
				}
				return nil
			}
			
			var menuItems = [UIMenu]()
			if let renameTagAction = self.renameTagAction(containers: containers) {
				menuItems.append(UIMenu(title: "", options: .displayInline, children: [renameTagAction]))
			}
			if let deleteTagAction = self.deleteTagAction(containers: containers) {
				menuItems.append(UIMenu(title: "", options: .displayInline, children: [deleteTagAction]))
			}
			return UIMenu(title: "", children: menuItems)
		})
	}

	private func renameTagAction(containers: [DocumentContainer]) -> UIAction? {
		guard containers.count == 1, let container = containers.first, let tagDocuments = container as? TagDocuments else { return nil }
		
		let action = UIAction(title: L10n.rename, image: AppAssets.rename) { [weak self] action in
			guard let self = self else { return }
			
			if self.traitCollection.userInterfaceIdiom == .mac {
				let renameTagViewController = UIStoryboard.dialog.instantiateController(ofType: MacRenameTagViewController.self)
				renameTagViewController.preferredContentSize = CGSize(width: 400, height: 80)
				renameTagViewController.tagDocuments = tagDocuments
				self.present(renameTagViewController, animated: true)
			} else {
				let renameTagNavViewController = UIStoryboard.dialog.instantiateViewController(withIdentifier: "RenameTagViewControllerNav") as! UINavigationController
				renameTagNavViewController.preferredContentSize = CGSize(width: 400, height: 100)
				renameTagNavViewController.modalPresentationStyle = .formSheet
				let renameTagViewController = renameTagNavViewController.topViewController as! RenameTagViewController
				renameTagViewController.tagDocuments = tagDocuments
				self.present(renameTagNavViewController, animated: true)
			}
		}
		
		return action
	}

	private func deleteTagAction(containers: [DocumentContainer]) -> UIAction? {
		let tagDocuments = containers.compactMap { $0 as? TagDocuments }
		guard tagDocuments.count == containers.count else { return nil}
		
		let action = UIAction(title: L10n.delete, image: AppAssets.delete, attributes: .destructive) { [weak self] action in
			let deleteAction = UIAlertAction(title: L10n.delete, style: .destructive) { _ in
				for tagDocument in tagDocuments {
					if let tag = tagDocument.tag {
						tagDocument.account?.forceDeleteTag(tag)
					}
				}
			}
			
			let title: String
			let message: String
			if tagDocuments.count == 1, let tag = tagDocuments.first?.tag {
				title = L10n.deleteTagPrompt(tag.name)
				message = L10n.deleteTagMessage
			} else {
				title = L10n.deleteTagsPrompt(tagDocuments.count)
				message = L10n.deleteTagsMessage
			}
			
			let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: L10n.cancel, style: .cancel))
			alert.addAction(deleteAction)
			alert.preferredAction = deleteAction
			self?.present(alert, animated: true, completion: nil)
		}
		
		return action
	}

}