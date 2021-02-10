//
//  EditorViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 11/10/20.
//

import UIKit
import MobileCoreServices
import RSCore
import Templeton

class EditorViewController: UIViewController, MainControllerIdentifiable, UndoableCommandRunner {

	@IBOutlet weak var collectionView: UICollectionView!
	
	var mainControllerIdentifer: MainControllerIdentifier { return .editor }

	var isOutlineFunctionsUnavailable: Bool {
		return outline == nil
	}
	
	var isOutlineFiltered: Bool {
		return outline?.isFiltered ?? false
	}
	
	var isOutlineNotesHidden: Bool {
		return outline?.isNotesHidden ?? false
	}
	
	var isDeleteCurrentRowUnavailable: Bool {
		return currentRows == nil
	}
	
	var isInsertRowUnavailable: Bool {
		return currentRows == nil
	}
	
	var isCreateRowUnavailable: Bool {
		return currentRows == nil
	}
	
	var isIndentRowsUnavailable: Bool {
		guard let outline = outline, let rows = currentRows else { return true }
		return outline.isIndentRowsUnavailable(rows: rows)
	}

	var isOutdentRowsUnavailable: Bool {
		guard let outline = outline, let rows = currentRows else { return true }
		return outline.isOutdentRowsUnavailable(rows: rows)
	}

	var isToggleRowCompleteUnavailable: Bool {
		guard let outline = outline, let rows = currentRows else { return true }
		return outline.isCompleteUnavailable(rows: rows) && outline.isUncompleteUnavailable(rows: rows)
	}

	var isCompleteRowsAvailable: Bool {
		guard let outline = outline, let rows = currentRows else { return true }
		return !outline.isCompleteUnavailable(rows: rows)
	}
	
	var isCreateRowNotesUnavailable: Bool {
		guard let outline = outline, let rows = currentRows else { return true }
		return outline.isCreateNotesUnavailable(rows: rows)
	}

	var isDeleteRowNotesUnavailable: Bool {
		guard let outline = outline, let rows = currentRows else { return true }
		return outline.isDeleteNotesUnavailable(rows: rows)
	}

	var isSplitRowUnavailable: Bool {
		return currentTextView == nil
	}

	var isFormatUnavailable: Bool {
		return currentTextView == nil || !(currentTextView?.isSelecting ?? false)
	}

	var isLinkUnavailable: Bool {
		return currentTextView == nil || !(currentTextView?.isSelecting ?? false)
	}

	var isExpandAllInOutlineUnavailable: Bool {
		return outline == nil || outline!.isExpandAllUnavailable(containers: [outline!])
	}

	var isCollapseAllInOutlineUnavailable: Bool {
		return outline == nil || outline!.isCollapseAllUnavailable(containers: [outline!])
	}

	var isExpandAllUnavailable: Bool {
		guard let outline = outline, let rows = currentRows else { return true }
		return outline.isExpandAllUnavailable(containers: rows)
	}

	var isCollapseAllUnavailable: Bool {
		guard let outline = outline, let rows = currentRows else { return true }
		return outline.isCollapseAllUnavailable(containers: rows)
	}

	var isExpandUnavailable: Bool {
		guard let rows = currentRows else { return true }
		for row in rows {
			if row.isExpandable {
				return false
			}
		}
		return true
	}

	var isCollapseUnavailable: Bool {
		guard let rows = currentRows else { return true }
		for row in rows {
			if row.isCollapsable {
				return false
			}
		}
		return true
	}

	var currentRows: [Row]? {
		if let selected = collectionView?.indexPathsForSelectedItems, !selected.isEmpty {
			return selected.compactMap { outline?.shadowTable?[$0.row] }
		} else if let currentRow = currentTextView?.row {
			return [currentRow]
		}
		return nil
	}
	
	var undoableCommands = [UndoableCommand]()
	
	override var canBecomeFirstResponder: Bool { return true }

	private(set) var outline: Outline?
	
	private var currentTextView: OutlineTextView? {
		return UIResponder.currentFirstResponder as? OutlineTextView
	}
	
	private var currentTextRowStrings: TextRowStrings? {
		return currentTextView?.textRowStrings
	}
	
	private var currentCursorPosition: Int? {
		return currentTextView?.cursorPosition
	}
	
	private var cancelledKeyPresses = Set<UIKeyboardHIDUsage>()
	private var currentKeyPresses = Set<UIKeyboardHIDUsage>()
	
	private var filterBarButtonItem: UIBarButtonItem?

	private var titleRegistration: UICollectionView.CellRegistration<EditorTitleViewCell, Outline>?
	private var tagRegistration: UICollectionView.CellRegistration<EditorTagViewCell, String>?
	private var tagInputRegistration: UICollectionView.CellRegistration<EditorTagInputViewCell, EntityID>?
	private var tagAddRegistration: UICollectionView.CellRegistration<EditorTagAddViewCell, EntityID>?
	private var rowRegistration: UICollectionView.CellRegistration<EditorTextRowViewCell, Row>?
	
