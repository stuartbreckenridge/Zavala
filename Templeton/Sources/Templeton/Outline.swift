//
//  Outline.swift
//  
//
//  Created by Maurice Parker on 11/6/20.
//

import Foundation

public final class Outline: Identifiable, Equatable, Codable {
	
	public var id: EntityID
	public var name: String?
	public var created: Date?
	public var updated: Date?
	
	enum CodingKeys: String, CodingKey {
		case id = "id"
		case name = "name"
		case created = "created"
		case updated = "updated"
	}
	
	public var account: Account? {
		return AccountManager.shared.findAccount(accountID: id.accountID)
	}
	
	public var folder: Folder? {
		let folderID = EntityID.folder(id.accountID, id.folderID)
		return AccountManager.shared.findFolder(folderID)
	}
	
	public static func == (lhs: Outline, rhs: Outline) -> Bool {
		return lhs.id == rhs.id
	}
	
	init(parentID: EntityID, name: String) {
		self.id = EntityID.outline(parentID.accountID, parentID.folderID, UUID().uuidString)
		self.name = name
		self.created = Date()
		self.updated = Date()
	}
	
}
