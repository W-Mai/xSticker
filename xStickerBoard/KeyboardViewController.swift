//
//  KeyboardViewController.swift
//  xStickerBoard
//
//  Created by W-Mai on 2021/10/22.
//

import UIKit
import CoreData
import SwiftUI
import UniformTypeIdentifiers

class KeyboardViewController: UIInputViewController {
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        // Add custom view sizing constraints here
    }
    
    let persistence = PersistenceController.shared
    var localSettingManager: LocalSettingsManager {
        return LocalSettingsManager(with: persistence)
    }
    
    @IBOutlet var nextKeyboardButton: UIButton!
    var collectionView: UICollectionView!
    var collectionViewDelegateAndDataSource: MyCollectionDelegate!
    var keyboardStickerManagerView: UIView!
    var hintLabel: UILabel!
    
    var currentSelected: CollectionModel = CollectionModel()
    var currentStickers: [Stickers]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.heightAnchor.constraint(equalToConstant: 400).isActive = true
        
        self.initView()
    }
    
    override func viewWillLayoutSubviews() {
        self.nextKeyboardButton.isHidden = !self.needsInputModeSwitchKey
        super.viewWillLayoutSubviews()
        
        nextKeyboardButton.layer.shadowColor = UIColor(named: "ShallowShadowColor")?.cgColor
    }
    
    override func textWillChange(_ textInput: UITextInput?) {
        // The app is about to change the document's contents. Perform any preparation here.
    }
    
    override func textDidChange(_ textInput: UITextInput?) {
        // The app has just changed the document's contents, the document context has been updated.
        
        var textColor: UIColor
        let proxy = self.textDocumentProxy
        if proxy.keyboardAppearance == UIKeyboardAppearance.dark {
            textColor = UIColor.white
        } else {
            textColor = UIColor.black
        }
        self.nextKeyboardButton.setTitleColor(textColor, for: [])
        
    }

}
