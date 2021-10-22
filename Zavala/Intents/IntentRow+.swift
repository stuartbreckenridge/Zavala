//
//  IntentRow+.swift
//  Zavala
//
//  Created by Maurice Parker on 10/21/21.
//

import Foundation
import Templeton

extension IntentRow {
	
	convenience init(_ row: Row) {
		self.init(identifier: row.entityID.description, display: row.topicMarkdown ?? "")
		entityID = IntentEntityID(row.entityID)
		
		topic = row.topicMarkdown
		note = row.noteMarkdown
		
		complete = NSNumber(booleanLiteral: row.isComplete)
		expanded = NSNumber(booleanLiteral: row.isExpanded)
		level = NSNumber(integerLiteral: row.level)
	}
	
}