	private var firstVisibleShadowTableIndex: Int? {
		let visibleRect = collectionView.layoutMarginsGuide.layoutFrame
		let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.minY)
		if let indexPath = collectionView.indexPathForItem(at: visiblePoint), indexPath.section == Outline.Section.rows.rawValue {
			return indexPath.row
		}
		return nil
	}
	
	// This is used to keep the collection view from scrolling to the top as its layout gets invalidated.
	private var transitionContentOffset: CGPoint?
	
	private var isOutlineNewFlag = false
	private var isShowingAddButton = false
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		if traitCollection.userInterfaceIdiom == .mac {
			navigationController?.setNavigationBarHidden(true, animated: false)
		} else {
			filterBarButtonItem = UIBarButtonItem(image: AppAssets.filterInactive, style: .plain, target: self, action: #selector(toggleOutlineFilter(_:)))
			navigationItem.rightBarButtonItems = [filterBarButtonItem!]
		}
		
		collectionView.layer.speed = 1.25
		collectionView.collectionViewLayout = createLayout()
		collectionView.delegate = self
		collectionView.dataSource = self
		collectionView.dragDelegate = self
		collectionView.dropDelegate = self
		collectionView.dragInteractionEnabled = true
		collectionView.allowsMultipleSelection = true
		collectionView.selectionFollowsFocus = false
		collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 40, right: 0)

		titleRegistration = UICollectionView.CellRegistration<EditorTitleViewCell, Outline> { [weak self] (cell, indexPath, outline) in
			cell.title = outline.title
			cell.delegate = self
		}
		
		tagRegistration = UICollectionView.CellRegistration<EditorTagViewCell, String> { (cell, indexPath, name) in
			cell.name = name
			cell.delegate = self
		}
		
		tagInputRegistration = UICollectionView.CellRegistration<EditorTagInputViewCell, EntityID> { (cell, indexPath, outlineID) in
			cell.outlineID = outlineID
			cell.delegate = self
		}
		
		tagAddRegistration = UICollectionView.CellRegistration<EditorTagAddViewCell, EntityID> { (cell, indexPath, outlineID) in
			cell.outlineID = outlineID
			cell.delegate = self
		}
		
		rowRegistration = UICollectionView.CellRegistration<EditorTextRowViewCell, Row> { [weak self] (cell, indexPath, row) in
			cell.row = row
			cell.isNotesHidden = self?.outline?.isNotesHidden
			cell.delegate = self
		}
		
		updateUI()
		collectionView.reloadData()
		
		NotificationCenter.default.addObserver(self, selector: #selector(documentTitleDidChange(_:)), name: .DocumentTitleDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(outlineElementsDidChange(_:)), name: .OutlineElementsDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(applicationWillTerminate(_:)),	name: UIApplication.willTerminateNotification, object: nil)
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		restoreOutlineCursorPosition()
		restoreScrollPosition()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		moveCursorToTitleOnNew()
	}
	
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		if collectionView.contentOffset != .zero {
			transitionContentOffset = collectionView.contentOffset
		}
	}
	
	override func viewDidLayoutSubviews() {
		if let offset = transitionContentOffset {
			collectionView.contentOffset = offset
			transitionContentOffset = nil
		}
	}
	
	override func cut(_ sender: Any?) {
		guard let rows = currentRows else { return }
		cutRows(rows)
	}
	
	override func copy(_ sender: Any?) {
		guard let rows = currentRows else { return }
		copyRows(rows)
	}
	
	override func paste(_ sender: Any?) {
		pasteRows(afterRows: currentRows)
	}
	
	override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
		switch action {
		case .cut, .copy:
			return !(collectionView.indexPathsForSelectedItems?.isEmpty ?? true)
		case .paste:
			return UIPasteboard.general.contains(pasteboardTypes: [kUTTypeUTF8PlainText as String, Row.typeIdentifier])
		default:
			return super.canPerformAction(action, withSender: sender)
		}
	}
	
	override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
		if collectionView.indexPathsForSelectedItems?.isEmpty ?? true {
			pressesBeganForEditMode(presses, with: event)
		} else {
			pressesBeganForSelectMode(presses, with: event)
		}
	}
	
	override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
		super.pressesEnded(presses, with: event)
		let keyCodes = presses.compactMap { $0.key?.keyCode }
		keyCodes.forEach { currentKeyPresses.remove($0) }
	}
	
	override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
		super.pressesCancelled(presses, with: event)
		let keyCodes = presses.compactMap { $0.key?.keyCode }
		keyCodes.forEach { cancelledKeyPresses.insert($0)	}
	}
	
	// MARK: Notifications
	
	@objc func documentTitleDidChange(_ note: Notification) {
		guard let document = note.object as? Document,
			  let updatedOutline = document.outline,
			  updatedOutline == outline,
			  !(view.window?.isKeyWindow ?? false) else { return }
		collectionView.reloadItems(at: [IndexPath(row: 0, section: Outline.Section.title.rawValue)])
	}
	
	@objc func outlineElementsDidChange(_ note: Notification) {
		if note.object as? Outline == outline {
			guard let changes = note.userInfo?[OutlineElementChanges.userInfoKey] as? OutlineElementChanges else { return }
			applyChangesRestoringState(changes)
		}
	}
	
	@objc func applicationWillTerminate(_ note: Notification) {
		updateSpotlightIndex()
	}
	
	// MARK: API
	
	func edit(_ newOutline: Outline?, isNew: Bool) {
		guard outline != newOutline else { return }
		isOutlineNewFlag = isNew
		
		// Get ready for the new outline, buy saving the current one
		outline?.cursorCoordinates = CursorCoordinates.currentCoordinates
		
		if let textField = UIResponder.currentFirstResponder as? OutlineTextView {
			textField.endEditing(true)
		}
		
		updateSpotlightIndex()
		outline?.isBeingViewed = false
		outline?.suspend()
		clearUndoableCommands()
	
		// Assign the new Outline and load it
		outline = newOutline
		outline?.isBeingViewed = true
		outline?.load()
			
		guard isViewLoaded else { return }
		updateUI()
		collectionView.reloadData()
		
		restoreOutlineCursorPosition()
		restoreScrollPosition()
		moveCursorToTitleOnNew()
	}
	
	func deleteCurrentRows() {
		guard let rows = currentRows else { return }
		deleteRows(rows)
	}
	
	func insertRow() {
		guard let rows = currentRows else { return }
		createRow(beforeRows: rows)
	}
	
	func createRow() {
		guard let rows = currentRows else { return }
		createRow(afterRows: rows)
	}
	
	func indentRows() {
		guard let rows = currentRows else { return }
		indentRows(rows)
	}
	
	func outdentRows() {
		guard let rows = currentRows else { return }
		outdentRows(rows)
	}
	
	func toggleCompleteRows() {
		guard let outline = outline, let rows = currentRows else { return }
		if !outline.isCompleteUnavailable(rows: rows) {
			completeRows(rows)
		} else if !outline.isUncompleteUnavailable(rows: rows) {
			uncompleteRows(rows)
		}
	}
	
	func createRowNotes() {
		guard let rows = currentRows else { return }
		createRowNotes(rows)
	}
	
	func deleteRowNotes() {
		guard let rows = currentRows else { return }
		deleteRowNotes(rows)
	}
	
	func splitRow() {
		guard let row = currentRows?.last,
			  let topic = currentTextRowStrings?.topic,
			  let cursorPosition = currentCursorPosition else { return }
		splitRow(row, topic: topic, cursorPosition: cursorPosition)
	}
	
	func outlineToggleBoldface() {
		currentTextView?.toggleBoldface(self)
	}
	
	func outlineToggleItalics() {
		currentTextView?.toggleItalics(self)
	}
	
	func link() {
		currentTextView?.editLink(self)
	}
	
	func expandAllInOutline() {
		guard let outline = outline else { return }
		expandAll(containers: [outline])
	}
	
	func collapseAllInOutline() {
		guard let outline = outline else { return }
		collapseAll(containers: [outline])
	}
	
	func expandAll() {
		guard let rows = currentRows else { return }
		expandAll(containers: rows)
	}
	
	func collapseAll() {
		guard let rows = currentRows else { return }
		collapseAll(containers: rows)
	}
	
	func expand() {
		guard let rows = currentRows else { return }
		expand(rows: rows)
	}
	
	func collapse() {
		guard let rows = currentRows else { return }
		collapse(rows: rows)
	}
	
	// MARK: Actions
	
	@objc func toggleOutlineFilter(_ sender: Any?) {
		guard let changes = outline?.toggleFilter() else { return }
		updateUI()
		applyChangesRestoringState(changes)
	}
	
	@objc func toggleOutlineHideNotes(_ sender: Any?) {
		guard let changes = outline?.toggleNotesHidden() else { return }
		updateUI()
		applyChangesRestoringState(changes)
	}
	
	@objc func repeatMoveCursorUp() {
		guard currentKeyPresses.contains(.keyboardUpArrow) else { return }

		if let textView = UIResponder.currentFirstResponder as? EditorTextRowTopicTextView, let row = textView.row {
			moveCursorUp(row: row)
		} else if let tagInput = UIResponder.currentFirstResponder as? EditorTagInputTextField {
			if tagInput.isShowingResults {
				tagInput.selectAbove()
				return
			} else {
				moveCursorToTitle()
			}
		}
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
			self.repeatMoveCursorUp()
		}
	}

	@objc func repeatMoveCursorDown() {
		guard currentKeyPresses.contains(.keyboardDownArrow) else { return }
		
		if let textView = UIResponder.currentFirstResponder as? EditorTextRowTopicTextView, let row = textView.row {
			moveCursorDown(row: row)
		} else if let tagInput = UIResponder.currentFirstResponder as? EditorTagInputTextField {
			if tagInput.isShowingResults {
				tagInput.selectBelow()
				return
			} else if outline?.shadowTable?.count ?? 0 > 0 {
				if let rowCell = collectionView.cellForItem(at: IndexPath(row: 0, section: Outline.Section.rows.rawValue)) as? EditorTextRowViewCell {
					rowCell.moveToEnd()
				}
			}
		} else if let textView = UIResponder.currentFirstResponder as? EditorTitleTextView, !textView.isSelecting {
			moveCursorToTagInput()
		}
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
			self.repeatMoveCursorDown()
		}
	}
	
}

