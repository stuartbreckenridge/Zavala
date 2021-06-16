//
//  PrintVisitor.swift
//  
//
//  Created by Maurice Parker on 4/14/21.
//

import UIKit

class PrintVisitor {
	
	var indentLevel = 0
	var print = NSMutableAttributedString()

	func visitor(_ visited: Row) {
		guard let textRow = visited.textRow else { return }
		
		if let topic = textRow.topic {
			var attrs = [NSAttributedString.Key : Any]()
			if textRow.isComplete || textRow.isAncestorComplete {
				attrs[.foregroundColor] = UIColor.darkGray
			} else {
				attrs[.foregroundColor] = UIColor.black
			}
			
			if textRow.isComplete {
				attrs[.strikethroughStyle] = 1
				attrs[.strikethroughColor] = UIColor.darkGray
			} else {
				attrs[.strikethroughStyle] = 0
			}

			let topicFont = UIFont.systemFont(ofSize: 12)
			let topicParagraphStyle = NSMutableParagraphStyle()
			topicParagraphStyle.paragraphSpacing = 0.33 * topicFont.lineHeight
			topicParagraphStyle.firstLineHeadIndent = CGFloat(indentLevel * 20)
			topicParagraphStyle.headIndent = CGFloat(indentLevel * 20)
			attrs[.paragraphStyle] = topicParagraphStyle
			
			let printTopic = NSMutableAttributedString(attributedString: topic)
			let range = NSRange(location: 0, length: printTopic.length)
			printTopic.addAttributes(attrs, range: range)
			printTopic.replaceFont(with: topicFont)

			print.append(printTopic)
		}
		
		if let note = textRow.note {
			var attrs = [NSAttributedString.Key : Any]()
			attrs[.foregroundColor] = UIColor.darkGray

			let noteFont: UIFont
			if let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body).withDesign(.serif) {
				noteFont = UIFont(descriptor: descriptor, size: 11)
			} else {
				noteFont = UIFont.systemFont(ofSize: 11)
			}

			let noteParagraphStyle = NSMutableParagraphStyle()
			noteParagraphStyle.paragraphSpacing = 0.33 * noteFont.lineHeight
			noteParagraphStyle.firstLineHeadIndent = CGFloat(indentLevel * 20)
			noteParagraphStyle.headIndent = CGFloat(indentLevel * 20)
			attrs[.paragraphStyle] = noteParagraphStyle

			let noteTopic = NSMutableAttributedString(string: "\n")
			noteTopic.append(note)
			let range = NSRange(location: 0, length: noteTopic.length)
			noteTopic.addAttributes(attrs, range: range)
			noteTopic.replaceFont(with: noteFont)

			print.append(noteTopic)
		}
		
		indentLevel = indentLevel + 1
		textRow.rows.forEach {
			print.append(NSAttributedString(string: "\n"))
			$0.visit(visitor: self.visitor)
		}
		indentLevel = indentLevel - 1
	}
}