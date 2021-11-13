//
//  EditorTextRowContentConfiguration.swift
//  Zavala
//
//  Created by Maurice Parker on 11/17/20.
//

import UIKit
import Templeton

struct EditorTextRowContentConfiguration: UIContentConfiguration {

	weak var delegate: EditorTextRowViewCellDelegate? = nil

	var row: Row? = nil
	var indentationWidth: CGFloat
	var isNotesHidden: Bool
	var isSearching: Bool
	
	init(row: Row, indentionLevel: Int, indentationWidth: CGFloat, isNotesHidden: Bool, isSearching: Bool) {
		self.row = row
		self.indentationWidth = indentationWidth
		self.isNotesHidden = isNotesHidden
		self.isSearching = isSearching
	}
	
	func makeContentView() -> UIView & UIContentView {
		return EditorTextRowContentView(configuration: self)
	}
	
	func updated(for state: UIConfigurationState) -> Self {
		return self
	}

}
