//
//  Created by Maurice Parker on 7/6/24.
//

import Foundation
import AppIntents

enum AccountTypeAppEnum: String, AppEnum {
    case onMyDevice
    case iCloud

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Account Type")
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
		.onMyDevice: DisplayRepresentation(title: LocalizedStringResource("label.text.on-my-device", comment: "On My <device>")),
		.iCloud: "iCloud" // Don't translate
    ]
}

