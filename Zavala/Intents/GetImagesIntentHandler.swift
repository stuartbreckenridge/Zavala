//
//  GetImagesIntentHandler.swift
//  Zavala
//
//  Created by Maurice Parker on 10/7/21.
//

import Intents
import Templeton

class GetImagesIntentHandler: NSObject, ZavalaIntentHandler, GetImagesIntentHandling {

	func handle(intent: GetImagesIntent, completion: @escaping (GetImagesIntentResponse) -> Void) {
		resume()

		guard let intentOutline = intent.outline,
			  let outlineIdentifier = intentOutline.identifier,
			  let id = EntityID(description: outlineIdentifier),
			  let outline = AccountManager.shared.findDocument(id)?.outline else {
				  suspend()
				  completion(GetImagesIntentResponse(code: .failure, userActivity: nil))
				  return
			  }
		
		var files = [INFile]()
		
		outline.loadImages()
		
		guard let imageGroups = outline.images?.values, !imageGroups.isEmpty else {
			suspend()
			completion(GetImagesIntentResponse(code: .success, userActivity: nil))
			return
		}

		let allImages = imageGroups.flatMap({ $0 })
		
		for image in allImages {
			let file = INFile(data: image.data, filename: "\(image.id.imageUUID).png", typeIdentifier: "public.png")
			files.append(file)
		}
		
		outline.unloadImages()
		
		let response = GetImagesIntentResponse(code: .success, userActivity: nil)
		response.images = files
		suspend()
		completion(response)
	}
	
}
