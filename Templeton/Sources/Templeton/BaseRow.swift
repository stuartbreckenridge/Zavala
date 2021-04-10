//
//  BaseRow.swift
//  
//
//  Created by Maurice Parker on 12/26/20.
//

import Foundation

public class BaseRow: NSObject, NSCopying, OPMLImporter, Identifiable {
	
	public var parent: RowContainer?
	public var shadowTableIndex: Int?

	public var id: EntityID
	public var isExpanded: Bool
	public internal(set) var rows: [Row] {
		get {
			guard let outline = self.outline else { return [Row]() }
			return rowOrder.compactMap { outline.keyedRows?[$0] }
		}
		set {
			guard let outline = self.outline else { return }
			
			outline.beginCloudKitBatchRequest()
			outline.requestCloudKitUpdate(for: id)
			
			for id in rowOrder {
				outline.keyedRows?.removeValue(forKey: id)
				outline.requestCloudKitUpdate(for: id)
			}

			var order = [EntityID]()
			for row in newValue {
				order.append(row.id)
				outline.keyedRows?[row.id] = row
				outline.requestCloudKitUpdate(for: row.id)
			}
			rowOrder = order
			
			outline.endCloudKitBatchRequest()
		}
	}
	
	public var rowCount: Int {
		return rowOrder.count
	}

	public var account: Account? {
		return AccountManager.shared.findAccount(accountID: id.accountID)
	}
	
	public var outline: Outline? {
		let document = account?.findDocument(documentUUID: id.documentUUID)
		if case .outline(let outline) = document {
			return outline
		}
		return nil
	}
	
	var rowOrder: [EntityID]

	var isAncestorComplete: Bool {
		if let parentRow = parent as? Row {
			return parentRow.isComplete || parentRow.isAncestorComplete
		}
		return false
	}

	var isPartOfSearchResult = false {
		didSet {
			guard isPartOfSearchResult else { return }
			
			var parentRow = parent as? Row
			while (parentRow != nil) {
				parentRow!.isPartOfSearchResult = true
				parentRow = parentRow?.parent as? Row
			}
		}
	}
	
	public override init() {
		self.id = .row(0, "", "")
		self.isExpanded = true
		self.rowOrder = [EntityID]()
	}
	
	func reassignAccount(_ accountID: Int) {
		self.id = .row(accountID, id.documentUUID, id.rowUUID)
		var newOrder = [EntityID]()
		for row in rowOrder {
			newOrder.append(.row(accountID, row.documentUUID, row.rowUUID))
		}
		rowOrder = newOrder
	}
	
	public func findImage(id: EntityID) -> Image? {
		return nil
	}
	
	public func saveImage(_ image: Image) {
	}

	public func deleteImage(id: EntityID) {
	}
	
	public func firstIndexOfRow(_ row: Row) -> Int? {
		return rowOrder.firstIndex(of: row.id)
	}
	
	public func containsRow(_ row: Row) -> Bool {
		return rowOrder.contains(row.id)
	}
	
	public func insertRow(_ row: Row, at: Int) {
		rowOrder.insert(row.id, at: at)
		outline?.keyedRows?[row.id] = row

		outline?.requestCloudKitUpdates(for: [id, row.id])
	}

	public func removeRow(_ row: Row) {
		rowOrder.removeFirst(object: row.id)
		outline?.keyedRows?.removeValue(forKey: row.id)
		outline?.requestCloudKitUpdates(for: [id, row.id])
	}

	public func appendRow(_ row: Row) {
		rowOrder.append(row.id)
		outline?.keyedRows?[row.id] = row

		outline?.requestCloudKitUpdates(for: [id, row.id])
	}

	public func clone(newOutlineID: EntityID) -> Row {
		fatalError("clone not implemented")
	}
	
	public func print(indentLevel: Int) -> NSAttributedString {
		fatalError("print not implemented")
	}
	
	public func string(indentLevel: Int) -> String {
		fatalError("string not implemented")
	}
	
	public func markdownOutline(indentLevel: Int) -> String {
		fatalError("markdown not implemented")
	}
	
	public func markdownPost(indentLevel: Int) -> String {
		fatalError("markdown not implemented")
	}
	
	public func opml(indentLevel: Int) -> String {
		fatalError("opml not implemented")
	}

	public override func isEqual(_ object: Any?) -> Bool {
		guard let other = object as? Self else { return false }
		if self === other { return true }
		return id == other.id
	}
	
	public override var hash: Int {
		var hasher = Hasher()
		hasher.combine(id)
		return hasher.finalize()
	}
	
	public func copy(with zone: NSZone? = nil) -> Any {
		return self
	}
	
}
