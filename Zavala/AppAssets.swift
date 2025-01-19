//
//  AppAssets.swift
//  Zavala
//
//  Created by Maurice Parker on 10/6/22.
//

import UIKit
import SwiftUI

extension Color {
	
	static let aboutBackgroundColor = Color("AboutBackgroundColor")
	
}

extension UIColor {
	
	static let accessoryColor = UIColor.tertiaryLabel
	static let barBackgroundColor = UIColor(named: "BarBackgroundColor")!
	static let fullScreenBackgroundColor = UIColor(named: "FullScreenBackgroundColor")!
	static let verticalBarColor = UIColor.quaternaryLabel
	static let brightenedDefaultAccentColor = UIColor.accentColor.brighten(by: 50)
	
}

extension UIImage {
	
	static let add = UIImage(systemName: "plus")!
	
	static let bold = UIImage(systemName: "bold")!
	static let bullet = UIImage(systemName: "circle.fill")!.applyingSymbolConfiguration(.init(pointSize: 4, weight: .heavy))!

	static let collaborating = UIImage(systemName: "person.crop.circle.badge.checkmark")!
	static let collapseAll = UIImage(systemName: "arrow.down.right.and.arrow.up.left")!
	static let completeRow = UIImage(systemName: "checkmark.square")!
	static let copy = UIImage(systemName: "doc.on.doc")!
	static let copyRowLink = UIImage(systemName: "link.circle")!
	static let createEntity = UIImage(systemName: "square.and.pencil")!
	static let cut = UIImage(systemName: "scissors")!

	static let delete = UIImage(systemName: "trash")!
	static let disclosure = UIImage(systemName: "chevron.down")!.applyingSymbolConfiguration(.init(pointSize: 12, weight: .medium))!
	static let documentLink = UIImage(named: "DocumentLink")!.applyingSymbolConfiguration(.init(pointSize: 24, weight: .medium))!
	static let duplicate = UIImage(systemName: "plus.square.on.square")!

	static let ellipsis = UIImage(systemName: "ellipsis.circle")!
	static let expandAll = UIImage(systemName: "arrow.up.left.and.arrow.down.right")!
	static let export = UIImage(systemName: "arrow.up.doc")!

	static let favoriteSelected = UIImage(systemName: "star.fill")!
	static let favoriteUnselected = UIImage(systemName: "star")!
	static let filterActive = UIImage(systemName: "line.horizontal.3.decrease.circle.fill")!
	static let filterInactive = UIImage(systemName: "line.horizontal.3.decrease.circle")!
	static let find = UIImage(systemName: "magnifyingglass")!
	static let focusInactive = UIImage(systemName: "eye.circle")!
	static let focusActive = UIImage(systemName: "eye.circle.fill")!
	static let format = UIImage(systemName: "textformat")!

	static let getInfo = UIImage(systemName: "info.circle")!
	static let goBackward = UIImage(systemName: "chevron.left")!
	static let goForward = UIImage(systemName: "chevron.right")!
	static let groupRows = UIImage(systemName: "increase.indent")!

	static let importDocument = UIImage(systemName: "square.and.arrow.down")!
	static let italic = UIImage(systemName: "italic")!

	static let hideKeyboard = UIImage(systemName: "keyboard.chevron.compact.down")!
	static let hideNotesActive = UIImage(systemName: "doc.text.fill")!
	static let hideNotesInactive = UIImage(systemName: "doc.text")!

	static let insertImage = UIImage(systemName: "photo")!

	static let link = UIImage(systemName: "link")!

	static let moveDown = UIImage(systemName: "arrow.down.to.line.compact")!
	static let moveLeft = UIImage(systemName: "arrow.left.to.line.compact")!
	static let moveRight = UIImage(systemName: "arrow.right.to.line.compact")!
	static let moveUp = UIImage(systemName: "arrow.up.to.line.compact")!

	static let newline = UIImage(systemName: "return")!
	static let noteAdd = UIImage(systemName: "doc.text")!
	static let noteDelete = UIImage(systemName: "doc.text.fill")!
	static let noteFont = UIImage(systemName: "textformat.size.smaller")!

	static let outline = UIImage(named: "Outline")!

