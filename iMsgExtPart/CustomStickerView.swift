//
//  CustomStickerView.swift
//  xSticker
//
//  Created by W-Mai on 2021/10/14.
//

import Foundation
import UIKit
import Messages
import CoreData

extension MessagesViewController: MSStickerBrowserViewDataSource {
    func initView() -> Void {
        view.backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        
//        stickerPickerViewController.contentInsetAdjustmentBehavior = .never
//        collectionPickerViewController.contentInsetAdjustmentBehavior = .never
        collectionPickerViewController.showsHorizontalScrollIndicator = false
        collectionPickerViewController.backgroundColor = .blue
        
        createStickerBrowser()
        createColletionSelector()
    }
    
    func createStickerBrowser() {
        stickerBrowser = MSStickerBrowserViewController()
        addChild(stickerBrowser)
        stickerPickerViewController.addSubview(stickerBrowser.view)
        
        stickerBrowser.stickerBrowserView.dataSource = self
        stickerBrowser.stickerBrowserView.backgroundColor = UIColor(named: "AccentColor")
    }
    
    func createColletionSelector() {
        let fllayout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: collectionPickerViewController.bounds, collectionViewLayout: fllayout)
        
        collectionViewDelegateAndDataSource = MyCollectionDelegate(persistence: persistenceController)
        collectionView.delegate = collectionViewDelegateAndDataSource
        collectionView.dataSource = collectionViewDelegateAndDataSource
        
        collectionView.backgroundColor = .orange
        collectionView.showsHorizontalScrollIndicator = false
        
        fllayout.minimumInteritemSpacing = 0
        fllayout.scrollDirection = .horizontal
        fllayout.itemSize = CGSize(width: 70, height: 70)
        
        collectionView.contentSize = fllayout.collectionViewContentSize
        
        collectionView.register(MyCollectionCell.self, forCellWithReuseIdentifier: "Cell")
        collectionPickerViewController.addSubview(collectionView)
    }
    
    @objc func buttonOnClick(){
        self.requestPresentationStyle(.compact)
        let layout = MSMessageTemplateLayout()
        
        let context = persistenceController.container.viewContext
        
        let req: NSFetchRequest<Item> = Item.fetchRequest()
        let res = try? context.fetch(req)
        
        layout.caption = "你好👋"
        layout.image = UIImage(named: "plus.circle")
        layout.subcaption = "\(String(describing: res?.last?.timestamp))"
        layout.trailingCaption = "再见👋"
        
        let msg = MSMessage()
        msg.layout = layout
        
        activeConversation?.insert(msg, completionHandler: { error in
            
        })
    }
    
    // MARK: - 数据源
    func numberOfStickers(in stickerBrowserView: MSStickerBrowserView) -> Int {
        let context = persistenceController.container.viewContext
        
        let req: NSFetchRequest<Stickers> = Stickers.fetchRequest()
        let res = (try? context.count(for: req)) ?? 0
        
        return res
    }
    
    func stickerBrowserView(_ stickerBrowserView: MSStickerBrowserView, stickerAt index: Int) -> MSSticker {
        let context = persistenceController.container.viewContext
        let req: NSFetchRequest<Stickers> = Stickers.fetchRequest()
        guard let stickers = try? context.fetch(req)
        else { return try! MSSticker(contentsOfFileURL: StickerManager.defaultImagePath, localizedDescription: "拉普兰德和德克萨斯") }
        let sticker = stickers[index]
        let stickerPath = stickerManager.get(path: sticker) ?? StickerManager.defaultImagePath
        
        return try! MSSticker(contentsOfFileURL: stickerPath, localizedDescription: sticker.name!)
    }
    
}

class MyCollectionDelegate: UIView, UICollectionViewDelegate, UICollectionViewDataSource {
    var persistence: PersistenceController!
    
    var collections: [Collections]?
    
    init(persistence: PersistenceController) {
        super.init(frame: .zero)
        self.persistence = persistence
        
        let req: NSFetchRequest<Collections> = Collections.fetchRequest()
        
        let context = persistence.container.viewContext
        collections = try? context.fetch(req)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collections?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! MyCollectionCell
        cell.backgroundColor = .red
        
        let collection = collections?[indexPath.row]
        let img = stickerManager.get(profile: collection!)
        cell.update(img: img)
        return cell
    }
    
    
}

class MyCollectionCell: UICollectionViewCell {
    
    var imageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initView() {
//        let v = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
//        v.backgroundColor = .red
        
        imageView = UIImageView(frame: bounds)
        
//        addSubview(v)
        addSubview(imageView)
        backgroundColor = .green
    }
    
    func update(img: UIImage) {
        imageView.image = img
    }
}
