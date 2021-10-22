//
//  CustomKeyboardView.swift
//  xStickerBoard
//
//  Created by W-Mai on 2021/10/22.
//

import Foundation
import UIKit
import CoreData

extension KeyboardViewController {
    
    func initView() -> Void {
        view.backgroundColor = UIColor(named: "BGColor")
        
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
        currentSelected = loadCurrentCollection()
        
//        stickerBrowser = MSStickerBrowserViewController()
//        addChild(stickerBrowser)
//        view.addSubview(stickerBrowser.view)
//
//        stickerBrowser.stickerBrowserView.dataSource = self
//        stickerBrowser.stickerBrowserView.backgroundColor = UIColor(named: "BGColor")
    }
    
    func createColletionSelector() {
        let fllayout = UICollectionViewFlowLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: fllayout)
        
        collectionViewDelegateAndDataSource = MyCollectionDelegate(persistence: persistence, defaultCollection: currentSelected, onSelected: collectionSelected(collection:))
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
        collectionSelected(collection: currentSelected)
    }
    
    func BindConstraint() {
//        stickerBrowser.view.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        hintLabel.translatesAutoresizingMaskIntoConstraints = false

//        stickerBrowser.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
//        stickerBrowser.view.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
//        stickerBrowser.view.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true


//        cons1 = stickerBrowser.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
//        cons2 = stickerBrowser.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -80)

        collectionView.leftAnchor.constraint(equalTo: self.nextKeyboardButton.rightAnchor).isActive = true
        collectionView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        collectionView.heightAnchor.constraint(equalToConstant: 80).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        hintLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        hintLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60).isActive = true
//        hintLabel.heightAnchor.constraint(equalToConstant: 120).isActive = true
    }
    
    func collectionSelected(collection: Collections) {
        currentSelected = collection
        
        let context = persistence.container.viewContext
        let req: NSFetchRequest<Stickers> = Stickers.fetchRequest()
        req.predicate = NSPredicate(format: "collection=%@", currentSelected!)
        req.sortDescriptors = [NSSortDescriptor(keyPath: \Stickers.order, ascending: true)]
        currentStickers = try? context.fetch(req)
        
        hintLabel.layer.opacity = currentStickers.count == 0 ? 1 : 0
        
//        stickerBrowser.stickerBrowserView.reloadData()
        
        localSettingManager.lastUsedCollection.wrappedValue = currentSelected.id?.uuidString
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