	static let paste = UIImage(systemName: "doc.on.clipboard")!
	#if targetEnvironment(macCatalyst)
	static let popupChevrons = UIImage(systemName: "chevron.up.chevron.down")!.applyingSymbolConfiguration(.init(pointSize: 10, weight: .bold))!
	#else
	static let popupChevrons = UIImage(systemName: "chevron.up.chevron.down")!.applyingSymbolConfiguration(.init(pointSize: 13, weight: .medium))!
	#endif
	static let printDoc = UIImage(systemName: "printer")!
	static let printList = UIImage(systemName: "printer.dotmatrix")!
	
	static let redo = UIImage(systemName: "arrow.uturn.forward")!
	static let rename = UIImage(systemName: "pencil")!
	static let restore = UIImage(systemName: "gobackward")!

	static let settings = UIImage(systemName: "gear")!
	static let share = UIImage(systemName: "square.and.arrow.up")!
	static let sort = UIImage(systemName: "arrow.up.arrow.down")!
	static let sync = UIImage(systemName: "arrow.clockwise")!

	static let topicFont = UIImage(systemName: "textformat.size.larger")!
	
	static let uncompleteRow = UIImage(systemName: "square")!
	static let undo = UIImage(systemName: "arrow.uturn.backward")!
	static let undoMenu = UIImage(systemName: "arrow.uturn.backward.circle.badge.ellipsis")!

}

extension String {
	
	private static let dateFormatter: DateFormatter = {
		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .medium
		dateFormatter.timeStyle = .none
		return dateFormatter
	}()
	
	private static let timeFormatter: DateFormatter = {
		let timeFormatter = DateFormatter()
		timeFormatter.dateStyle = .none
		timeFormatter.timeStyle = .short
		return timeFormatter
	}()
	
	// MARK: URL's
	
	static let acknowledgementsURL = "https://github.com/vincode-io/Zavala/wiki/Acknowledgements"
	static let communityURL = "https://github.com/vincode-io/Zavala/discussions"
	static let feedbackURL = "mailto:mo@vincode.io"
	static let helpURL = "https://zavala.vincode.io/help/Zavala_Help.md/"
	static let privacyPolicyURL = "https://vincode.io/privacy-policy/"
	static let websiteURL = "https://zavala.vincode.io"
	
	// MARK: Localizable Variables
	
	static let aboutZavala = String(localized: "label.text.about-zavala", comment: "Label: About Zavala")
	static let accountsControlLabel = String(localized: "label.text.accounts", comment: "Label: Accounts")
	static let acknowledgementsControlLabel = String(localized: "label.text.acknowledgements", comment: "Label: Acknowledgements")
	static let actualSizeControlLabel = String(localized: "action.text.actual-size", comment: "View Action: Actual Size")
	static let addControlLabel = String(localized: "action.text.add", comment: "Outline Action: Add")
	static let addNoteControlLabel = String(localized: "action.text.add-note", comment: "Outline Action: Add Note")
	static let addNoteLevelControlLabel = String(localized: "action.text.add-note-level", comment: "Action: Add Note Level")
	static let addNumberingLevelControlLabel = String(localized: "action.text.add-numbering-level", comment: "Action: Add Numbering Level")
	static let addRowAboveControlLabel = String(localized: "action.text.add-row-above", comment: "Outline Action: Add Row Above")
	static let addRowAfterControlLabel = String(localized: "action.text.add-row-after", comment: "Outline Action: Add Row After")
	static let addRowBelowControlLabel = String(localized: "action.text.add-row-below", comment: "Outline Action: Add Row Below")
	static let addRowControlLabel = String(localized: "action.text.add-row", comment: "Outline Action: Add Row")
	static let addRowInsideControlLabel = String(localized: "action.text.add-row-inside", comment: "Outline Action: Add Row Inside")
	static let addRowOutsideControlLabel = String(localized: "action.text.add-row-outside", comment: "Outline Action: Add Row Outside")
	static let addTagControlLabel = String(localized: "action.text.add-tag", comment: "Outline Action: Add Tag")
	static let addTopicLevelControlLabel = String(localized: "action.text.add-topic-level", comment: "Outline Action: Add Topic Level")
	static let appHelpControlLabel = String(localized: "label.text.zavala-help", comment: "Label: Zavala Help")
	static let ascendingControlLabel = String(localized: "action.text.ascending", comment: "Sort Action: Ascending")
	static let automaticallyChangeLinkTitlesControlLabel = String(localized: "action.text.change-link-titles-automatically", comment: "Set Default Action: Change Link Titles Automatically")
	static let automaticallyCreateLinksControlLabel = String(localized: "action.text.create-links-automatically", comment: "Set Default Action: Create Links Automatically")
	static let automaticControlLabel = String(localized: "action.text.automatic-color-palette", comment: "Set App Color Palette Action: Automatic")