// MARK: Collection View

extension EditorViewController: UICollectionViewDelegate, UICollectionViewDataSource {
	
	private func createLayout() -> UICollectionViewLayout {
		let layout = UICollectionViewCompositionalLayout() { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
			
			if sectionIndex == Outline.Section.tags.rawValue {
				let itemSize = NSCollectionLayoutSize(widthDimension: .estimated(50), heightDimension: .estimated(100))
				let item = NSCollectionLayoutItem(layoutSize: itemSize)
				let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(100))
				let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
				return NSCollectionLayoutSection(group: group)
			} else {
				var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
				configuration.showsSeparators = false
				return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
			}
			
		}
		
		return layout
	}
	
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		self.outline?.verticleScrollState = firstVisibleShadowTableIndex
		if let tagInput = UIResponder.currentFirstResponder as? EditorTagInputTextField {
			tagInput.setNeedsLayout()
		}
	}
	
	func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 3
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		switch section {
		case Outline.Section.title.rawValue:
			return outline == nil ? 0 : 1
		case Outline.Section.tags.rawValue:
			if let outline = outline {
				if isShowingAddButton {
					return outline.tags.count + 2
				} else {
					return outline.tags.count + 1
				}
			} else {
				return 0
			}
		default:
			return outline?.shadowTable?.count ?? 0
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		switch indexPath.section {
		case Outline.Section.title.rawValue:
			return collectionView.dequeueConfiguredReusableCell(using: titleRegistration!, for: indexPath, item: outline)
		case Outline.Section.tags.rawValue:
			if let outline = outline, indexPath.row < outline.tagCount {
				let tag = outline.tags[indexPath.row]
				return collectionView.dequeueConfiguredReusableCell(using: tagRegistration!, for: indexPath, item: tag.name)
			} else if let outline = outline, indexPath.row == outline.tagCount {
				return collectionView.dequeueConfiguredReusableCell(using: tagInputRegistration!, for: indexPath, item: outline.id)
			} else {
				return collectionView.dequeueConfiguredReusableCell(using: tagAddRegistration!, for: indexPath, item: outline!.id)
			}
		default:
			let row = outline?.shadowTable?[indexPath.row] ?? Row.blank
			return collectionView.dequeueConfiguredReusableCell(using: rowRegistration!, for: indexPath, item: row)
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
		guard indexPath.section == Outline.Section.rows.rawValue else { return nil }
		
		// Force save the text if the context menu has been requested so that we don't lose our
		// text changes when the cell configuration gets applied
		if let textView = UIResponder.currentFirstResponder as? OutlineTextView {
			textView.saveText()
		}
		
		if !(collectionView.indexPathsForSelectedItems?.contains(indexPath) ?? false) {
			collectionView.deselectAll()
		}
		
		let rows: [Row]
		if let selected = collectionView.indexPathsForSelectedItems, !selected.isEmpty {
			rows = selected.compactMap { outline?.shadowTable?[$0.row] }
		} else {
			if let row = outline?.shadowTable?[indexPath.row] {
				rows = [row]
			} else {
				rows = [Row]()
			}
		}
		
		return makeRowsContextMenu(rows: rows)
	}
	
	func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
		guard let row = configuration.identifier as? TextRow,
			  let rowShadowTableIndex = row.shadowTableIndex,
			  let cell = collectionView.cellForItem(at: IndexPath(row: rowShadowTableIndex, section: Outline.Section.rows.rawValue)) as? EditorTextRowViewCell else { return nil }
		
		return UITargetedPreview(view: cell, parameters: EditorTextRowPreviewParameters(cell: cell, row: row))
	}
	
	func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
		return indexPath.section == Outline.Section.rows.rawValue
	}
	
}

extension EditorViewController: EditorTitleViewCellDelegate {
	
	var editorTitleUndoManager: UndoManager? {
		return undoManager
	}
	
	func editorTitleLayoutEditor() {
		layoutEditor()
	}
	
	func editorTitleTextFieldDidBecomeActive() {
		collectionView.deselectAll()
	}
	
	func editorTitleDidUpdate(title: String) {
		outline?.update(title: title)
	}
	
	func editorTitleMoveToTagInput() {
		moveCursorToTagInput()
	}

}

extension EditorViewController: EditorTagInputViewCellDelegate {
	
	var editorTagInputUndoManager: UndoManager? {
		return undoManager
	}
	
	var editorTagInputIsAddShowing: Bool {
		return isShowingAddButton
	}
	
