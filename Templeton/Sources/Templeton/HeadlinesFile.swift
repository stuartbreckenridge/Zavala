//
//  HeadlinesFile.swift
//  
//
//  Created by Maurice Parker on 11/15/20.
//

import Foundation
import os.log
import RSCore

final class HeadlinesFile {
	
	private var log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "HeadlinesFile")

	private weak var outline: Outline?
	private let fileURL: URL
	private lazy var managedFile = ManagedResourceFile(fileURL: fileURL,
													   load: { [weak self] in self?.loadCallback() },
													   save: { [weak self] in self?.saveCallback() })
	private var lastModificationDate: Date?
	
	init(outline: Outline) {
		self.outline = outline
		let localAccountFolder = AccountManager.shared.accountsFolder.appendingPathComponent(outline.account!.type.folderName)
		fileURL = localAccountFolder.appendingPathComponent("\(outline.id.outlineUUID).json")
	}
	
	func markAsDirty() {
		managedFile.markAsDirty()
	}
	
	func load() {
		managedFile.load()
	}
	
	func save() {
		managedFile.saveIfNecessary()
	}
	
	func delete() {
		do {
			try FileManager.default.removeItem(atPath: fileURL.path)
		} catch {
			os_log(.error, log: log, "Delete headline file from disk failed: %@.", error.localizedDescription)
		}
	}
	
}

private extension HeadlinesFile {

	func loadCallback() {
		var fileData: Data? = nil
		let errorPointer: NSErrorPointer = nil
		let fileCoordinator = NSFileCoordinator(filePresenter: managedFile)
		
		fileCoordinator.coordinate(readingItemAt: fileURL, options: [], error: errorPointer, byAccessor: { readURL in
			do {
				let resourceValues = try readURL.resourceValues(forKeys: [.contentModificationDateKey])
				guard lastModificationDate != resourceValues.contentModificationDate else {
					return
				}
				lastModificationDate = resourceValues.contentModificationDate

				fileData = try Data(contentsOf: readURL)
			} catch {
				// Ignore this.  It will get called everytime we create a new Outline
			}
		})
		
		if let error = errorPointer?.pointee {
			os_log(.error, log: log, "Headlines read from disk coordination failed: %@.", error.localizedDescription)
		}

		guard let headlinesData = fileData else {
			return
		}

		let decoder = JSONDecoder()
		let headlines: [Headline]
		do {
			headlines = try decoder.decode([Headline].self, from: headlinesData)
		} catch {
			os_log(.error, log: log, "Headlines read deserialization failed: %@.", error.localizedDescription)
			return
		}

		outline?.headlines = headlines
	}
	
	func saveCallback() {
		guard let headlines = outline?.headlines else { return }
		let encoder = JSONEncoder()
		let headlinesData: Data
		do {
			headlinesData = try encoder.encode(headlines)
		} catch {
			os_log(.error, log: log, "Account read deserialization failed: %@.", error.localizedDescription)
			return
		}

		let errorPointer: NSErrorPointer = nil
		let fileCoordinator = NSFileCoordinator(filePresenter: managedFile)
		
		fileCoordinator.coordinate(writingItemAt: fileURL, options: [], error: errorPointer, byAccessor: { writeURL in
			do {
				try headlinesData.write(to: writeURL)
				let resourceValues = try writeURL.resourceValues(forKeys: [.contentModificationDateKey])
				lastModificationDate = resourceValues.contentModificationDate
			} catch let error as NSError {
				os_log(.error, log: log, "Account save to disk failed: %@.", error.localizedDescription)
			}
		})
		
		if let error = errorPointer?.pointee {
			os_log(.error, log: log, "Account save to disk coordination failed: %@.", error.localizedDescription)
		}
	}
	
}