	static let backControlLabel = String(localized: "action.text.back", comment: "Navigation Action: Back")
	static let backlinksLabel = String(localized: "label.text.backlinks", comment: "Label: Backlinks")
	static let blueControlLabel = String(localized: "action.text.set-font-blue", comment: "Set Font Color Action: Blue")
	static let boldControlLabel = String(localized: "action.text.set-font-bold", comment: "Set Font Weight Action: Bold")
	static let brownControlLabel = String(localized: "action.text.set-font-brown", comment: "Set Font Color Action: Brown")
	static let bugTrackerControlLabel = String(localized: "label.text.bug-tracker", comment: "Label: Bug Tracker")
	
	static let cancelControlLabel = String(localized: "action.text.cancel", comment: "Action: Cancel")
	static let checkSpellingWhileTypingControlLabel = String(localized: "action.text.check-spelling-while-typing", comment: "Set Default Action: Check Spelling While Typing")
	
	static let collapseAllControlLabel = String(localized: "action.text.collapse-all", comment: "Outline Action: Collapse All")
	static let collapseAllInOutlineControlLabel = String(localized: "action.text.collapse-all-in-outline", comment: "Outline Action: Collapse All in Outline")
	static let collapseAllInRowControlLabel = String(localized: "action.text.collapse-all-in-row", comment: "Outline Action: Collapse All in Row")
	static let collapseControlLabel = String(localized: "action.text.collapse", comment: "Outline Action: Collapse")
	static let collapseParentRowControlLabel = String(localized: "outline.action.collapse-parent-row", comment: "Outline Action: Collapse Parent Row")
	static let colorPalettControlLabel = String(localized: "label.text.color-palette", comment: "Label: Color Palette")
	static let communityControlLabel = String(localized: "label.text.community-discussion", comment: "Label: Community Discussion")
	static let completeAccessibilityLabel = String(localized: "accessibility.text.complete", comment: "Accessibility Label: Complete")
	static let completeControlLabel = String(localized: "label.text.complete", comment: "Label: Complete")
	static let copyControlLabel = String(localized: "action.text.copy", comment: "Action: Copy")
	static let copyDocumentLinkControlLabel = String(localized: "action.text.copy-document-link", comment: "Document Action: Copy Document Link")
	static let copyDocumentLinksControlLabel = String(localized: "action.text.copy-document-links", comment: "Document Action: Copy Document Links")
	static let copyRowLinkControlLabel = String(localized: "action.text.copy-row-link", comment: "Document Action: Copy Row Link")
	static let correctSpellingAutomaticallyControlLabel = String(localized: "action.text.correct-spelling-automatically", comment: "Default Action: Correct Spelling Automatically")
	static let corruptedOutlineTitle = String(localized: "label.text.corrupted-outline", comment: "Label: Corrupted Outline")
	static let corruptedOutlineMessage = String(localized: "label.text.corrupted-outline-message", comment: "Alert Message: This outline appears to be corrupted. Would you like to fix it?")
	static let createdControlLabel = String(localized: "label.text.created", comment: "Label: Created")
	static let cutControlLabel = String(localized: "action.text.cut", comment: "Action: Cut")
	static let cyanControlLabel = String(localized: "action.text.set-font-cyan", comment: "Set Font Color Action: Cyan")

