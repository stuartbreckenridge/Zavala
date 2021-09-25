//
//  EditorTextRowTopicTextView.swift
//  Zavala
//
//  Created by Maurice Parker on 11/17/20.
//

import UIKit
import Templeton

protocol EditorTextRowTopicTextViewDelegate: AnyObject {
	var editorRowTopicTextViewUndoManager: UndoManager? { get }
	var editorRowTopicTextViewTextRowStrings: TextRowStrings { get }
	var editorRowTopicTextViewInputAccessoryView: UIView? { get }
	func didBecomeActive(_: EditorTextRowTopicTextView, row: Row)
	func invalidateLayout(_: EditorTextRowTopicTextView)
	func textChanged(_: EditorTextRowTopicTextView, row: Row, isInNotes: Bool, selection: NSRange)
	func deleteRow(_: EditorTextRowTopicTextView, row: Row)
	func createRow(_: EditorTextRowTopicTextView, beforeRow: Row)
	func createRow(_: EditorTextRowTopicTextView, afterRow: Row)
	func indentRow(_: EditorTextRowTopicTextView, row: Row)
	func splitRow(_: EditorTextRowTopicTextView, row: Row, topic: NSAttributedString, cursorPosition: Int)
	func editLink(_: EditorTextRowTopicTextView, _ link: String?, text: String?, range: NSRange)
}

class EditorTextRowTopicTextView: EditorTextRowTextView {
	
	override var editorUndoManager: UndoManager? {
		return editorDelegate?.editorRowTopicTextViewUndoManager
	}
	
