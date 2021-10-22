//
//  CustomKeyboardView.swift
//  xStickerBoard
//
//  Created by W-Mai on 2021/10/22.
//

import Foundation
import UIKit
import CoreData
import SwiftUI

extension KeyboardViewController {
    
    func initView() -> Void {
        view.backgroundColor = UIColor(named: "BGColor")
        
        createKeyboardChangeButton()
        createHintLabel()
        createStickerBrowser()
        createColletionSelector()
        BindConstraint()
    }
    
    func loadCurrentCollection() -> Collections{
        guard let lastUserdCollectionUUID = localSettingManager.lastUsedCollection.wrappedValue
        else { return persistence.defaultCollection }
        
        let contex = persistence.container.viewContext
        let req: NSFetchRequest<Collections> = Collections.fetchRequest()
        req.predicate = NSPredicate(format: "id=%@", NSUUID(uuidString: lastUserdCollectionUUID)!)
        
        guard let first = (try? contex.fetch(req))?.first
        else { return persistence.defaultCollection }
        
        return first
    }
    
    func createKeyboardChangeButton(){
        // Perform custom UI setup here
        nextKeyboardButton = UIButton(type: .system)
        
        nextKeyboardButton.setImage(UIImage(systemName: "globe"), for: .normal)
//        nextKeyboardButton.setTitle(NSLocalizedString("", comment: "Title for 'Next Keyboard' button"), for: [])
        nextKeyboardButton.tintColor = UIColor(named: "AccentColor")
        nextKeyboardButton.backgroundColor = UIColor(named: "BGColor")
        
        nextKeyboardButton.layer.cornerRadius = 10
        nextKeyboardButton.layer.shadowColor = UIColor(named: "ShallowShadowColor")?.cgColor
        nextKeyboardButton.layer.shadowRadius = 5
        nextKeyboardButton.layer.shadowOpacity = 1
        nextKeyboardButton.layer.shadowOffset = CGSize(width: 1, height: 2)
        
        nextKeyboardButton.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        
        view.addSubview(self.nextKeyboardButton)
    }
    
    func createHintLabel() {
        hintLabel = UILabel()
        
        hintLabel.numberOfLines = 0
        hintLabel.lineBreakMode = .byCharWrapping
        
        let kkry = NSMutableAttributedString(string: "🈳️🈳️如👴", attributes: [.font: UIFont.systemFont(ofSize: 60)])
        kkry.append(NSAttributedString(string: "\n\n打开xSticker APP添加自己喜欢的Sticker叭😁"))
        kkry.append(NSAttributedString(string: "\n\n👆向上滑动 查看更多"))
        
        hintLabel.attributedText = kkry
        hintLabel.textAlignment = .center
        
        view.addSubview(hintLabel)
    }
    
    func createStickerBrowser() {
        currentSelected.v = loadCurrentCollection()
        
        let host = UIHostingController(
            rootView: HStack{
                VStack{
                    KeyboardStickerManagerView(collection: self.currentSelected)
                    Text("ok i am fine").onDrag({ NSItemProvider(object: NSString(string: self.currentSelected.v.name ?? "null")) })
                }
            })
        keyboardStickerManagerView = host.view
        
        self.addChild(host)
        self.view.addSubview(keyboardStickerManagerView)
        host.didMove(toParent: self)
    }
    
    func createColletionSelector() {
        let fllayout = UICollectionViewFlowLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: fllayout)
        
        collectionViewDelegateAndDataSource = MyCollectionDelegate(persistence: persistence, defaultCollection: currentSelected.v, onSelected: collectionSelected(collection:))
        collectionView.delegate = collectionViewDelegateAndDataSource
        collectionView.dataSource = collectionViewDelegateAndDataSource
        
        collectionView.backgroundColor = UIColor(named: "BGColor")
        collectionView.showsHorizontalScrollIndicator = false
        
        fllayout.minimumInteritemSpacing = 5
        fllayout.scrollDirection = .horizontal
        fllayout.itemSize = CGSize(width: 50, height: 50)
        fllayout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        
        collectionView.contentSize = fllayout.collectionViewContentSize
        collectionView.isPagingEnabled = false
        collectionView.decelerationRate = .fast
        
        collectionView.register(MyCollectionCell.self, forCellWithReuseIdentifier: "Cell")
        view.addSubview(collectionView)
        collectionSelected(collection: currentSelected.v)
    }
    
    func BindConstraint() {
        // 设置自动转换为关闭
        nextKeyboardButton.translatesAutoresizingMaskIntoConstraints = false
        keyboardStickerManagerView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        hintLabel.translatesAutoresizingMaskIntoConstraints = false

        //设置约束
        nextKeyboardButton.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 5).isActive = true
        nextKeyboardButton.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor).isActive = true
        nextKeyboardButton.widthAnchor.constraint(equalToConstant: 35).isActive = true
        nextKeyboardButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        keyboardStickerManagerView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        keyboardStickerManagerView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        keyboardStickerManagerView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        keyboardStickerManagerView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -60).isActive = true

//        cons1 = stickerBrowser.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
//        cons2 = stickerBrowser.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -80)

        collectionView.leftAnchor.constraint(equalTo: self.nextKeyboardButton.rightAnchor, constant: -10).isActive = true
        collectionView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        collectionView.topAnchor.constraint(equalTo: keyboardStickerManagerView.bottomAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        hintLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        hintLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60).isActive = true
        
        view.sendSubviewToBack(collectionView)
    }
    
    func collectionSelected(collection: Collections) {
        currentSelected.v = collection
        
        let context = persistence.container.viewContext
        let req: NSFetchRequest<Stickers> = Stickers.fetchRequest()
        req.predicate = NSPredicate(format: "collection=%@", currentSelected.v!)
        req.sortDescriptors = [NSSortDescriptor(keyPath: \Stickers.order, ascending: true)]
        currentStickers = try? context.fetch(req)
        
        hintLabel.layer.opacity = currentStickers.count == 0 ? 1 : 0
        
//        stickerBrowser.stickerBrowserView.reloadData()
        
        localSettingManager.lastUsedCollection.wrappedValue = currentSelected.v.id?.uuidString
    }
    
    // MARK: - 数据源
    
//    func numberOfStickers(in stickerBrowserView: MSStickerBrowserView) -> Int {
//        return currentStickers?.count ?? 0
//    }
//
//    func stickerBrowserView(_ stickerBrowserView: MSStickerBrowserView, stickerAt index: Int) -> MSSticker {
//        if currentStickers == nil {
//            return try! MSSticker(contentsOfFileURL: StickerManager.defaultImagePath, localizedDescription: "拉普兰德和德克萨斯")
//        }
//        let sticker = currentStickers[index]
//        let stickerPath = stickerManager.get(path: sticker) ?? StickerManager.defaultImagePath
//
//        return try! MSSticker(contentsOfFileURL: stickerPath, localizedDescription: sticker.name!)
//    }
    
}