	static let darkControlLabel = String(localized: "action.text.set-appearance-dark", comment: "Set App Color Palette Action: Dark")
	static let deleteAlwaysControlLabel = String(localized: "action.text.always-delete-without-asking", comment: "Delete Action: Always Delete Without Asking")
	static let deleteCompletedRowsControlLabel = String(localized: "label.text.delete-completed", comment: "Label: Delete Completed Rows")
	static let deleteCompletedRowsTitle = String(localized: "label.text.delete-completed-rows", comment: "Label: Delete Completed Rows")
	static let deleteCompletedRowsMessage = String(localized: "label.text.delete-completed-rows-message", comment: "Alert Message: Are you sure you want to delete the completed rows?")
	static let deleteControlLabel = String(localized: "action.text.delete", comment: "Action: Delete")
	static let deleteOnceControlLabel = String(localized: "action.text.delete-once", comment: "Action: Delete Once")
	static let deleteOutlineControlLabel = String(localized: "action.text.delete-outline", comment: "Action: Delete Outline")
	static let deleteOutlineMessage = String(localized: "action.text.delete-outline-message", comment: "Alert Message: The outline will be deleted and unrecoverable.")
	static let deleteOutlinesMessage = String(localized: "action.text.delete-outlines-message", comment: "Alert Message: The outlines will be deleted and unrecoverable.")
	static let deleteNoteControlLabel = String(localized: "action.text.delete-note", comment: "Action: Delete Note")
	static let deleteRowControlLabel = String(localized: "action.text.delete-row", comment: "Action: Delete Row")
	static let deleteRowsControlLabel = String(localized: "action.text.delete-rows", comment: "Action: Delete Rows")
	static let deleteTagMessage = String(localized: "action.text.delete-tag-message.", comment: "Alert Message: Any child Tag associated with this Tag will also be deleted. No Outlines associated with this Tag will be deleted.")
	static let deleteTagsMessage = String(localized: "action.text.delete-tags-message.", comment: "Alert Message: Any child Tag associated with these Tags will also be deleted. No Outlines associated with these Tags will be deleted.")
	static let descendingControlLabel = String(localized: "action.text.descending", comment: "Action: Descending")
	static let disableAnimationsControlLabel = String(localized: "action.text.disable-animations", comment: "Action: Disable Animations")
	static let documentNotFoundTitle = String(localized: "label.text.document-not-found", comment: "Label: Document Not Found")
	static let documentNotFoundMessage = String(localized: "label.text.document-not-found-message", comment: "Alert Message: The requested document could not be found. It was most likely deleted and is no longer available.")
	static let doneControlLabel = String(localized: "label.text.done", comment: "Label: Done")
	static let duplicateControlLabel = String(localized: "action.text.duplicate", comment: "Action: Duplicate")
	static let duplicateRowControlLabel = String(localized: "action.text.duplicate-row", comment: "Action: Duplicate Row")
	static let duplicateRowsControlLabel = String(localized: "action.text.duplicate-rows", comment: "Label: Duplicate Rows")

	static let editorControlLabel = String(localized: "label.text.editor", comment: "Label: Editor")
	static let emailControlLabel = String(localized: "label.text.email", comment: "Label: Email")
	static let enableCloudKitControlLabel = String(localized: "action.text.enable-icloud", comment: "Label: Enable iCloud")
	static let enableOnMyIPhoneControlLabel = String(localized: "action.text.enable-iphone", comment: "Label: Enable On My iPhone")
	static let enableOnMyIPadControlLabel = String(localized: "action.text.enable-ipad", comment: "Label: Enable On My iPad")
	static let enableOnMyMacControlLabel = String(localized: "action.text.enable-mac", comment: "Label: Enable On My Mac")
	static let errorAlertTitle = String(localized: "label.text.error", comment: "Label: Error")
	static let exportControlLabel = String(localized: "action.text.export", comment: "Action: Export")
	static let exportMarkdownDocEllipsisControlLabel = String(localized: "action.text.export-markdown-doc-with-ellipsis", comment: "Action: Export Markdown Doc…")
	static let exportMarkdownListEllipsisControlLabel = String(localized: "action.text.export-markdown-list-with-ellipsis", comment: "Action: Export Markdown List…")
	static let exportPDFDocEllipsisControlLabel = String(localized: "action.text.export-pdf-doc-with-ellipsis", comment: "Action: Export PDF Doc…")
	static let exportPDFListEllipsisControlLabel = String(localized: "action.text.export-pdf-list-with-ellipsis", comment: "Action: Export PDF List…")
	static let exportOPMLEllipsisControlLabel = String(localized: "action.text.export-opml-ellipsis", comment: "Action: Export OPML…")
	static let expandAllControlLabel = String(localized: "action.text.expand-all", comment: "Action: Expand All")
	static let expandAllInOutlineControlLabel = String(localized: "action.text.expand-all-in-outline", comment: "Action: Expand All in Outline")
	static let expandAllInRowControlLabel = String(localized: "action.text.expand-all-in-row", comment: "Action: Expand All in Row")
	static let expandControlLabel = String(localized: "action.text.expand", comment: "Action: Expand")
	
