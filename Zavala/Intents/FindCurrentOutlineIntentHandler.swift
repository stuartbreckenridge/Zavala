//
//  FindCurrentOutlineIntentHandler.swift
//  Zavala
//
//  Created by Maurice Parker on 9/28/21.
//

import Intents

public class FindCurrentOutlineIntentHandler: NSObject, FindCurrentOutlineIntentHandling {
	
	private weak var mainCoordinator: MainCoordinator?
	
	init(mainCoordinator: MainCoordinator?) {
		self.mainCoordinator = mainCoordinator
	}
	
	public func handle(intent: FindCurrentOutlineIntent, completion: @escaping (FindCurrentOutlineIntentResponse) -> Void) {
		guard let outline = mainCoordinator?.currentOutline else {
			completion(FindCurrentOutlineIntentResponse(code: .notFound, userActivity: nil))
			return
		}
		
		let response = FindCurrentOutlineIntentResponse(code: .success, userActivity: nil)
		response.outline = IntentOutline(identifier: outline.id.description, display: outline.title ?? "")
		completion(response)
	}
		
}