	var editorTagInputTags: [Tag]? {
		guard let outlineTags = outline?.tags else { return nil }
		return outline?.account?.tags?.filter({ !outlineTags.contains($0) })
	}
	
	func editorTagInputLayoutEditor() {
		layoutEditor()
	}
	
	func editorTagInputTextFieldDidBecomeActive() {
		collectionView.deselectAll()
	}
	
	func editorTagInputTextFieldShowAdd() {
		guard let tagCount = outline?.tagCount else { return }
		isShowingAddButton = true
		let indexPath = IndexPath(row: tagCount + 1, section: Outline.Section.tags.rawValue)
		collectionView.insertItems(at: [indexPath])
	}
	
	func editorTagInputTextFieldHideAdd() {
		guard isShowingAddButton, let tagCount = outline?.tagCount else { return }
		isShowingAddButton = false
		let indexPath = IndexPath(row: tagCount + 1, section: Outline.Section.tags.rawValue)
		collectionView.deleteItems(at: [indexPath])
	}
	
	func editorTagInputTextFieldCreateRow() {
		createRow(afterRows: nil)
	}
	
	func editorTagInputTextFieldCreateTag(name: String) {
		createTag(name: name)
	}
	
}

extension EditorViewController: EditorTagAddViewCellDelegate {
	
	func editorTagAddAddTag() {
		if let outline = outline {
			let indexPath = IndexPath(row: outline.tags.count, section: Outline.Section.tags.rawValue)
			if let tagInputCell = collectionView.cellForItem(at: indexPath) as? EditorTagInputViewCell {
				tagInputCell.createTag()
			}
		}
	}
	
}

extension EditorViewController: EditorTagViewCellDelegate {
	
	func editorTagDeleteTag(name: String) {
		deleteTag(name: name)
	}
	
}

extension EditorViewController: EditorTextRowViewCellDelegate {

	var editorTextRowUndoManager: UndoManager? {
		return undoManager
	}
	
	func editorTextRowLayoutEditor() {
		layoutEditor()
	}
	
	func editorTextRowTextFieldDidBecomeActive() {
		collectionView.deselectAll()
	}

	func editorTextRowToggleDisclosure(row: Row) {
		toggleDisclosure(row: row)
	}
	
	func editorTextRowTextChanged(row: Row, textRowStrings: TextRowStrings, isInNotes: Bool, cursorPosition: Int) {
		textChanged(row: row, textRowStrings: textRowStrings, isInNotes: isInNotes, cursorPosition: cursorPosition)
	}
	
	func editorTextRowDeleteRow(_ row: Row, textRowStrings: TextRowStrings) {
		deleteRows([row], textRowStrings: textRowStrings)
	}
	
	func editorTextRowCreateRow(beforeRow: Row) {
		createRow(beforeRows: [beforeRow])
	}
	
	func editorTextRowCreateRow(afterRow: Row?, textRowStrings: TextRowStrings?) {
		let afterRows = afterRow == nil ? nil : [afterRow!]
		createRow(afterRows: afterRows, textRowStrings: textRowStrings)
	}
	
	func editorTextRowIndentRow(_ row: Row, textRowStrings: TextRowStrings) {
		indentRows([row], textRowStrings: textRowStrings)
	}
	
	func editorTextRowOutdentRow(_ row: Row, textRowStrings: TextRowStrings) {
		outdentRows([row], textRowStrings: textRowStrings)
	}
	
	func editorTextRowSplitRow(_ row: Row, topic: NSAttributedString, cursorPosition: Int) {
		splitRow(row, topic: topic, cursorPosition: cursorPosition)
	}
	
	func editorTextRowCreateRowNote(_ row: Row, textRowStrings: TextRowStrings) {
		createRowNotes([row], textRowStrings: textRowStrings)
	}
	
	func editorTextRowDeleteRowNote(_ row: Row, textRowStrings: TextRowStrings) {
		deleteRowNotes([row], textRowStrings: textRowStrings)
	}
	
	func editorTextRowMoveCursorTo(row: Row) {
		moveCursorTo(row: row)
	}
	
	func editorTextRowMoveCursorDown(row: Row) {
		moveCursorDown(row: row)
	}
	
	func editorTextRowEditLink(_ link: String?, range: NSRange) {
		editLink(link, range: range)
	}

}

// MARK: EditorOutlineCommandDelegate

extension EditorViewController: OutlineCommandDelegate {
	
	func restoreCursorPosition(_ cursorCoordinates: CursorCoordinates) {
		restoreCursorPosition(cursorCoordinates, animated: true)
	}
	
}

// MARK: LinkViewControllerDelegate

extension EditorViewController: LinkViewControllerDelegate {
	
	func updateLink(_: LinkViewController, cursorCoordinates: CursorCoordinates, link: String?, range: NSRange) {
		guard let shadowTableIndex = cursorCoordinates.row.shadowTableIndex else { return }
		let indexPath = IndexPath(row: shadowTableIndex, section: Outline.Section.rows.rawValue)
		guard let textRowCell = collectionView.cellForItem(at: indexPath) as? EditorTextRowViewCell else { return	}
		
		if cursorCoordinates.isInNotes {
			textRowCell.noteTextView?.updateLinkForCurrentSelection(link: link, range: range)
		} else {
			textRowCell.topicTextView?.updateLinkForCurrentSelection(link: link, range: range)
		}
	}
	
}

// MARK: Helpers

extension EditorViewController {
	
	private func updateUI() {
		navigationItem.largeTitleDisplayMode = .never
		
		if traitCollection.userInterfaceIdiom != .mac {
			if outline?.isFiltered ?? false {
				filterBarButtonItem?.image = AppAssets.filterActive
			} else {
				filterBarButtonItem?.image = AppAssets.filterInactive
			}
		}
	}
	
	private func pressesBeganForEditMode(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
		if !(CursorCoordinates.currentCoordinates?.isInNotes ?? false),
		   presses.count == 1,
		   presses.first?.key?.modifierFlags.subtracting(.numericPad).isEmpty ?? true,
		   let keyCode = presses.first?.key?.keyCode {
			
			guard cancelledKeyPresses.remove(keyCode) == nil else {
				return
			}
			
			switch keyCode {
			case .keyboardUpArrow:
				currentKeyPresses.insert(keyCode)
				repeatMoveCursorUp()
			case .keyboardDownArrow:
				currentKeyPresses.insert(keyCode)
				repeatMoveCursorDown()
			default:
				super.pressesBegan(presses, with: event)
			}
			
		} else {
			
			super.pressesBegan(presses, with: event)
			
		}
	}
	
