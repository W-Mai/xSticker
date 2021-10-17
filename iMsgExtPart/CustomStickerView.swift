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
        
        collectionPickerViewController.showsHorizontalScrollIndicator = false
        collectionPickerViewController.backgroundColor = .blue
        
        createStickerBrowser()
        createColletionSelector()
    }
    
    func createStickerBrowser() {
        currentSelected = persistenceController.defaultCollection
        
        stickerBrowser = MSStickerBrowserViewController()
        addChild(stickerBrowser)
        stickerPickerViewController.addSubview(stickerBrowser.view)
        
        stickerBrowser.stickerBrowserView.dataSource = self
        stickerBrowser.stickerBrowserView.backgroundColor = UIColor(named: "AccentColor")
    }
    
    func createColletionSelector() {
        let fllayout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: collectionPickerViewController.bounds, collectionViewLayout: fllayout)
        
        collectionViewDelegateAndDataSource = MyCollectionDelegate(persistence: persistenceController, onSelected: collectionSelected(collection:))
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
        
        collectionSelected(collection: currentSelected)
    }
    
    func collectionSelected(collection: Collections) {
        currentSelected = collection
        
        let context = persistenceController.container.viewContext
        let req: NSFetchRequest<Stickers> = Stickers.fetchRequest()
        req.predicate = NSPredicate(format: "collection=%@", currentSelected!)
        currentStickers = try? context.fetch(req)
        
        stickerBrowser.stickerBrowserView.reloadData()
    }
    
    // MARK: - 数据源
    
    func numberOfStickers(in stickerBrowserView: MSStickerBrowserView) -> Int {
        return currentStickers?.count ?? 0
    }
    
    func stickerBrowserView(_ stickerBrowserView: MSStickerBrowserView, stickerAt index: Int) -> MSSticker {
        if currentStickers == nil {
            return try! MSSticker(contentsOfFileURL: StickerManager.defaultImagePath, localizedDescription: "拉普兰德和德克萨斯")
        }
        let sticker = currentStickers[index]
        let stickerPath = stickerManager.get(path: sticker) ?? StickerManager.defaultImagePath
        
        return try! MSSticker(contentsOfFileURL: stickerPath, localizedDescription: sticker.name!)
    }
    
}

class MyCollectionDelegate: UIView, UICollectionViewDelegate, UICollectionViewDataSource {
    var persistence: PersistenceController!
    var onSelected: ((Collections)->())!
    
    var collections: [Collections]?
    
    var isFirstTimeToSelected = true
    
    init(persistence: PersistenceController, onSelected: @escaping (Collections)->()) {
        super.init(frame: .zero)
        self.persistence = persistence
        self.onSelected = onSelected
        
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
        
        let collection = collections?[indexPath.row]
        let img = stickerManager.get(profile: collection!)
        cell.setProfile(img: img)
        cell.labelView.text = "\(indexPath)"
        if isFirstTimeToSelected && indexPath.row == 0{
            cell.update(force: true)
            return cell
        }
        cell.update()
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! MyCollectionCell
        onSelected(collections![indexPath.row])
//        cell.isSelected = true
        cell.update()
        
        if isFirstTimeToSelected && indexPath.row != 0{
            let cell0 = collectionView.cellForItem(at: IndexPath(row: 0, section: 0)) as! MyCollectionCell
            cell0.update(force: false)
            isFirstTimeToSelected = false
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as? MyCollectionCell
//        cell.isSelected = false
        cell?.update()
    }
}

class MyCollectionCell: UICollectionViewCell {
    var labelView: UILabel!
    var imageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initView() {
        imageView = UIImageView(frame: CGRect(x: 0, y: 30, width: 70, height: 70))
        labelView = UILabel(frame: CGRect(x: 0, y: 0, width: 70, height: 30))
        
        addSubview(imageView)
        addSubview(labelView)
        backgroundColor = .green
    }
    
    func setProfile(img: UIImage) {
        imageView.image = img
    }
    
    func update(force: Bool? = nil) {
        if force != nil {
            if force! == true {
                layer.cornerRadius = 20
            } else {
                layer.cornerRadius = 0
            }
            clipsToBounds = true
        } else {
            if isSelected == true {
                layer.cornerRadius = 20
            } else {
                layer.cornerRadius = 0
            }
            clipsToBounds = true
        }
    }
}
