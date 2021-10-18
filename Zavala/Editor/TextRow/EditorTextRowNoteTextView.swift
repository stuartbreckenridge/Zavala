//
//  EditorTextRowNoteTextView.swift
//  Zavala
//
//  Created by Maurice Parker on 12/13/20.
//

import UIKit
import Templeton

protocol EditorTextRowNoteTextViewDelegate: AnyObject {
	var editorRowNoteTextViewUndoManager: UndoManager? { get }
	var editorRowNoteTextViewInputAccessoryView: UIView? { get }
	func invalidateLayout(_ : EditorTextRowNoteTextView)
	func makeCursorVisibleIfNecessary(_ : EditorTextRowNoteTextView)
	func didBecomeActive(_ : EditorTextRowNoteTextView, row: Row)
	func textChanged(_ : EditorTextRowNoteTextView, row: Row, isInNotes: Bool, selection: NSRange, rowStrings: RowStrings)
	func deleteRowNote(_ : EditorTextRowNoteTextView, row: Row, rowStrings: RowStrings)
	func moveCursorTo(_ : EditorTextRowNoteTextView, row: Row)
	func moveCursorDown(_ : EditorTextRowNoteTextView, row: Row)
	func editLink(_: EditorTextRowNoteTextView, _ link: String?, text: String?, range: NSRange)
}

class EditorTextRowNoteTextView: EditorTextRowTextView {
	
	override var editorUndoManager: UndoManager? {
		return editorDelegate?.editorRowNoteTextViewUndoManager
	}
	
	override var keyCommands: [UIKeyCommand]? {
		var keys = [UIKeyCommand]()
		if cursorPosition == 0 {
			keys.append(UIKeyCommand(action: #selector(moveCursorToText(_:)), input: UIKeyCommand.inputUpArrow))
		}
		if cursorPosition == attributedText.length {
			keys.append(UIKeyCommand(action: #selector(moveCursorDown(_:)), input: UIKeyCommand.inputDownArrow))
		}
		keys.append(UIKeyCommand(action: #selector(moveCursorToText(_:)), input: UIKeyCommand.inputEscape))
		keys.append(toggleBoldCommand)
		keys.append(toggleItalicsCommand)
		keys.append(editLinkCommand)
		return keys
	}
	
	weak var editorDelegate: EditorTextRowNoteTextViewDelegate?
	
	override var rowStrings: RowStrings {
		return RowStrings.note(cleansedAttributedText)
	}
	
	private var autosaveWorkItem: DispatchWorkItem?
	private var textViewHeight: CGFloat?
	private var isSavingTextUnnecessary = false

	override init(frame: CGRect, textContainer: NSTextContainer?) {
		super.init(frame: frame, textContainer: textContainer)
		
		self.delegate = self

		self.textColor = .secondaryLabel
		self.linkTextAttributes = [.foregroundColor: UIColor.secondaryLabel, .underlineStyle: 1]
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	@discardableResult
	override func becomeFirstResponder() -> Bool {
		if traitCollection.userInterfaceIdiom == .phone {
			inputAccessoryView = editorDelegate?.editorRowNoteTextViewInputAccessoryView
		}
		let result = super.becomeFirstResponder()
		didBecomeActive()
		return result
	}
	
	override func resignFirstResponder() -> Bool {
		if let row = row {
			CursorCoordinates.lastKnownCoordinates = CursorCoordinates(row: row, isInNotes: true, selection: selectedRange)
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
		if attributedText.length == 0 {
			isSavingTextUnnecessary = true
			editorDelegate?.deleteRowNote(self, row: textRow, rowStrings: rowStrings)
		} else {
			super.deleteBackward()
		}
	}

	@objc func moveCursorToText(_ sender: Any) {
		guard let textRow = row else { return }
		editorDelegate?.moveCursorTo(self, row: textRow)
	}
	
	@objc func moveCursorDown(_ sender: Any) {
		guard let textRow = row else { return }
		editorDelegate?.moveCursorDown(self, row: textRow)
	}

	@objc override func editLink(_ sender: Any?) {
		let result = findAndSelectLink()
		editorDelegate?.editLink(self, result.0, text: result.1, range: result.2)
	}
	
	override func saveText() {
		guard isTextChanged, let textRow = row else { return }
		
		if isSavingTextUnnecessary {
			isSavingTextUnnecessary = false
		} else {
			editorDelegate?.textChanged(self, row: textRow, isInNotes: true, selection: selectedRange, rowStrings: rowStrings)
		}
		
		autosaveWorkItem?.cancel()
		autosaveWorkItem = nil
		isTextChanged = false
	}
	
	override func updateLinkForCurrentSelection(text: String, link: String?, range: NSRange) {
		super.updateLinkForCurrentSelection(text: text, link: link, range: range)
		textStorage.replaceFont(with: OutlineFontCache.shared.note(level: indentionLevel))
		isTextChanged = true
		saveText()
	}
	
	override func indentionLevelWasUpdated() {
		font = OutlineFontCache.shared.note(level: indentionLevel)
	}
	
}

// MARK: CursorCoordinatesProvider

extension EditorTextRowNoteTextView: CursorCoordinatesProvider {

	var coordinates: CursorCoordinates? {
		if let row = row {
			return CursorCoordinates(row: row, isInNotes: true, selection: selectedRange)
		}
		return nil
	}

}

// MARK: UITextViewDelegate

extension EditorTextRowNoteTextView: UITextViewDelegate {
	
	func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
		let fittingSize = textView.sizeThatFits(CGSize(width: textView.frame.width, height: CGFloat.greatestFiniteMagnitude))
		textViewHeight = fittingSize.height
		return true
	}
	
	func textViewDidEndEditing(_ textView: UITextView) {
		detectData()
		saveText()
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
		if let currentHeight = textViewHeight, abs(fittingSize.height - currentHeight) > OutlineFontCache.shared.note(level: indentionLevel).capHeight / 2  {
			textViewHeight = fittingSize.height
			editorDelegate?.invalidateLayout(self)
		}
		
		editorDelegate?.makeCursorVisibleIfNecessary(self)

		autosaveWorkItem?.cancel()
		autosaveWorkItem = DispatchWorkItem { [weak self] in
			self?.saveText()
		}
		DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: autosaveWorkItem!)
	}
	
}
