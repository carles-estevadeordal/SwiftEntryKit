//
//  EKTextField.swift
//  SwiftEntryKit
//
//  Created by Daniel Huri on 5/16/18.
//

import Foundation
import UIKit

final public class EKTextField: UIView {
    
    // MARK: - Properties
    
    static let totalHeight: CGFloat = 45
    
    private let content: EKProperty.TextFieldContent
    
    private let imageView = UIImageView()
    public let textField = UITextField()
    private let separatorView = UIView()
    
    public var text: String {
        set {
            textField.text = newValue
        }
        get {
            return textField.text ?? ""
        }
    }
    
    // MARK: - Setup
    
    public init(with content: EKProperty.TextFieldContent) {
        self.content = content
        super.init(frame: UIScreen.main.bounds)
        setupImageView()
        setupTextField()
        setupSeparatorView()
        textField.accessibilityIdentifier = content.accessibilityIdentifier
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupImageView() {
        addSubview(imageView)
        imageView.contentMode = .center
        imageView.set(.width, .height, of: EKTextField.totalHeight)
        imageView.layoutToSuperview(.leading)
        imageView.image = content.leadingImage
        imageView.tintColor = content.tintColor(for: traitCollection)
    }
    
    private func setupTextField() {
        addSubview(textField)
        textField.textFieldContent = content
        textField.set(.height, of: EKTextField.totalHeight)
        textField.layout(.leading, to: .trailing, of: imageView)
        textField.layoutToSuperview(.top, .trailing)
        imageView.layout(to: .centerY, of: textField)
        
        if content.datePicker != nil {
            textField.datePicker = content.datePicker
        } else if content.pickerView != nil {
            textField.pickerView = content.pickerView
        }
    }
    
    private func setupSeparatorView() {
        addSubview(separatorView)
        separatorView.layout(.top, to: .bottom, of: textField)
        separatorView.set(.height, of: 1)
        separatorView.layoutToSuperview(.bottom)
        separatorView.layoutToSuperview(axis: .horizontally, offset: 10)
        separatorView.backgroundColor = content.bottomBorderColor.color(
            for: traitCollection,
            mode: content.displayMode
        )
    }
    
    public func makeFirstResponder() {
        textField.becomeFirstResponder()
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        separatorView.backgroundColor = content.bottomBorderColor(for: traitCollection)
        imageView.tintColor = content.tintColor(for: traitCollection)
        textField.textColor = content.textStyle.color(for: traitCollection)
        textField.placeholder = content.placeholder
    }
}

public extension UITextField {
    
    fileprivate struct AssociatedKeys {
        static var DateFormatter = "am_DateFormat"
        static var ShowClearButton = "am_ShowClearButton"
        static var ClearButtonTitle = "am_ClearButtonTitle"
    }
    
    /// The `UIPickerView` for the text field. Set this to configure the `inputView` and `inputAccessoryView` for the text field.
    var pickerView: UIPickerView? {
        get {
            return self.inputView as? UIPickerView
        }
        set {
            setInputViewToPicker(newValue)
        }
    }
    
    /// The `UIDatePicker` for the text field. Set this to configure the `inputView` and `inputAccessoryView` for the text field.
    var datePicker: UIDatePicker? {
        get {
            return self.inputView as? UIDatePicker
        }
        set {
            setInputViewToPicker(newValue)
        }
    }
    
    fileprivate func setInputViewToPicker(_ picker: UIView?) {
        self.inputView = picker
        self.inputAccessoryView = picker != nil ? pickerToolbar() : nil
    }
    
    fileprivate func refreshPickerToolbar() {
        self.inputAccessoryView = hasPicker() ? pickerToolbar() : nil
    }
    
    fileprivate func hasPicker() -> Bool {
        return pickerView != nil || datePicker != nil
    }
    
    fileprivate func pickerToolbar() -> UIToolbar {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = createDoneButton()
        
        var toolbarItems = [flexibleSpace, doneButton]
        
        if showPickerClearButton {
            toolbarItems.insert(createClearButton(), at: 0)
        }
        
        toolbar.items = toolbarItems
        
        return toolbar
    }
    
    fileprivate func createDoneButton() -> UIBarButtonItem {
        return UIBarButtonItem(barButtonSystemItem: .done,
                               target: self,
                               action: #selector(UITextField.didPressPickerDoneButton(_:)))
    }
    
    fileprivate func createClearButton() -> UIBarButtonItem {
        return UIBarButtonItem(title: clearButtonTitle,
                               style: .plain,
                               target: self,
                               action: #selector(UITextField.didPressPickerClearButton(_:)))
    }
    
    /// The `NSDateFormatter` to use to set the text field's `text` when using the `datePicker`.
    /// Defaults to a date formatter with date format: "M/d/yy".
    var dateFormatter: DateFormatter {
        get {
            if let formatter = objc_getAssociatedObject(self, &AssociatedKeys.DateFormatter) as? DateFormatter {
                return formatter
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "M/d/yy"
                objc_setAssociatedObject(self, &AssociatedKeys.DateFormatter, formatter, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return formatter
            }
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.DateFormatter, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// If set to `true` the `inputAccessoryView` toolbar will include a button to clear the text field.
    /// Defaults to `false`.
    var showPickerClearButton: Bool {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.ShowClearButton) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.ShowClearButton, newValue as Bool, .OBJC_ASSOCIATION_COPY_NONATOMIC)
            refreshPickerToolbar()
        }
    }
    
    /// The title to display for the clear button on the `inputAccessoryView` toolbar.
    /// Defaults to "Clear".
    var clearButtonTitle: String {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.ClearButtonTitle) as? String ?? "Clear"
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.ClearButtonTitle, newValue as NSString, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /**
     This method is called when the "Done" button on the `inputAccessoryView` toolbar is pressed.
     
     :discussion: This method will set the text field's text with the title for the selected row in the `pickerView` in component `0` from the `pickerView`'s `delegate.
     
     - parameter sender: The "Done" button sending the action.
     */
    @objc func didPressPickerDoneButton(_ sender: AnyObject) {
        guard pickerView != nil || datePicker != nil else { return }
        
        if pickerView != nil {
            setTextFromPickerView()
            
        } else if datePicker != nil {
            setTextFromDatePicker()
        }
        DispatchQueue.main.async(execute: { () -> Void in
            self.sendActions(for: .editingChanged)
        })
        resignFirstResponder()
    }
    
    fileprivate func setTextFromPickerView() {
        if let selectedRow = pickerView?.selectedRow(inComponent: 0),
            let title = pickerView?.delegate?.pickerView?(pickerView!, titleForRow: selectedRow, forComponent: 0) {
            self.text = title
        }
    }
    
    fileprivate func setTextFromDatePicker() {
        if let date = datePicker?.date {
            self.text = self.dateFormatter.string(from: date)
        }
    }
    
    /**
     This method is called when the clear button on the `inputAccessoryView` toolbar is pressed.
     
     :discussion: This method will set the text field's text to `nil`.
     
     - parameter sender: The clear button sending the action.
     */
    @objc func didPressPickerClearButton(_ sender: AnyObject) {
        self.text = nil
        DispatchQueue.main.async(execute: { () -> Void in
            self.sendActions(for: .editingChanged)
        })
        resignFirstResponder()
    }
    
}
