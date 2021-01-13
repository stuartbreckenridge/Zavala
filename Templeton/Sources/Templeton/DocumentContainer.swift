//
//  DocumentContainer.swift
//  
//
//  Created by Maurice Parker on 11/9/20.
//

import Foundation
import RSCore

public protocol DocumentContainer {
	var id: EntityID { get }
	var name: String? { get }
	var image: RSImage? { get }
	
	var isSmartContainer: Bool { get } 
	func documents(completion: @escaping (Result<[Document], Error>) -> Void)
	func sortedDocuments(completion: @escaping (Result<[Document], Error>) -> Void)
}

public extension DocumentContainer {
	
	var isSmartContainer: Bool {
		return id.isSmartContainer
	}

	static func sortByUpdate(_ documents: [Document]) -> [Document] {
		return documents.sorted(by: { $0.updated ?? Date.distantPast > $1.updated ?? Date.distantPast })
	}

	static func sortByTitle(_ documents: [Document]) -> [Document] {
		return documents.sorted(by: { ($0.title ?? "").caseInsensitiveCompare($1.title ?? "") == .orderedAscending })
	}

}

public struct LazyDocumentContainer: DocumentContainer {
	
	public var id: EntityID
	
	public var name: String? {
		switch id {
		case .all:
			return L10n.providerAll
		case .favorites:
			return L10n.providerFavorites
		case .recents:
			return L10n.providerRecents
		default:
			fatalError()
		}
	}
	
	public var image: RSImage? {
		switch id {
		case .all:
			return RSImage(systemName: "tray")
		case .favorites:
			return RSImage(systemName: "star.circle")
		case .recents:
			return RSImage(systemName: "clock")
		default:
			fatalError()
		}
	}

	public func documents(completion: @escaping (Result<[Document], Error>) -> Void) {
		completion(.success(documentCallback()))
	}
	
	public func sortedDocuments(completion: @escaping (Result<[Document], Error>) -> Void) {
		completion(.success(documentCallback()))
	}
	
	private var documentCallback: (() -> [Document])
	
	init(id: EntityID, callback: @escaping (() -> [Document])) {
		self.id = id
		self.documentCallback = callback
	}
	
}
