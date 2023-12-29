//
//  SettingsFontConfigViewController.swift
//  Zavala
//
//  Created by Maurice Parker on 3/26/21.
//

import UIKit

protocol SettingsFontConfigViewControllerDelegate: AnyObject {
	func didUpdateConfig(field: OutlineFontField, config: OutlineFontConfig)
}

class SettingsFontConfigViewController: UITableViewController {

	var field: OutlineFontField?
	var config: OutlineFontConfig?
	weak var delegate: SettingsFontConfigViewControllerDelegate?
	
	@IBOutlet weak var doneBarButtonItem: UIBarButtonItem!
	@IBOutlet weak var fontNameLabel: UILabel!
	@IBOutlet weak var fontSizeLabel: UILabel!
	@IBOutlet weak var fontSizeStepper: UIStepper!
	@IBOutlet weak var sampleTextLabel: UILabel!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		if let field, 
			let outlineFonts = AppDefaults.shared.outlineFonts,
			!outlineFonts.rowFontConfigs.keys.contains(field) {
			doneBarButtonItem.title = AppStringAssets.addControlLabel
		}
		
		navigationItem.title = field?.displayName
		fontNameLabel.text = config?.name
		fontSizeLabel.text = String(config?.size ?? 0)
		fontSizeStepper.value = Double(config?.size ?? 0)
		
		updateUI()
    }

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if indexPath.section == 0 && indexPath.row == 0 {
			let controller = UIFontPickerViewController()
			controller.delegate = self
			present(controller, animated: true)
		}
		tableView.selectRow(at: nil, animated: true, scrollPosition: .none)
	}
	
	@IBAction func fontSizeChanged(_ sender: Any) {
		let stepValue = Int(fontSizeStepper.value)
		config?.size = stepValue
		fontSizeLabel.text = String(stepValue)
		updateUI()
	}
	
	@IBAction func cancel(_ sender: Any) {
		dismiss(animated: true)
	}
	
	@IBAction func done(_ sender: Any) {
		guard let field = field, let config = config else { return }
		
		var fontDefaults = AppDefaults.shared.outlineFonts
		fontDefaults?.rowFontConfigs[field] = config
		AppDefaults.shared.outlineFonts = fontDefaults

		dismiss(animated: true)
	}
	
}

// MARK: UIFontPickerViewControllerDelegate

extension SettingsFontConfigViewController: UIFontPickerViewControllerDelegate {
	
	func fontPickerViewControllerDidPickFont(_ viewController: UIFontPickerViewController) {
		guard let fontName = viewController.selectedFontDescriptor?.fontAttributes[.family] as? String else { return }
		viewController.dismiss(animated: true)
		fontNameLabel.text = fontName
		config?.name = fontName
		updateUI()
	}
	
}

// MARK: Helpers

private extension SettingsFontConfigViewController {

	func updateUI() {
		guard let config = config, let font = UIFont(name: config.name, size: CGFloat(config.size)) else { return }
		sampleTextLabel.font = font
		tableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .none)
	}

}