	private func pressesBeganForSelectMode(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
		if presses.count == 1, let keyCode = presses.first?.key?.keyCode {
			guard cancelledKeyPresses.remove(keyCode) == nil else {
				return
			}
			
			switch keyCode {
			case .keyboardUpArrow:
				if let first = collectionView.indexPathsForSelectedItems?.sorted().first {
					if first.row > 0 {
						if let cell = collectionView.cellForItem(at: IndexPath(row: first.row - 1, section: first.section)) as? EditorTextRowViewCell {
							cell.moveToEnd()
						}
					} else {
						if let cell = collectionView.cellForItem(at: first) as? EditorTextRowViewCell {
							cell.moveToStart()
						}
					}
				}
			case .keyboardDownArrow:
				if let last = collectionView.indexPathsForSelectedItems?.sorted().last {
					if last.row + 1 < outline?.shadowTable?.count ?? 0 {
						if let cell = collectionView.cellForItem(at: IndexPath(row: last.row + 1, section: last.section)) as? EditorTextRowViewCell {
							cell.moveToEnd()
						}
					} else {
						if let cell = collectionView.cellForItem(at: last) as? EditorTextRowViewCell {
							cell.moveToEnd()
						}
					}
				}
			case .keyboardLeftArrow:
				if let first = collectionView.indexPathsForSelectedItems?.sorted().first {
					if let cell = collectionView.cellForItem(at: first) as? EditorTextRowViewCell {
						cell.moveToStart()
					}
				}
			case .keyboardRightArrow:
				if let last = collectionView.indexPathsForSelectedItems?.sorted().last {
					if let cell = collectionView.cellForItem(at: last) as? EditorTextRowViewCell {
						cell.moveToEnd()
					}
				}
			default:
				super.pressesBegan(presses, with: event)
			}
			
		} else {
			super.pressesBegan(presses, with: event)
		}
	}
	
	private func layoutEditor() {
		let contentOffset = collectionView.contentOffset
		collectionView.collectionViewLayout.invalidateLayout()
		collectionView.layoutIfNeeded()
		collectionView.contentOffset = contentOffset
	}
	
	private func applyChanges(_ changes: OutlineElementChanges) {
		if let deletes = changes.deleteIndexPaths, !deletes.isEmpty {
			collectionView.deleteItems(at: deletes)
		}
		
		if let inserts = changes.insertIndexPaths, !inserts.isEmpty {
			collectionView.insertItems(at: inserts)
		}
		
		if let moves = changes.moveIndexPaths, !moves.isEmpty {
			collectionView.performBatchUpdates {
				for move in moves {
					collectionView.moveItem(at: move.0, to: move.1)
				}
			}
		}
		
		if let reloads = changes.reloadIndexPaths, !reloads.isEmpty {
			// This is to prevent jumping when reloading the last item in the collection
			UIView.performWithoutAnimation {
				let contentOffset = collectionView.contentOffset
				collectionView.reloadItems(at: reloads)
				collectionView.contentOffset = contentOffset
			}
		}
	}
	
	private func applyChangesRestoringState(_ changes: OutlineElementChanges) {
		var textRange: UITextRange? = nil
		var cursorRow: Row? = nil
		if let editorTextView = UIResponder.currentFirstResponder as? EditorTextRowTopicTextView {
			textRange = editorTextView.selectedTextRange
			cursorRow = editorTextView.row
		}
		
		let selectedIndexPaths = collectionView.indexPathsForSelectedItems
		
		applyChanges(changes)
		
		if let textRange = textRange,
		   let updated = cursorRow?.shadowTableIndex,
		   let rowCell = collectionView.cellForItem(at: IndexPath(row: updated, section: Outline.Section.rows.rawValue)) as? EditorTextRowViewCell {
			rowCell.restoreSelection(textRange)
		}
		
		if changes.isOnlyReloads, let indexPaths = selectedIndexPaths {
			for indexPath in indexPaths {
				collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
			}
		}
	}

	private func restoreOutlineCursorPosition() {
		if let cursorCoordinates = outline?.cursorCoordinates {
			restoreCursorPosition(cursorCoordinates, animated: false)
		}
	}

