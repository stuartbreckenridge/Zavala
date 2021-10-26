//
//  Row.swift
//  
//
//  Created by Maurice Parker on 12/24/20.
//

import Foundation
import MobileCoreServices
import MarkdownAttributedString

public enum RowStrings {
	case topicMarkdown(String?)
	case noteMarkdown(String?)
	case topic(NSAttributedString?)
	case note(NSAttributedString?)
	case both(NSAttributedString?, NSAttributedString?)
}

enum RowError: LocalizedError {
	case unableToDeserialize
	var errorDescription: String? {
		return NSLocalizedString("Unable to deserialize the row data.", comment: "An unexpected CloudKit error occurred.")
	}
}

public final class Row: NSObject, NSCopying, RowContainer, Codable, Identifiable {
	
	public static let typeIdentifier = "io.vincode.Zavala.Row"
	
	public var parent: RowContainer?
	public var shadowTableIndex: Int?

	public var id: String
	public var syncID: String?
	public var isExpanded: Bool
	public internal(set) var rows: [Row] {
		get {
			guard let outline = self.outline else { return [Row]() }
			return rowOrder.compactMap { outline.keyedRows?[$0] }
		}
		set {
			guard let outline = self.outline else { return }
			
			outline.beginCloudKitBatchRequest()
			outline.requestCloudKitUpdate(for: entityID)
			
			for id in rowOrder {
				outline.keyedRows?.removeValue(forKey: id)
				outline.requestCloudKitUpdate(for: entityID)
			}

			var order = [String]()
			for row in newValue {
				order.append(row.id)
				outline.keyedRows?[row.id] = row
				outline.requestCloudKitUpdate(for: row.entityID)
			}
			rowOrder = order
			
			outline.endCloudKitBatchRequest()
		}
	}
	
	public var rowCount: Int {
		return rowOrder.count
	}

	public var isAncestorComplete: Bool {
		if let parentRow = parent as? Row {
			return parentRow.isComplete || parentRow.isAncestorComplete
		}
		return false
	}

	public weak var outline: Outline? {
		didSet {
			if let outline = outline {
				_entityID = .row(outline.id.accountID, outline.id.documentUUID, id)
			}
		}
	}
	
	public var entityID: EntityID {
		guard let entityID = _entityID else {
			fatalError("Missing EntityID for row")
		}
		return entityID
	}

	var rowOrder: [String]

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
	
	private var _entityID: EntityID?
	
	public var level: Int {
		var parentCount = 0
		var p = parent as? Row
		while p != nil {
			parentCount = parentCount + 1
			p = p?.parent as? Row
		}
		return parentCount
	}
	
	public var isExpandable: Bool {
		guard rowCount > 0 else { return false }
		return !isExpanded
	}

	public var isCollapsable: Bool {
		guard rowCount > 0 else { return false }
		return isExpanded
	}
	
	public var isCompletable: Bool {
		return !isComplete
	}
	
	public var isUncompletable: Bool {
		return isComplete
	}
	
	public internal(set) var isComplete: Bool

	public var isNoteEmpty: Bool {
		return noteMarkdown == nil
	}
	
	public var topicMarkdown: String? {
		get {
			return convertAttrString(topic, isInNotes: false)
		}
		set {
			topic = convertMarkdown(newValue, isInNotes: false)
		}
	}
	
	public var noteMarkdown: String? {
		get {
			return convertAttrString(note, isInNotes: true)
		}
		set {
			note = convertMarkdown(newValue, isInNotes: true)
		}
	}
	