	static let feedbackControlLabel = String(localized: "action.text.provide-feedback", comment: "Action: Provide Feedback")
	static let filterControlLabel = String(localized: "action.text.filter", comment: "Action: Filter")
	static let filterCompletedControlLabel = String(localized: "label.text.filter-completed", comment: "Label: Filter Completed")
	static let filterNotesControlLabel = String(localized: "action.text.filter-notes", comment: "Action: Filter Notes")
	static let findControlLabel = String(localized: "action.text.find", comment: "Action: Find")
	static let findEllipsisControlLabel = String(localized: "action.text.find-with-ellipsis", comment: "Action: Find…")
	static let findNextControlLabel = String(localized: "action.text.find-next", comment: "Action: Find Next")
	static let findPreviousControlLabel = String(localized: "action.text.find-previous", comment: "Action: Find Previous")
	static let fixItControlLabel = String(localized: "action.text.fix-it", comment: "Action: Fix It")
	static let focusInControlLabel = String(localized: "action.text.focus-in", comment: "Action: Focus In")
	static let focusOutControlLabel = String(localized: "action.text.focus-out", comment: "Action: Focus Out")
	static let fontsControlLabel = String(localized: "label.text.fonts", comment: "Label: Fonts")
	static let formatControlLabel = String(localized: "label.text.format", comment: "Label: Format")
	static let forwardControlLabel = String(localized: "action.text.forward", comment: "Action: Forward")
	static let fullWidthControlLabel = String(localized: "action.text.full-width", comment: "Action: Full Width")

	static let getInfoControlLabel = String(localized: "action.text.get-info", comment: "Action: Get Info")
	static let generalControlLabel = String(localized: "action.text.general", comment: "Action: General")
	static let gitHubRepositoryControlLabel = String(localized: "label.text.github-repository", comment: "Label: GitHub Repository")
	static let goBackwardControlLabel = String(localized: "action.text.go-backward", comment: "Action: Go Backward")
	static let goForwardControlLabel = String(localized: "action.text.go-forward", comment: "Action: Go Forward")
	static let greenControlLabel = String(localized: "action.text.set-font-green", comment: "Set Font Color Action: Green")
	static let groupRowControlLabel = String(localized: "action.text.group-row", comment: "Action: Group Row")
	static let groupRowsControlLabel = String(localized: "action.text.group-rows", comment: "Action: Group Rows")

	static let helpControlLabel = String(localized: "label.text.help", comment: "Label: Help")
	static let hideKeyboardControlLabel = String(localized: "action.text.hide-keyboard", comment: "Action: Hide Keyboard")
	static let historyControlLabel = String(localized: "label.text.history", comment: "Label: History")
	
	static let imageControlLabel = String(localized: "label.text.image", comment: "Label: Image")
	static let importFailedTitle = String(localized: "label.text.import-failed", comment: "Error Message Title: Import Failed")
	static let importOPMLControlLabel = String(localized: "action.text.import-opml", comment: "Action: Import OPML")
	static let importOPMLEllipsisControlLabel = String(localized: "action.text.import-opml-with-ellipsis", comment: "Action: Import OPML…")
	static let indigoControlLabel = String(localized: "action.text.set-font-indigo", comment: "Set Font Color Action: Indigo")
	static let insertImageControlLabel = String(localized: "action.text.insert-image", comment: "Action: Insert Image")
	static let insertImageEllipsisControlLabel = String(localized: "action.text.insert-image-with-ellipsis", comment: "Label: Insert Image…")
	static let italicControlLabel = String(localized: "action.text.italic", comment: "Set Font Action: Italic")

	static let jumpToNoteControlLabel = String(localized: "action.text.jump-to-note", comment: "Action: Jump to Note")
	static let jumpToTopicControlLabel = String(localized: "action.text.jump-to-topic", comment: "Action: Jump to Topic")

	static let largeControlLabel = String(localized: "action.text.large", comment: "Action: Large")
	static let linkControlLabel = String(localized: "label.text.link", comment: "Label: Link")
	static let linkEllipsisControlLabel = String(localized: "label.text.link-with-ellipsis", comment: "Label: Link…")
	static let lightControlLabel = String(localized: "action.text.light", comment: "Set App Appearance Action: Light")

