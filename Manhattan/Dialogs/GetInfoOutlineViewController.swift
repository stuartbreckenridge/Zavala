//
//  GetInfoOutlineViewController.swift
//  Manhattan
//
//  Created by Maurice Parker on 11/12/20.
//

import UIKit
import Templeton

class GetInfoOutlineViewController: FormViewController {
	
	static let preferredContentSize = CGSize(width: 400, height: 200)

	var outline: Outline?

	@IBOutlet weak var addBarButtonItem: UIBarButtonItem!
	
	@IBOutlet weak var nameTextField: UITextField!
	
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var cancelButton: UIButton!
	@IBOutlet weak var submitButton: UIButton!
	
	override func viewDidLoad() {
		super.viewDidLoad()
	
		if traitCollection.userInterfaceIdiom == .mac {
			nameTextField.placeholder = nil
			nameTextField.borderStyle = .bezel
			navigationController?.setNavigationBarHidden(true, animated: false)
			submitButton.role = .primary
		} else {
			nameLabel.isHidden = true
			cancelButton.isHidden = true
			submitButton.isHidden = true
		}

		nameTextField.text = outline?.title
		nameTextField.addTarget(self, action: #selector(nameTextFieldDidChange), for: .editingChanged)
		nameTextField.delegate = self
		
		updateUI()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		nameTextField.becomeFirstResponder()
	}
	
	@objc func nameTextFieldDidChange(textField: UITextField) {
		updateUI()
	}
	
	@IBAction override func submit(_ sender: Any) {
		guard let outline = outline, let outlineName = nameTextField.text, !outlineName.isEmpty else { return }
		
		outline.update(title: outlineName)
		dismiss(animated: true)
	}
	
	func updateUI() {
		let isReady = !(nameTextField.text?.isEmpty ?? false)
		addBarButtonItem.isEnabled = isReady
		submitButton.isEnabled = isReady
	}

}

extension GetInfoOutlineViewController: UITextFieldDelegate {
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
	
}