	public var topic: NSAttributedString? {
		get {
			guard let topic = topicData else { return nil }
			if topicCache == nil {
				topicCache = try? NSAttributedString(data: topic,
													 options: [.documentType: NSAttributedString.DocumentType.rtf, .characterEncoding: String.Encoding.utf8.rawValue],
													 documentAttributes: nil)
				topicCache = replaceImages(attrString: topicCache, isNotes: false)
			}
			return topicCache
		}
		set {
			if let attrText = newValue {
				let (cleanAttrText, newImages) = splitOffImages(attrString: attrText, isNotes: false)
				
				topicData = try? cleanAttrText.data(from: .init(location: 0, length: cleanAttrText.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
				
				var notesImages = images?.filter { $0.isInNotes } ?? [Image]()
				notesImages.append(contentsOf: newImages)
				images = notesImages
			} else {
				topicData = nil
				images = images?.filter { $0.isInNotes }
			}
			outline?.requestCloudKitUpdate(for: entityID)
		}
	}
	
	public var note: NSAttributedString? {
		get {
			guard let note = noteData else { return nil }
			if noteCache == nil {
				noteCache = try? NSAttributedString(data: note,
													options: [.documentType: NSAttributedString.DocumentType.rtf, .characterEncoding: String.Encoding.utf8.rawValue],
													documentAttributes: nil)
				noteCache = replaceImages(attrString: noteCache, isNotes: true)
			}
			return noteCache
		}
		set {
			if let attrText = newValue {
				let (cleanAttrText, newImages) = splitOffImages(attrString: attrText, isNotes: true)
				
				noteData = try? cleanAttrText.data(from: .init(location: 0, length: cleanAttrText.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])

				var topicImages = images?.filter { !$0.isInNotes } ?? [Image]()
				topicImages.append(contentsOf: newImages)
				images = topicImages
			} else {
				noteData = nil
				images = images?.filter { !$0.isInNotes }
			}
			outline?.requestCloudKitUpdate(for: entityID)
		}
	}
	
	public var rowStrings: RowStrings {
		get {
			return RowStrings.both(topic, note)
		}
		set {
			switch newValue {
			case .topicMarkdown(let topicMarkdown):
				self.topicMarkdown = topicMarkdown
			case .noteMarkdown(let noteMarkdown):
				self.noteMarkdown = noteMarkdown
			case .topic(let topic):
				self.topic = topic
			case .note(let note):
				self.note = note
			case .both(let topic, let note):
				self.topic = topic
				self.note = note
			}
		}
	}
	
	public var searchResultCoordinates = NSHashTable<SearchResultCoordinates>.weakObjects()

	var topicData: Data? {
		didSet {
			topicCache = nil
		}
	}
	
	var noteData: Data? {
		didSet {
			noteCache = nil
		}
	}
	
	var images: [Image]? {
		get {
			return outline?.findImages(rowID: id)
		}
		set {
			outline?.updateImages(rowID: id, images: newValue)
			topicCache = nil
			noteCache = nil
		}
	}
	
	private enum CodingKeys: String, CodingKey {
		case id = "id"
		case syncID = "syncID"
		case topicData = "topicData"
		case noteData = "noteData"
		case isExpanded = "isExpanded"
		case isComplete = "isComplete"
		case rowOrder = "rowOrder"
	}
	
	private static let markdownImagePattern = "!\\]\\]\\(([^)]+).png\\)"
	
	private var topicCache: NSAttributedString?
	private var noteCache: NSAttributedString?

	public init(outline: Outline) {
		self.isComplete = false
		self.id = UUID().uuidString
		self.outline = outline
		self._entityID = .row(outline.id.accountID, outline.id.documentUUID, id)
		self.isExpanded = true
		self.rowOrder = [String]()
		super.init()
	}

	public init(outline: Outline, topicMarkdown: String?, noteMarkdown: String? = nil) {
		self.isComplete = false
		self.id = UUID().uuidString
		self.outline = outline
		self._entityID = .row(outline.id.accountID, outline.id.documentUUID, id)
		self.isExpanded = true
		self.rowOrder = [String]()
		super.init()
		self.topicMarkdown = topicMarkdown
		self.noteMarkdown = noteMarkdown
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		if let isComplete = try? container.decode(Bool.self, forKey: .isComplete) {
			self.isComplete = isComplete
		} else {
			self.isComplete = false
		}

		if let id = try? container.decode(String.self, forKey: .id) {
			self.id = id
		} else if let id = try? container.decode(EntityID.self, forKey: .id) {
			self.id = id.rowUUID
		} else {
			throw RowError.unableToDeserialize
		}
		
		if let isExpanded = try? container.decode(Bool.self, forKey: .isExpanded) {
			self.isExpanded = isExpanded
		} else {
			self.isExpanded = true
		}
		
		if let rowOrder = try? container.decode([String].self, forKey: .rowOrder) {
			self.rowOrder = rowOrder
		} else if let rowOrder = try? container.decode([EntityID].self, forKey: .rowOrder) {
			self.rowOrder = rowOrder.map { $0.rowUUID }
		} else {
			throw RowError.unableToDeserialize
		}

		super.init()

		topicData = try? container.decode(Data.self, forKey: .topicData)
		noteData = try? container.decode(Data.self, forKey: .noteData)
	}
	
	public override init() {
		self.isComplete = false
		self.id = UUID().uuidString
		self.isExpanded = true
		self.rowOrder = [String]()
		super.init()
	}
	
	init(id: String) {
		self.isComplete = false
		self.id = id
		self.isExpanded = true
		self.rowOrder = [String]()
		super.init()
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(id, forKey: .id)
		try container.encode(topicData, forKey: .topicData)
		try container.encode(noteData, forKey: .noteData)
		try container.encode(isExpanded, forKey: .isExpanded)
		try container.encode(isComplete, forKey: .isComplete)
		try container.encode(rowOrder, forKey: .rowOrder)
	}
	
	public func duplicate(newOutline: Outline) -> Row {
		let row = Row(outline: newOutline)

		row.topicData = topicData
		row.noteData = noteData
		row.isExpanded = isExpanded
		row.isComplete = isComplete
		row.rowOrder = rowOrder
		row.images = images?.map { $0.duplicate(accountID: newOutline.id.accountID, documentUUID: newOutline.id.documentUUID, rowUUID: row.id) }
		
		return row
	}
	
	public func importText(topicMarkdown: String?, noteMarkdown: String?, images: [String: Data]?) {
		guard let regEx = try? NSRegularExpression(pattern: Self.markdownImagePattern, options: []) else {
			return
		}
		
		var matchedImages = [Image]()
		
		func replaceImageMarkdown(_ markdown: String?, isInNotes: Bool) -> NSAttributedString? {
			if let markdown = markdown {
				let mangledMarkdown = markdown.replacingOccurrences(of: "![", with: "!]")
				let attrString = NSMutableAttributedString(markdownRepresentation: mangledMarkdown, attributes: [.font : UIFont.preferredFont(forTextStyle: .body)])
				let strippedString = attrString.string
				let matches = regEx.allMatches(in: strippedString)
				
				for match in matches {
					guard let wholeRange = Range(match.range(at: 0), in: strippedString), let captureRange = Range(match.range(at: 1), in: strippedString) else {
						continue
					}
					
					let currentString = attrString.string
					let wholeString = strippedString[wholeRange]
					guard let wholeStringRange = currentString.range(of: wholeString) else {
						continue
					}
					
					let offset = currentString[currentString.startIndex..<wholeStringRange.lowerBound].utf16.count
					attrString.replaceCharacters(in: NSRange(location: offset, length: wholeString.utf16.count), with: "")
					
					let imageUUID = String(strippedString[captureRange])
					if let data = images?[imageUUID] {
						let imageID = EntityID.image(entityID.accountID, entityID.documentUUID, entityID.rowUUID, imageUUID)
						matchedImages.append(Image(id: imageID, isInNotes: isInNotes, offset: offset, data: data))
					}
				}
				
				return attrString
			}
			
			return nil
		}
		
		self.topic = replaceImageMarkdown(topicMarkdown, isInNotes: false)
		self.note = replaceImageMarkdown(noteMarkdown, isInNotes: true)
		
		outline?.updateImages(rowID: id, images: matchedImages)
	}
	
	public func findImage(id: EntityID) -> Image? {
		return images?.first(where: { $0.id == id })
	}

	public func saveImage(_ image: Image) {
		var foundImages = images
		
		if foundImages == nil {
			images = [image]
		} else {
			if let index = foundImages!.firstIndex(where: { $0.id == image.id }) {
				foundImages!.remove(at: index)
			}
			foundImages!.append(image)
			images = foundImages
		}
		
		topicCache = nil
		noteCache = nil
	}

	public func deleteImage(id: EntityID) {
		images?.removeAll(where: { $0.id == id })
		topicCache = nil
		noteCache = nil
	}

	public func complete() {
		guard isCompletable else { return }
		isComplete = true
		outline?.requestCloudKitUpdate(for: entityID)
	}
	
	public func uncomplete() {
		guard isUncompletable else { return }
		isComplete = false
		outline?.requestCloudKitUpdate(for: entityID)
	}

	public func firstIndexOfRow(_ row: Row) -> Int? {
		return rows.firstIndex(of: row)
	}
	
	public func containsRow(_ row: Row) -> Bool {
		return rows.contains(row)
	}
	
	public func insertRow(_ row: Row, at: Int) {
		rowOrder.insert(row.id, at: at)
		outline?.keyedRows?[row.id] = row

		outline?.requestCloudKitUpdates(for: [entityID, row.entityID])
	}

	public func removeRow(_ row: Row) {
		rowOrder.removeFirst(object: row.id)
		outline?.keyedRows?.removeValue(forKey: row.id)
		outline?.requestCloudKitUpdates(for: [entityID, row.entityID])
	}

	public func appendRow(_ row: Row) {
		rowOrder.append(row.id)
		outline?.keyedRows?[row.id] = row

		outline?.requestCloudKitUpdates(for: [entityID, row.entityID])
	}

	public func isDecendent(_ row: Row) -> Bool {
		if let parentRow = parent as? Row, parentRow.id == row.id || parentRow.isDecendent(row) {
			return true
		}
		return false
	}
	
	/// Returns itself or the first ancestor that shares a parent with the given row
	public func ancestorSibling(_ row: Row) -> Row? {
		guard let parent = parent else { return nil }
		
		if parent.containsRow(row) || containsRow(row) {
			return self
		}
		
		if let parentRow = parent as? Row {
			return parentRow.ancestorSibling(row)
		}
		
		return nil
	}
	
	public func hasSameParent(_ row: Row) -> Bool {
		if let parentOutline = parent as? Outline, let rowOutline = row.parent as? Outline {
			return parentOutline.id == rowOutline.id
		}
		if let parentRow = parent as? Row, let rowRow = row.parent as? Row {
			return parentRow.id == rowRow.id
		}
		return false
	}
	
	public func markdownList() -> String {
		let visitor = MarkdownListVisitor()
		visit(visitor: visitor.visitor)
		return visitor.markdown
	}
	
	public func visit(visitor: (Row) -> Void) {
		visitor(self)
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

// MARK: CustomDebugStringConvertible

extension Row {
	override public var debugDescription: String {
		return "\(topic?.string ?? "") (\(id))"
	}
}

// MARK: Helpers

extension Row {
	
	private func replaceImages(attrString: NSAttributedString?, isNotes: Bool) -> NSAttributedString? {
		guard let attrString = attrString else { return nil }
		let mutableAttrString = NSMutableAttributedString(attributedString: attrString)
		
		mutableAttrString.enumerateAttribute(.attachment, in: .init(location: 0, length: mutableAttrString.length), options: []) { (attribute, range, _) in
			mutableAttrString.removeAttribute(.attachment, range: range)
		}
		
		for image in images?.sorted(by: { $0.offset < $1.offset }) ?? [Image]() {
			if image.isInNotes == isNotes {
				insertImageAttachment(attrString: mutableAttrString, image: image, offset: image.offset)
			}
		}
		
		return mutableAttrString
	}
	
	private func splitOffImages(attrString: NSAttributedString, isNotes: Bool) -> (NSAttributedString, [Image]) {
		guard let outline = outline else {
			fatalError("Missing Outline")
		}
		
		let mutableAttrString = NSMutableAttributedString(attributedString: attrString)
		var images = [Image]()
		
		mutableAttrString.enumerateAttribute(.attachment, in: .init(location: 0, length: mutableAttrString.length), options: []) { (attribute, range, _) in
			if let outlineTextAttachment = attribute as? OutlineTextAttachment, let imageUUID = outlineTextAttachment.imageUUID, let pngData = outlineTextAttachment.image?.pngData() {
				let entityID = EntityID.image(outline.id.accountID, outline.id.documentUUID, id, imageUUID)
				let image = Image(id: entityID, isInNotes: isNotes, offset: range.location, data: pngData)
				images.append(image)
			}
			mutableAttrString.removeAttribute(.attachment, range: range)
		}
		
		return (mutableAttrString, images)
	}
	
	func convertAttrString(_ attrString: NSAttributedString?, isInNotes: Bool) -> String? {
		if let attrString = attrString, let images = images?.filter({ $0.isInNotes == isInNotes }), !images.isEmpty {
			let result = NSMutableAttributedString(attributedString: attrString)
			let sortedImages = images.sorted(by: { $0.offset > $1.offset })
			for image in sortedImages {
				let markdown = NSAttributedString(string: "![](\(image.id.imageUUID).png)")
				result.insert(markdown, at: image.offset)
			}
			return result.markdownRepresentation
		} else {
			return attrString?.markdownRepresentation
		}
	}
	
	func convertMarkdown(_ markdown: String?, isInNotes: Bool) -> NSAttributedString? {
		guard let markdown = markdown, let regEx = try? NSRegularExpression(pattern: Self.markdownImagePattern, options: []) else {
			return nil
		}

		let mangledMarkdown = markdown.replacingOccurrences(of: "![", with: "!]")
		let attrString = NSMutableAttributedString(markdownRepresentation: mangledMarkdown, attributes: [.font : UIFont.preferredFont(forTextStyle: .body)])
		let strippedString = attrString.string
		let matches = regEx.allMatches(in: strippedString)
		
		for match in matches {
			guard let wholeRange = Range(match.range(at: 0), in: strippedString), let captureRange = Range(match.range(at: 1), in: strippedString) else {
				continue
			}
			
			let currentString = attrString.string
			let wholeString = strippedString[wholeRange]
			guard let wholeStringRange = currentString.range(of: wholeString) else {
				continue
			}
			
			let offset = currentString[currentString.startIndex..<wholeStringRange.lowerBound].utf16.count
			attrString.replaceCharacters(in: NSRange(location: offset, length: wholeString.utf16.count), with: "")

			let imageUUID = String(strippedString[captureRange])
			let imageID = EntityID.image(entityID.accountID, entityID.documentUUID, entityID.rowUUID, imageUUID)
			if let image = findImage(id: imageID) {
				insertImageAttachment(attrString: attrString, image: image, offset: offset)
			}
		}
		
		return attrString
	}
	
	func insertImageAttachment(attrString: NSMutableAttributedString, image: Image, offset: Int) {
		let attachment = OutlineTextAttachment(data: image.data, ofType: kUTTypePNG as String)
		attachment.imageUUID = image.id.imageUUID
		let imageAttrText = NSAttributedString(attachment: attachment)
		attrString.insert(imageAttrText, at: offset)
	}
	
}