	static let manageSharingEllipsisControlLabel = String(localized: "label.text.manage-sharing-with-ellipsis", comment: "Label: Manage Sharing…")
	static let maxWidthControlLabel = String(localized: "label.text.max-width", comment: "Label: Max Width")
	static let mediumControlLabel = String(localized: "action.text.medium", comment: "Set Appearance Action: Medium")
	static let mintControlLabel = String(localized: "action.text.mint", comment: "Set Font Color Action: Mint")
	static let moreControlLabel = String(localized: "label.text.more", comment: "Label: More")
	static let moveControlLabel = String(localized: "label.text.move", comment: "Label: Move")
	static let moveRightControlLabel = String(localized: "action.text.move-right", comment: "Action: Move Right")
	static let moveLeftControlLabel = String(localized: "action.text.move-left", comment: "Action: Move Left")
	static let moveUpControlLabel = String(localized: "action.text.move-up", comment: "Action: Move Up")
	static let moveDownControlLabel = String(localized: "action.text.move-down", comment: "Action: Move Down")
	static let multipleSelectionsLabel = String(localized: "label.text.multiple-selections", comment: "Label: Multiple Selections")
	
	static let nameControlLabel = String(localized: "label.text.name", comment: "Label: Name")
	static let navigationControlLabel = String(localized: "label.text.navigation", comment: "Label: Navigation")
	static let newMainWindowControlLabel = String(localized: "label.text.new-main-window", comment: "Label: New Main Window")
	static let newOutlineControlLabel = String(localized: "action.text.new-outline", comment: "Action: New Outline")
	static let nextResultControlLabel = String(localized: "action.text.next-result", comment: "Action: Next Result")
	static let noneControlLabel = String(localized: "label.text.none", comment: "Label: None")
	static let normalControlLabel = String(localized: "action.text.normal", comment: "Label: Normal")
	static let noSelectionLabel = String(localized: "label.text.no-selection", comment: "Label: No Selection")
	static let noTitleLabel = String(localized: "label.text.no-title", comment: "Label: (No Title)")
	static let numberingStyleControlLabel = String(localized: "label.text.numbering-style", comment: "Label: Numbering Style")

	static let openQuicklyEllipsisControlLabel = String(localized: "action.text.open-quickly-with-ellipsis", comment: "Action: Open Quickly…")
	static let openQuicklySearchPlaceholder = String(localized: "action.text.open-quickly", comment: "Action: Open Quickly")
	static let outlineControlLabel = String(localized: "label.text.outline", comment: "Label: Outline")
	static let outlineOwnerControlLabel = String(localized: "label.text.outline-owner", comment: "Label: Outline Owner")
	static let outlineDefaultsControlLabel = String(localized: "label.text.outline-defaults", comment: "Label: Outline Defaults")
	static let opmlOwnerFieldNote = String(localized: "label.text.opml-ownership-description", comment: "Label: This information is included in OPML documents to attribute ownership.")
	static let orangeControlLabel = String(localized: "action.text.orange", comment: "Set Font Color Action: Orange")
	static let ownerControlLabel = String(localized: "label.text.owner", comment: "Label: Owner")

	static let pasteControlLabel = String(localized: "action.text.paste", comment: "Action: Paste")
	static let preferencesEllipsisControlLabel = String(localized: "label.text.preferences-with-ellipsis", comment: "Label: Preferences…")
	static let previousResultControlLabel = String(localized: "action.text.previous-result", comment: "Action: Previous Result")
	static let pinkControlLabel = String(localized: "action.text.pink", comment: "Set Font Color Action: Pink")
	static let primaryTextControlLabel = String(localized: "label.text.primary-text", comment: "Label: Primary Text")
	static let printControlLabel = String(localized: "action.text.print", comment: "Action: Print")
	static let printDocControlLabel = String(localized: "action.text.print-doc", comment: "Action: Print Doc")
	static let printDocEllipsisControlLabel = String(localized: "action.text.print-doc-with-ellipsis", comment: "Action: Print Doc…")
	static let printListControlLabel = String(localized: "action.text.print-list", comment: "Action: Print List")
	static let printListControlEllipsisLabel = String(localized: "action.text.print-list-with-ellipsis", comment: "Label: Print List…")
	static let privacyPolicyControlLabel = String(localized: "label.text.privacy-policy", comment: "Label: Privacy Policy")
	static let purpleControlLabel = String(localized: "action.text.purple", comment: "Set Font Color Action: Purple")

	static let quaternaryTextControlLabel = String(localized: "label.text.quaternary-text", comment: "Label: Quaternary Text")

