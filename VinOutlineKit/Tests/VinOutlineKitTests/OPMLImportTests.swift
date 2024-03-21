//
//  OPMLImport.swift
//  
//
//  Created by Maurice Parker on 3/16/24.
//

import XCTest

final class OPMLImportTests: VOKTestCase {

    func testImport() throws {
		let outline = try loadOutline()
		XCTAssertEqual(outline.rows.count, 6)
    }

}