	private func restoreCursorPosition(_ cursorCoordinates: CursorCoordinates, animated: Bool) {
		guard let shadowTableIndex = cursorCoordinates.row.shadowTableIndex else { return }
		let indexPath = IndexPath(row: shadowTableIndex, section: Outline.Section.rows.rawValue)

		func restoreCursor() {
			guard let rowCell = collectionView.cellForItem(at: indexPath) as? EditorTextRowViewCell else { return	}
			rowCell.restoreCursor(cursorCoordinates)
		}
		
		if !collectionView.indexPathsForVisibleItems.contains(indexPath) {
			CATransaction.begin()
			CATransaction.setCompletionBlock {
				// Got to wait or the row cell won't be found
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
					restoreCursor()
				}
			}
			collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: animated)
			CATransaction.commit()
		} else {
			restoreCursor()
		}
	}
	
	private func restoreScrollPosition() {
		if let verticleScrollState = outline?.verticleScrollState, verticleScrollState != 0 {
			collectionView.isHidden = true
			collectionView.scrollToItem(at: IndexPath(row: verticleScrollState, section: Outline.Section.rows.rawValue), at: .top, animated: false)
			DispatchQueue.main.async {
				self.collectionView.scrollToItem(at: IndexPath(row: verticleScrollState, section: Outline.Section.rows.rawValue), at: .top, animated: false)
				self.collectionView.isHidden = false
			}
		}
	}
	
	private func moveCursorToTitleOnNew() {
		if isOutlineNewFlag {
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
				self.moveCursorToTitle()
			}
		}
		isOutlineNewFlag = false
	}
	
	private func moveCursorToTitle() {
		if let titleCell = self.collectionView.cellForItem(at: IndexPath(row: 0, section: Outline.Section.title.rawValue)) as? EditorTitleViewCell {
			titleCell.takeCursor()
		}
	}
	
	private func moveCursorToTagInput() {
		if let outline = outline {
			let indexPath = IndexPath(row: outline.tags.count, section: Outline.Section.tags.rawValue)
			if let tagInputCell = collectionView.cellForItem(at: indexPath) as? EditorTagInputViewCell {
				tagInputCell.takeCursor()
			}
		}
	}
	
	private func editLink(_ link: String?, range: NSRange) {
		if traitCollection.userInterfaceIdiom == .mac {
		
			let linkViewController = UIStoryboard.dialog.instantiateController(ofType: LinkViewController.self)
			linkViewController.preferredContentSize = LinkViewController.preferredContentSize
			linkViewController.cursorCoordinates = CursorCoordinates.bestCoordinates
			linkViewController.link = link
			linkViewController.range = range
			linkViewController.delegate = self
			present(linkViewController, animated: true)
		
		} else {
			
			let linkNavViewController = UIStoryboard.dialog.instantiateViewController(withIdentifier: "LinkViewControllerNav") as! UINavigationController
			linkNavViewController.preferredContentSize = LinkViewController.preferredContentSize
			linkNavViewController.modalPresentationStyle = .formSheet

			let linkViewController = linkNavViewController.topViewController as! LinkViewController
			linkViewController.cursorCoordinates = CursorCoordinates.bestCoordinates
			linkViewController.link = link
			linkViewController.range = range
			linkViewController.delegate = self
			present(linkNavViewController, animated: true)
			
		}
	}
	
	private func makeRowsContextMenu(rows: [Row]) -> UIContextMenuConfiguration? {
		guard let firstRow = rows.sortedByDisplayOrder().first else { return nil }
		
		return UIContextMenuConfiguration(identifier: firstRow.associatedRow as NSCopying, previewProvider: nil, actionProvider: { [weak self] suggestedActions in
			guard let self = self, let outline = self.outline else { return nil }
			
			var menuItems = [UIMenu]()

			var standardEditActions = [UIAction]()
			standardEditActions.append(self.cutAction(rows: rows))
			standardEditActions.append(self.copyAction(rows: rows))
			if self.canPerformAction(.paste, withSender: nil) {
				standardEditActions.append(self.pasteAction(rows: rows))
			}
			menuItems.append(UIMenu(title: "", options: .displayInline, children: standardEditActions))

			var outlineActions = [UIAction]()
			outlineActions.append(self.addAction(rows: rows))
			if !outline.isIndentRowsUnavailable(rows: rows) {
				outlineActions.append(self.indentAction(rows: rows))
			}
			if !outline.isOutdentRowsUnavailable(rows: rows) {
				outlineActions.append(self.outdentAction(rows: rows))
			}
			if !outline.isCompleteUnavailable(rows: rows) {
				outlineActions.append(self.completeAction(rows: rows))
			}
			if !outline.isUncompleteUnavailable(rows: rows) {
				outlineActions.append(self.uncompleteAction(rows: rows))
			}
			if !outline.isCreateNotesUnavailable(rows: rows) {
				outlineActions.append(self.createNoteAction(rows: rows))
			}
			if !outline.isDeleteNotesUnavailable(rows: rows) {
				outlineActions.append(self.deleteNoteAction(rows: rows))
			}
			menuItems.append(UIMenu(title: "", options: .displayInline, children: outlineActions))

			var viewActions = [UIAction]()
			if !outline.isExpandAllUnavailable(containers: rows) {
				viewActions.append(self.expandAllAction(rows: rows))
			}
			if !outline.isCollapseAllUnavailable(containers: rows) {
				viewActions.append(self.collapseAllAction(rows: rows))
			}
			menuItems.append(UIMenu(title: "", options: .displayInline, children: viewActions))
			
			let deleteAction = self.deleteAction(rows: rows)
			menuItems.append(UIMenu(title: "", options: .displayInline, children: [deleteAction]))

			return UIMenu(title: "", children: menuItems)
		})
	}
	
	private func cutAction(rows: [Row]) -> UIAction {
		return UIAction(title: L10n.cut, image: AppAssets.cut) { [weak self] action in
			self?.cutRows(rows)
		}
	}

	private func copyAction(rows: [Row]) -> UIAction {
		return UIAction(title: L10n.copy, image: AppAssets.copy) { [weak self] action in
			self?.copyRows(rows)
		}
	}

	private func pasteAction(rows: [Row]) -> UIAction {
		return UIAction(title: L10n.paste, image: AppAssets.paste) { [weak self] action in
			self?.pasteRows(afterRows: rows)
		}
	}

	private func addAction(rows: [Row]) -> UIAction {
		return UIAction(title: L10n.addRow, image: AppAssets.add) { [weak self] action in
			// Have to let the text field get the first responder by getting it away from this
			// action which appears to be holding on to it.
			DispatchQueue.main.async {
				self?.createRow(afterRows: rows)
			}
		}
	}

	private func indentAction(rows: [Row]) -> UIAction {
		return UIAction(title: L10n.indent, image: AppAssets.indent) { [weak self] action in
			self?.indentRows(rows)
		}
	}

	private func outdentAction(rows: [Row]) -> UIAction {
		return UIAction(title: L10n.outdent, image: AppAssets.outdent) { [weak self] action in
			self?.outdentRows(rows)
		}
	}

	private func expandAllAction(rows: [Row]) -> UIAction {
		return UIAction(title: L10n.expandAll, image: AppAssets.expandAll) { [weak self] action in
			self?.expandAll(containers: rows)
		}
	}

	private func collapseAllAction(rows: [Row]) -> UIAction {
		return UIAction(title: L10n.collapseAll, image: AppAssets.collapseAll) { [weak self] action in
			self?.collapseAll(containers: rows)
		}
	}

	private func completeAction(rows: [Row]) -> UIAction {
		return UIAction(title: L10n.complete, image: AppAssets.completeRow) { [weak self] action in
			self?.completeRows(rows)
		}
	}
	
	private func uncompleteAction(rows: [Row]) -> UIAction {
		return UIAction(title: L10n.uncomplete, image: AppAssets.uncompleteRow) { [weak self] action in
			self?.uncompleteRows(rows)
		}
	}
	
	private func createNoteAction(rows: [Row]) -> UIAction {
		return UIAction(title: L10n.addNote, image: AppAssets.note) { [weak self] action in
			self?.createRowNotes(rows)
		}
	}

	private func deleteNoteAction(rows: [Row]) -> UIAction {
		return UIAction(title: L10n.deleteNote, image: AppAssets.delete, attributes: .destructive) { [weak self] action in
			self?.deleteRowNotes(rows)
		}
	}

	private func deleteAction(rows: [Row]) -> UIAction {
		return UIAction(title: L10n.deleteRow, image: AppAssets.delete, attributes: .destructive) { [weak self] action in
			self?.deleteRows(rows)
		}
	}

	private func moveCursorTo(row: Row) {
		guard let shadowTableIndex = row.shadowTableIndex else {
			return
		}
		
		let indexPath = IndexPath(row: shadowTableIndex, section: Outline.Section.rows.rawValue)
		if let rowCell = collectionView.cellForItem(at: indexPath) as? EditorTextRowViewCell {
			rowCell.moveToEnd()
		}
	}
	
	private func moveCursorUp(row: Row) {
		guard let shadowTableIndex = row.shadowTableIndex, shadowTableIndex > 0 else {
			moveCursorToTagInput()
			return
		}
		
		let indexPath = IndexPath(row: shadowTableIndex - 1, section: Outline.Section.rows.rawValue)
		makeCellVisibleIfNecessary(indexPath: indexPath) {
			if let rowCell = self.collectionView.cellForItem(at: indexPath) as? EditorTextRowViewCell {
				rowCell.moveToEnd()
			}
		}
	}
	
	private func moveCursorDown(row: Row) {
		guard let shadowTableIndex = row.shadowTableIndex, let shadowTable = outline?.shadowTable, shadowTableIndex < (shadowTable.count - 1) else { return }
		let indexPath = IndexPath(row: shadowTableIndex + 1, section: Outline.Section.rows.rawValue)
		makeCellVisibleIfNecessary(indexPath: indexPath) {
			if let rowCell = self.collectionView.cellForItem(at: indexPath) as? EditorTextRowViewCell {
				rowCell.moveToEnd()
			}
		}
	}
	
	private func toggleDisclosure(row: Row) {
		if row.isExpandable {
			expand(rows: [row])
		} else {
			collapse(rows: [row])
		}
	}

	private func createTag(name: String) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = CreateTagCommand(undoManager: undoManager,
									   delegate: self,
									   outline: outline,
									   tagName: name)
		
		runCommand(command)
		moveCursorToTagInput()
	}

	private func deleteTag(name: String) {
		guard let undoManager = undoManager, let outline = outline else { return }

		let command = DeleteTagCommand(undoManager: undoManager,
									   delegate: self,
									   outline: outline,
									   tagName: name)
		
		runCommand(command)
	}
	
	private func expand(rows: [Row]) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = ExpandCommand(undoManager: undoManager,
									delegate: self,
									outline: outline,
									rows: rows)
		
		runCommand(command)
	}

	private func collapse(rows: [Row]) {
		guard let undoManager = undoManager, let outline = outline else { return }

		let command = CollapseCommand(undoManager: undoManager,
									  delegate: self,
									  outline: outline,
									  rows: rows)
		
		runCommand(command)
	}

	private func expandAll(containers: [RowContainer]) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = ExpandAllCommand(undoManager: undoManager,
									   delegate: self,
									   outline: outline,
									   containers: containers)
		
		runCommand(command)
	}

	private func collapseAll(containers: [RowContainer]) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = CollapseAllCommand(undoManager: undoManager,
										 delegate: self,
										 outline: outline,
										 containers: containers)

		runCommand(command)
	}

	private func textChanged(row: Row, textRowStrings: TextRowStrings, isInNotes: Bool, cursorPosition: Int) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = TextChangedCommand(undoManager: undoManager,
										 delegate: self,
										 outline: outline,
										 row: row,
										 textRowStrings: textRowStrings,
										 isInNotes: isInNotes,
										 cursorPosition: cursorPosition)
		runCommand(command)
	}

	private func cutRows(_ rows: [Row]) {
		guard let undoManager = undoManager, let outline = outline else { return }
		copyRows(rows)

		let command = CutRowCommand(undoManager: undoManager,
									delegate: self,
									outline: outline,
									rows: rows)

		runCommand(command)
	}

	private func copyRows(_ rows: [Row]) {
		var itemProviders = [NSItemProvider]()

		for row in rows.sortedWithDecendentsFiltered() {
			let itemProvider = NSItemProvider()
			
			// We only register the text representation on the first one, since it looks like most text editors only support 1 dragged text item
			if row == rows[0] {
				itemProvider.registerDataRepresentation(forTypeIdentifier: kUTTypeUTF8PlainText as String, visibility: .all) { completion in
					var markdowns = [String]()
					for row in rows {
						markdowns.append(row.markdown())
					}
					let data = markdowns.joined(separator: "\n").data(using: .utf8)
					completion(data, nil)
					return nil
				}
			}
			
			itemProvider.registerDataRepresentation(forTypeIdentifier: Row.typeIdentifier, visibility: .ownProcess) { completion in
				do {
					let data = try row.asData()
					completion(data, nil)
				} catch {
					completion(nil, error)
				}
				return nil
			}
			
			itemProviders.append(itemProvider)
		}
		
		UIPasteboard.general.setItemProviders(itemProviders, localOnly: false, expirationDate: nil)
	}

	private func pasteRows(afterRows: [Row]?) {
		guard let undoManager = undoManager, let outline = outline else { return }

		if let rowProviderIndexes = UIPasteboard.general.itemSet(withPasteboardTypes: [Row.typeIdentifier]), !rowProviderIndexes.isEmpty {
			let group = DispatchGroup()
			var rows = [Row]()
			
			for index in rowProviderIndexes {
				let itemProvider = UIPasteboard.general.itemProviders[index]
				group.enter()
				itemProvider.loadDataRepresentation(forTypeIdentifier: Row.typeIdentifier) { [weak self] (data, error) in
					if let data = data {
						do {
							rows.append(try Row(from: data))
							group.leave()
						} catch {
							self?.presentError(error)
							group.leave()
						}
					}
				}
			}

			group.notify(queue: DispatchQueue.main) {
				let command = PasteRowCommand(undoManager: undoManager,
											  delegate: self,
											  outline: outline,
											  rows: rows,
											  afterRow: afterRows?.last)

				self.runCommand(command)
			}
			
		} else if let stringProviderIndexes = UIPasteboard.general.itemSet(withPasteboardTypes: [kUTTypeUTF8PlainText as String]), !stringProviderIndexes.isEmpty {
			
			let group = DispatchGroup()
			var texts = [String]()
			
			for index in stringProviderIndexes {
				let itemProvider = UIPasteboard.general.itemProviders[index]
				group.enter()
				itemProvider.loadDataRepresentation(forTypeIdentifier: kUTTypeUTF8PlainText as String) { (data, error) in
					if let data = data, let itemText = String(data: data, encoding: .utf8) {
						texts.append(itemText)
						group.leave()
					}
				}
			}

			group.notify(queue: DispatchQueue.main) {
				let text = texts.joined(separator: "\n")
				guard !text.isEmpty else { return }
				
				var rows = [Row]()
				let textRows = text.split(separator: "\n").map { String($0) }
				for textRow in textRows {
					let row = Row.text(TextRow(document: .outline(outline), topicPlainText: textRow.trimmingWhitespace))
					rows.append(row)
				}
				
				let command = PasteRowCommand(undoManager: undoManager,
											  delegate: self,
											  outline: outline,
											  rows: rows,
											  afterRow: afterRows?.last)

				self.runCommand(command)
			}

		}
	}

	private func deleteRows(_ rows: [Row], textRowStrings: TextRowStrings? = nil) {
		guard let undoManager = undoManager, let outline = outline else { return }

		let command = DeleteRowCommand(undoManager: undoManager,
									   delegate: self,
									   outline: outline,
									   rows: rows,
									   textRowStrings: textRowStrings)

		runCommand(command)
		
		if let newCursorIndex = command.newCursorIndex, let rowCell = collectionView.cellForItem(at: IndexPath(row: newCursorIndex, section: Outline.Section.rows.rawValue)) as? EditorTextRowViewCell {
			rowCell.moveToEnd()
		} else {
			moveCursorToTagInput()
		}
	}
	
	private func createRow(beforeRows: [Row]) {
		guard let undoManager = undoManager, let outline = outline, let beforeRow = beforeRows.sortedByDisplayOrder().first else { return }

		let command = CreateRowBeforeCommand(undoManager: undoManager,
											 delegate: self,
											 outline: outline,
											 beforeRow: beforeRow)
		
		runCommand(command)
		
		if let newCursorIndex = command.newCursorIndex {
			if let rowCell = collectionView.cellForItem(at: IndexPath(row: newCursorIndex, section: Outline.Section.rows.rawValue)) as? EditorTextRowViewCell {
				rowCell.moveToEnd()
			}
		}
	}
	
	private func createRow(afterRows: [Row]?, textRowStrings: TextRowStrings? = nil) {
		guard let undoManager = undoManager, let outline = outline else { return }

		let afterRow = afterRows?.sortedByDisplayOrder().last
		
		let command = CreateRowAfterCommand(undoManager: undoManager,
											delegate: self,
											outline: outline,
											afterRow: afterRow,
											textRowStrings: textRowStrings)
		
		runCommand(command)
		
		if let newCursorIndex = command.newCursorIndex {
			let newCursorIndexPath = IndexPath(row: newCursorIndex, section: Outline.Section.rows.rawValue)
			makeCellVisibleIfNecessary(indexPath: newCursorIndexPath) {
				if let rowCell = self.collectionView.cellForItem(at: newCursorIndexPath) as? EditorTextRowViewCell {
					rowCell.moveToEnd()
				}
			}
		}
	}
	
	private func indentRows(_ rows: [Row], textRowStrings: TextRowStrings? = nil) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = IndentRowCommand(undoManager: undoManager,
									   delegate: self,
									   outline: outline,
									   rows: rows,
									   textRowStrings: textRowStrings)
		
		runCommand(command)
	}
	
	private func outdentRows(_ rows: [Row], textRowStrings: TextRowStrings? = nil) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = OutdentRowCommand(undoManager: undoManager,
										delegate: self,
										outline: outline,
										rows: rows,
										textRowStrings: textRowStrings)
		
		runCommand(command)
	}

	private func splitRow(_ row: Row, topic: NSAttributedString, cursorPosition: Int) {
		guard let undoManager = undoManager, let outline = outline else { return }

		let command = SplitRowCommand(undoManager: undoManager,
									  delegate: self,
									  outline: outline,
									  row: row,
									  topic: topic,
									  cursorPosition: cursorPosition)
												  
		
		runCommand(command)
		
		if let newCursorIndex = command.newCursorIndex {
			if let rowCell = collectionView.cellForItem(at: IndexPath(row: newCursorIndex, section: Outline.Section.rows.rawValue)) as? EditorTextRowViewCell {
				rowCell.moveToStart()
			}
		}
	}

	private func completeRows(_ rows: [Row], textRowStrings: TextRowStrings? = nil) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = CompleteCommand(undoManager: undoManager,
									  delegate: self,
									  outline: outline,
									  rows: rows,
									  textRowStrings: textRowStrings)
		
		runCommand(command)
		
		if let newCursorIndex = command.newCursorIndex {
			if let rowCell = collectionView.cellForItem(at: IndexPath(row: newCursorIndex, section: Outline.Section.rows.rawValue)) as? EditorTextRowViewCell {
				rowCell.moveToEnd()
			}
		}
	}
	
	private func uncompleteRows(_ rows: [Row], textRowStrings: TextRowStrings? = nil) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = UncompleteCommand(undoManager: undoManager,
										delegate: self,
										outline: outline,
										rows: rows,
										textRowStrings: textRowStrings)
		
		runCommand(command)
	}
	
	private func createRowNotes(_ rows: [Row], textRowStrings: TextRowStrings? = nil) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = CreateNoteCommand(undoManager: undoManager,
										delegate: self,
										outline: outline,
										rows: rows,
										textRowStrings: textRowStrings)
		
		runCommand(command)
		
		if let newCursorIndex = command.newCursorIndex ?? rows.first?.shadowTableIndex {
			if let rowCell = collectionView.cellForItem(at: IndexPath(row: newCursorIndex, section: Outline.Section.rows.rawValue)) as? EditorTextRowViewCell {
				rowCell.moveToNote()
			}
		}
	}

	private func deleteRowNotes(_ rows: [Row], textRowStrings: TextRowStrings? = nil) {
		guard let undoManager = undoManager, let outline = outline else { return }
		
		let command = DeleteNoteCommand(undoManager: undoManager,
										delegate: self,
										outline: outline,
										rows: rows,
										textRowStrings: textRowStrings)
		
		runCommand(command)

		if let newCursorIndex = command.newCursorIndex {
			if let rowCell = collectionView.cellForItem(at: IndexPath(row: newCursorIndex, section: Outline.Section.rows.rawValue)) as? EditorTextRowViewCell {
				rowCell.moveToEnd()
			}
		}
	}

	private func makeCellVisibleIfNecessary(indexPath: IndexPath, completion: @escaping () -> Void) {
		guard let frame = collectionView.layoutAttributesForItem(at: indexPath)?.frame else {
			completion()
			return
		}
		
		let top = collectionView.contentOffset.y
		let bottom = collectionView.contentOffset.y + collectionView.frame.size.height
		
		guard frame.minY < top || frame.maxY > bottom else {
			completion()
			return
		}
		
		CATransaction.begin()
		CATransaction.setCompletionBlock {
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
				completion()
			}
		}
		collectionView.scrollRectToVisible(frame, animated: true)
		CATransaction.commit()
	}
	
	private func updateSpotlightIndex() {
		if let outline = outline {
			(splitViewController as? MainSplitViewController)?.activityManager.updateIndex(forDocument: .outline(outline))
		}
	}
	
}