	static let redControlLabel = String(localized: "action.text.red", comment: "Set Font Color Action: Red")
	static let readableControlLabel = String(localized: "label.text.readable", comment: "Label: Readable")
	static let redoControlLabel = String(localized: "action.text.redo", comment: "Action: Redo")
	static let releaseNotesControlLabel = String(localized: "label.text.release-notes", comment: "Label: Release Notes")
	static let removeControlLabel = String(localized: "action.text.remove", comment: "Action: Remove")
	static let removeICloudAccountTitle = String(localized: "label.text.remove-icloud-account", comment: "Label: Remove iCloud Account")
	static let removeICloudAccountMessage = String(localized: "label.text.remove-icloud-account-message",
												   comment: "Label: Are you sure you want to remove the iCloud Account? All documents in the iCloud Account will be removed from this computer.")
	
	static let referenceLabel = String(localized: "label.text.reference", comment: "Label: Reference: ")
	static let referencesLabel = String(localized: "label.text.references", comment: "Label: References: ")
	static let removeTagControlLabel = String(localized: "action.text.remove-tag", comment: "Action: Remove Tag")
	static let renameControlLabel = String(localized: "action.text.rename", comment: "Action: Rename")
	static let replaceControlLabel = String(localized: "action.text.replace", comment: "Action: Replace")
	static let restoreControlLabel = String(localized: "action.text.restore", comment: "Action: Restore")
	static let restoreDefaultsMessage = String(localized: "label.text.restore-defaults", comment: "Label: Restore Defaults")
	static let restoreDefaultsInformative = String(localized: "label.text.restore-defaults-message",
												   comment: "Label: Are you sure you want to restore the defaults? All your font customizations will be lost.")
	static let rowIndentControlLabel = String(localized: "label.text.row-indent", comment: "Label: Row Indent")
	static let rowSpacingControlLabel = String(localized: "label.text.row-spacing", comment: "Label: Row Spacing")

	static let saveControlLabel = String(localized: "action.text.save", comment: "Action: Save")
	static let scrollModeControlLabel = String(localized: "label.text.scroll-mode", comment: "Label: Scroll Mode")
	static let searchPlaceholder = String(localized: "label.text.search", comment: "Label: Search")
	static let secondaryTextControlLabel = String(localized: "label.text.secondary-text", comment: "Label: Secondary Text")
	static let selectControlLabel = String(localized: "action.text.select", comment: "Action: Select")
	static let settingsControlLabel = String(localized: "label.text.settings", comment: "Label: Settings")
	static let settingsEllipsisControlLabel = String(localized: "label.text.settings-with-ellipsis", comment: "Label: Settings…")
	static let shareControlLabel = String(localized: "action.text.share", comment: "Action: Share")
	static let shareEllipsisControlLabel = String(localized: "action.text.share-with-ellipsis", comment: "Label: Share…")
	static let smallControlLabel = String(localized: "action.text.small", comment: "Action: Small")
	static let sortDocumentsControlLabel = String(localized: "action.text.sort-documents", comment: "Action: Sort Documents")
	static let sortRowsControlLabel = String(localized: "action.text.sort-rows", comment: "Action: Sort Rows")
	static let splitRowControlLabel = String(localized: "action.text.split-row", comment: "Action: Split Row")
	static let statisticsControlLabel = String(localized: "label.text.statistics", comment: "Label: Statistics")
	static let syncControlLabel = String(localized: "action.text.sync", comment: "Label: Sync")
	
	static let tagsLabel = String(localized: "label.text.tags", comment: "Label: Tags")
	static let tagDataEntryPlaceholder = String(localized: "label.text.tag", comment: "Label: Tag")
	static let tealControlLabel = String(localized: "action.text.teal", comment: "Set Font Color Appearance: Teal")
	static let tertiaryTextControlLabel = String(localized: "label.text.tertiary-text", comment: "Label: Tertiary Text")
	static let titleLabel = String(localized: "label.text.title", comment: "Font Label: Title")
	static let togglerSidebarControlLabel = String(localized: "action.text.toggle-sidebar", comment: "Action: Toggle Sidebar")
	static let turnFilterOffControlLabel = String(localized: "action.text.turn-filter-off", comment: "Action: Turn Filter Off")
	static let turnFilterOnControlLabel = String(localized: "action.text.turn-filter-on", comment: "Label: Turn Filter On")
	static let typingControlLabel = String(localized: "label.text.typing", comment: "Label: Typing")
	static let typewriterCenterControlLabel = String(localized: "label.text.typewriter", comment: "Label: Typewriter")

