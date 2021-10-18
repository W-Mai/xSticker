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
        view.backgroundColor = UIColor(named: "BGColor")
        
        collectionPickerViewController.backgroundColor = UIColor(named: "BGColor")
        
        createStickerBrowser()
        createColletionSelector()
    }
    
    func loadCurrentCollection() -> Collections{
        guard let lastUserdCollectionUUID = localSettingManager.lastUsedCollection.wrappedValue
        else { return persistenceController.defaultCollection }
        
        let contex = persistenceController.container.viewContext
        let req: NSFetchRequest<Collections> = Collections.fetchRequest()
        req.predicate = NSPredicate(format: "id=%@", NSUUID(uuidString: lastUserdCollectionUUID)!)
        
        guard let first = (try? contex.fetch(req))?.first
        else { return persistenceController.defaultCollection }
        
        return first
    }
    
    func createStickerBrowser() {
        currentSelected = loadCurrentCollection()
        
        stickerBrowser = MSStickerBrowserViewController()
        addChild(stickerBrowser)
        stickerPickerViewController.addSubview(stickerBrowser.view)
        
        stickerBrowser.stickerBrowserView.dataSource = self
        stickerBrowser.stickerBrowserView.backgroundColor = UIColor(named: "BGColor")
    }
    
    func createColletionSelector() {
        let fllayout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: collectionPickerViewController.bounds, collectionViewLayout: fllayout)
        
        collectionViewDelegateAndDataSource = MyCollectionDelegate(persistence: persistenceController, defaultCollection: currentSelected, onSelected: collectionSelected(collection:))
        collectionView.delegate = collectionViewDelegateAndDataSource
        collectionView.dataSource = collectionViewDelegateAndDataSource
        
        collectionView.backgroundColor = UIColor(named: "BGColor")
        collectionView.showsHorizontalScrollIndicator = false
        
        fllayout.minimumInteritemSpacing = 5
        fllayout.scrollDirection = .horizontal
        fllayout.itemSize = CGSize(width: 50, height: 50)
        
        collectionView.contentSize = fllayout.collectionViewContentSize
        collectionView.isPagingEnabled = false
        collectionView.decelerationRate = .fast
        
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
        
        localSettingManager.lastUsedCollection.wrappedValue = currentSelected.id?.uuidString
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
    
    var defaultSelected: IndexPath!
    var isFirstTimeToSelected = true
    
    init(persistence: PersistenceController, defaultCollection: Collections, onSelected: @escaping (Collections)->()) {
        super.init(frame: .zero)
        self.persistence = persistence
        
        self.onSelected = onSelected
        
        let req: NSFetchRequest<Collections> = Collections.fetchRequest()
        
        let context = persistence.container.viewContext
        collections = try? context.fetch(req)
        
        self.defaultSelected = IndexPath(row: collections?.firstIndex(of: defaultCollection) ?? 0, section: 0)
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
        cell.labelView.text = "\(cell.frame)"
        cell.labelView.adjustsFontSizeToFitWidth = true
        if isFirstTimeToSelected && indexPath == self.defaultSelected {
            cell.update(force: true)
            return cell
        }
        cell.update()
        layoutIfNeeded()
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! MyCollectionCell
        onSelected(collections![indexPath.row])
        cell.update()
        
        if isFirstTimeToSelected && indexPath != self.defaultSelected {
            let cell0 = collectionView.cellForItem(at: self.defaultSelected) as! MyCollectionCell
            cell0.update(force: false)
            isFirstTimeToSelected = false
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as? MyCollectionCell
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
        imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        labelView = UILabel(frame: CGRect(x: 0, y: 10, width: 50, height: 30))
        
        layer.cornerRadius = 16
        clipsToBounds = true
        
        addSubview(imageView)
        layer.borderColor = UIColor(named: "AccentColor")?.cgColor
    }
    
    func setProfile(img: UIImage) {
        imageView.image = img
    }
    
    func update(force: Bool? = nil) {
        let myIsSelected = force == nil ? isSelected : (force!)
        
        if myIsSelected == true {
            layer.borderWidth = 2
        } else {
            layer.borderWidth = 0
        }
    }
}
