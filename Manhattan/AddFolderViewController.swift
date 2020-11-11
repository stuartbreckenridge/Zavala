//
//  AddFolderViewController.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/11/20.
//

import UIKit
import Templeton

class AddFolderViewController: UIViewController {

	public static let preferredSize = CGSize(width: 600, height: 150)
	
	override var keyCommands: [UIKeyCommand]? {
		[
			UIKeyCommand(action: #selector(cancel(_:)), input: UIKeyCommand.inputEscape),
			UIKeyCommand(action: #selector(submit(_:)), input: "\r"),
		]
	}
	
	@IBOutlet weak var nameTextField: UITextField!
	
	@IBOutlet weak var addBarButtonItem: UIBarButtonItem!

	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var cancelButton: UIButton!
	@IBOutlet weak var addButton: UIButton!
	
	override func viewDidLoad() {
        super.viewDidLoad()
	
		if traitCollection.userInterfaceIdiom == .mac {
			nameTextField.placeholder = nil
			navigationController?.setNavigationBarHidden(true, animated: false)
			addButton.role = .primary
		} else {
			nameLabel.isHidden = true
			cancelButton.isHidden = true
			addButton.isHidden = true
		}

		nameTextField.addTarget(self, action: #selector(nameTextFieldDidChange), for: .editingChanged)
		nameTextField.delegate = self
	}
	
	override func viewDidAppear(_ animated: Bool) {
		nameTextField.becomeFirstResponder()
	}
	
	@objc func nameTextFieldDidChange(textField: UITextField) {
		let isReady = !(nameTextField.text?.isEmpty ?? false)
		addBarButtonItem.isEnabled = isReady
		addButton.isEnabled = isReady
	}
	
	@IBAction func cancel(_ sender: Any) {
		dismiss(animated: true)
	}
	
	@IBAction func submit(_ sender: Any) {
		guard let folderName = nameTextField.text, !folderName.isEmpty else {
			return
		}
		
		guard let account = AccountManager.shared.findAccount(accountID: AccountType.local.rawValue) else { return }
		
		account.createFolder(folderName) { result in
			switch result {
			case .success:
				self.dismiss(animated: true)
			case .failure(let error):
				self.presentError(error)
				self.dismiss(animated: true)
			}
		}
	}
	
}

extension AddFolderViewController: UITextFieldDelegate {
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
	
}