	static let uncompleteControlLabel = String(localized: "Uncomplete", comment: "Label: Uncomplete")
	static let undoControlLabel = String(localized: "Undo", comment: "Label: Undo")
	static let undoMenuControlLabel = String(localized: "Undo Menu", comment: "Label: Undo Menu")
	static let updatedControlLabel = String(localized: "Updated", comment: "Label: Updated")
	static let urlControlLabel = String(localized: "URL", comment: "Label: URL")
	static let useSelectionForFindControlLabel = String(localized: "Use Selection For Find", comment: "Label: Use Selection For Find")
	static let useMainWindowAsDefaultControlLabel = String(localized: "Use Main Window as Default", comment: "Label: Use Main Window as Default")
 
	static let websiteControlLabel = String(localized: "Website", comment: "Label: Website")
	static let wideControlLabel = String(localized: "Wide", comment: "Label: Wide")
	static let wordCountLabel = String(localized: "Word Count", comment: "Label: Word Count")

	static let yellowControlLabel = String(localized: "Yellow", comment: "Label: Yellow")

	static let zavalaHelpControlLabel = String(localized: "Zavala Help", comment: "Label: Zavala Help")
	static let zoomInControlLabel = String(localized: "Zoom In", comment: "Label: Zoom In")
	static let zoomOutControlLabel = String(localized: "Zoom Out", comment: "Label: Zoom Out")

	// MARK: Localizable Functions
	
	static func createdOnLabel(date: Date) -> String {
		let dateString = dateFormatter.string(from: date)
		let timeString = timeFormatter.string(from: date)
		return String(localized: "\(dateString) at \(timeString)", comment: "Timestame Label: Created")
	}
	
	static func updatedOnLabel(date: Date) -> String {
		let dateString = dateFormatter.string(from: date)
		let timeString = timeFormatter.string(from: date)
		return String(localized: "\(dateString) at \(timeString)", comment: "Timestame Label: Updated")
	}
	
	static func deleteOutlinePrompt(outlineTitle: String) -> String {
		return String(localized: "label.text.delete-outline-confirmation-message-\(outlineTitle)", comment: "Alert Title: Are you sure you want to delete the “Outline Title” outline?")
	}
	
	static func deleteTagPrompt(tagName: String) -> String {
		return String(localized: "label.text.delete-tag-confirmation-message-\(tagName)", comment: "Alert Title: Are you sure you want to delete the “Tag Name” tag?")
	}
	
	static func deleteTagsPrompt(tagCount: Int) -> String {
		return String(localized: "label.text.delete-multiple-tags-confirmation-message-\(tagCount)", comment: "Alert Title: Are you sure you want to delete tagCount tags?")
	}
	
	@available(*, deprecated, renamed: "deleteOutlinePrompt(outlineTitle:)", message: "Duplicate of deleteOutlinePrompt(outlineTitle:)")
	static func deleteOutlinePrompt(outlineName: String) -> String {
		return String(localized: "Are you sure you want to delete the “\(outlineName)” outline?", comment: "Confirmation: delete outline?")
	}
	
	static func deleteOutlinesPrompt(outlineCount: Int) -> String {
		return String(localized: "Are you sure you want to delete \(outlineCount) outlines?", comment: "Confirmation: delete outlines?")
	}

	
	static func seeDocumentsInPrompt(documentContainerTitle: String) -> String {
		return String(localized: "See documents in “\(documentContainerTitle)”", comment: "Prompt: see documents in document container")
	}
	
	static func editDocumentPrompt(documentTitle: String) -> String {
		return String(localized: "Edit document “\(documentTitle)”", comment: "Prompt: edit document")
	}
	
	static func numberingLevelLabel(level: Int) -> String {
		return String(localized: "Numbering Level \(level)", comment: "Font Label: The font for the given Numbering Level")
	}
	
	static func topicLevelLabel(level: Int) -> String {
		return String(localized: "Topic Level \(level)", comment: "Font Label: The font for the given Topic Level")
	}
	
	static func noteLevelLabel(level: Int) -> String {
		return String(localized: "Note Level \(level)", comment: "Font Label: The font for the given Note Level")
	}
	
	static func copyrightLabel() -> String {
		let year = String(Calendar.current.component(.year, from: Date()))
		return String(localized: "Copyright © Vincode, Inc. 2020-\(year)", comment: "About Box copyright information")
	}
	
}
