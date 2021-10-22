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
    var hintLabel: UILabel!
    
    var currentSelected: Collections!
    var currentStickers: [Stickers]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.inputView?.allowsSelfSizing = true
        
        
        self.view.heightAnchor.constraint(equalToConstant: 400).isActive = true
        
        // Perform custom UI setup here
        self.nextKeyboardButton = UIButton(type: .system)
        
        self.nextKeyboardButton.setTitle(NSLocalizedString("Next Keyboard", comment: "Title for 'Next Keyboard' button"), for: [])
        self.nextKeyboardButton.sizeToFit()
        self.nextKeyboardButton.translatesAutoresizingMaskIntoConstraints = false
        
        self.nextKeyboardButton.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        
        self.view.addSubview(self.nextKeyboardButton)
        
        self.nextKeyboardButton.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.nextKeyboardButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        self.nextKeyboardButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        self.nextKeyboardButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        let context = persistence.container.viewContext
        let req = Collections.fetchRequest() as NSFetchRequest<Collections>
        let count = (try? context.count(for: req)) ?? 0
        
        self.nextKeyboardButton.setTitle("\(count)", for: [])
        
        self.initView()
        
        
        let myView = UIHostingController(
            rootView: HStack{
                Text("ok i am fine").onDrag({ NSItemProvider(object: NSString("fuck up")) })
                
            })
        
        self.addChild(myView)
        self.view.addSubview(myView.view)
        
        myView.view.translatesAutoresizingMaskIntoConstraints = false
        
        myView.view.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        myView.view.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        myView.view.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        myView.view.heightAnchor.constraint(equalToConstant: 60).isActive = true
    }
    
    override func viewWillLayoutSubviews() {
        self.nextKeyboardButton.isHidden = !self.needsInputModeSwitchKey
        super.viewWillLayoutSubviews()
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