	override var keyCommands: [UIKeyCommand]? {
		let keys = [
			UIKeyCommand(action: #selector(indent(_:)), input: "\t"),
			UIKeyCommand(input: "\t", modifierFlags: [.alternate], action: #selector(insertTab(_:))),
			UIKeyCommand(input: "\r", modifierFlags: [.alternate], action: #selector(insertReturn(_:))),
			UIKeyCommand(input: "\r", modifierFlags: [.shift], action: #selector(insertRow(_:))),
			UIKeyCommand(input: "\r", modifierFlags: [.shift, .alternate], action: #selector(split(_:))),
			toggleBoldCommand,
			toggleItalicsCommand,
			editLinkCommand
		]
		return keys
	}
	
	weak var editorDelegate: EditorTextRowTopicTextViewDelegate?
	
	override var textRowStrings: TextRowStrings? {
		return editorDelegate?.editorRowTopicTextViewTextRowStrings
	}
	
	var cursorIsOnTopLine: Bool {
		guard let cursorRect = cursorRect else { return false }
		let lineStart = closestPosition(to: CGPoint(x: 0, y: cursorRect.midY))
		return lineStart == beginningOfDocument
	}
	
	var cursorIsOnBottomLine: Bool {
		guard let cursorRect = cursorRect else { return false }
		let lineEnd = closestPosition(to: CGPoint(x: bounds.maxX, y: cursorRect.midY))
		return lineEnd == endOfDocument
	}
	
	private var autosaveWorkItem: DispatchWorkItem?
	private var textViewHeight: CGFloat?
	private var isSavingTextUnnecessary = false

	override init(frame: CGRect, textContainer: NSTextContainer?) {
		super.init(frame: frame, textContainer: textContainer)
		self.delegate = self
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	@discardableResult
	override func becomeFirstResponder() -> Bool {
		if traitCollection.userInterfaceIdiom == .phone {
			inputAccessoryView = editorDelegate?.editorRowTopicTextViewInputAccessoryView
		}
		let result = super.becomeFirstResponder()
		didBecomeActive()
		return result
	}
	
	override func resignFirstResponder() -> Bool {
		if let textRow = row {
			CursorCoordinates.lastKnownCoordinates = CursorCoordinates(row: textRow, isInNotes: false, selection: selectedRange)
		}
		return super.resignFirstResponder()
	}
	
	override func didBecomeActive() {
		if let row = row {
			editorDelegate?.didBecomeActive(self, row: row)
		}
	}

	override func invalidateLayout() {
		editorDelegate?.invalidateLayout(self)
	}
	
	override func deleteBackward() {
		guard let textRow = row else { return }
		if attributedText.length == 0 && textRow.rowCount == 0 {
			editorDelegate?.deleteRow(self, row: textRow)
		} else {
			super.deleteBackward()
		}
	}

	@objc func createRow(_ sender: Any) {
		guard let textRow = row else { return }
		editorDelegate?.createRow(self, afterRow: textRow)
	}
	
	@objc func indent(_ sender: Any) {
		guard let textRow = row else { return }
		editorDelegate?.indentRow(self, row: textRow)
	}
	
	@objc func insertTab(_ sender: Any) {
		insertText("\t")
	}
	
	@objc func insertReturn(_ sender: Any) {
		insertText("\n")
	}
	
	@objc func insertRow(_ sender: Any) {
		guard let textRow = row else { return }
		isSavingTextUnnecessary = true
		editorDelegate?.createRow(self, beforeRow: textRow)
	}

	@objc func split(_ sender: Any) {
		guard let textRow = row else { return }
		
		isSavingTextUnnecessary = true
		
		if cursorPosition == 0 {
			editorDelegate?.createRow(self, beforeRow: textRow)
		} else {
			editorDelegate?.splitRow(self, row: textRow, topic: attributedText, cursorPosition: cursorPosition)
		}
	}
	
	@objc override func editLink(_ sender: Any?) {
		let result = findAndSelectLink()
		editorDelegate?.editLink(self, result.0, text: result.1, range: result.2)
	}
	
	override func rowWasUpdated() {
		if row?.isComplete ?? false {
			linkTextAttributes = [.foregroundColor: UIColor.tertiaryLabel, .underlineStyle: 1]
		} else {
			linkTextAttributes = [.foregroundColor: UIColor.label, .underlineStyle: 1]
		}
	}
	
	override func indentionLevelWasUpdated() {
		font = OutlineFontCache.shared.topic(level: indentionLevel)
	}
	
	override func saveText() {
		guard isTextChanged, let textRow = row else { return }
		
		if isSavingTextUnnecessary {
			isSavingTextUnnecessary = false
		} else {
			editorDelegate?.textChanged(self, row: textRow, isInNotes: false, selection: selectedRange)
		}
		
		autosaveWorkItem?.cancel()
		autosaveWorkItem = nil
		isTextChanged = false
	}
	
	override func updateLinkForCurrentSelection(text: String, link: String?, range: NSRange) {
		super.updateLinkForCurrentSelection(text: text, link: link, range: range)
		textStorage.replaceFont(with: OutlineFontCache.shared.topic(level: indentionLevel))
		isTextChanged = true
		saveText()
	}
	
}

// MARK: CursorCoordinatesProvider

extension EditorTextRowTopicTextView: CursorCoordinatesProvider {

	var coordinates: CursorCoordinates? {
		if let row = row {
			return CursorCoordinates(row: row, isInNotes: false, selection: selectedRange)
		}
		return nil
	}

}

// MARK: UITextViewDelegate

extension EditorTextRowTopicTextView: UITextViewDelegate {
	
	func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
		let fittingSize = textView.sizeThatFits(CGSize(width: textView.frame.width, height: CGFloat.greatestFiniteMagnitude))
		textViewHeight = fittingSize.height
		return true
	}
	
	func textViewDidEndEditing(_ textView: UITextView) {
		detectData()
		saveText()
	}
	
	func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
		guard let textRow = row else { return true }
		switch text {
		case "\n":
			editorDelegate?.createRow(self, afterRow: textRow)
			return false
		default:
			return true
		}
	}
	
	func textViewDidChange(_ textView: UITextView) {
		// Break any links with a space
		if textView.textStorage.length > 0 {
			let range = NSRange(location: textStorage.length - 1, length: 1)
			if textView.textStorage.attributedSubstring(from: range).string == " " {
				textView.textStorage.removeAttribute(.link, range: range)
			}
		}
		
		isTextChanged = true

		let fittingSize = textView.sizeThatFits(CGSize(width: textView.frame.width, height: CGFloat.greatestFiniteMagnitude))
		if let currentHeight = textViewHeight, abs(fittingSize.height - currentHeight) > OutlineFontCache.shared.topic(level: indentionLevel).capHeight / 2  {
			textViewHeight = fittingSize.height
			editorDelegate?.invalidateLayout(self)
		}
		
		autosaveWorkItem?.cancel()
		autosaveWorkItem = DispatchWorkItem { [weak self] in
			self?.saveText()
		}
		DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: autosaveWorkItem!)
	}
	
}
