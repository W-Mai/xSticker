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
        
        createHintLabel()
        createStickerBrowser()
        createColletionSelector()
        BindConstraint(.compact)
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
        
        stickerBrowser = MSStickerBrowserViewController()
        addChild(stickerBrowser)
        view.addSubview(stickerBrowser.view)

        stickerBrowser.stickerBrowserView.dataSource = self
        stickerBrowser.stickerBrowserView.backgroundColor = UIColor(named: "BGColor")
    }
    
    func createColletionSelector() {
        let fllayout = UICollectionViewFlowLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: fllayout)
        
        collectionViewDelegateAndDataSource = MyCollectionDelegate(persistence: persistenceController, defaultCollection: currentSelected, onSelected: collectionSelected(collection:))
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
    
    func BindConstraint(_ status: MSMessagesAppPresentationStyle) {
        stickerBrowser.view.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        
        stickerBrowser.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        stickerBrowser.view.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        stickerBrowser.view.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        
        cons1 = stickerBrowser.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        cons2 = stickerBrowser.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -80)
        
        collectionView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        collectionView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        collectionView.topAnchor.constraint(equalTo: stickerBrowser.view.bottomAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        hintLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        hintLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60).isActive = true
//        hintLabel.heightAnchor.constraint(equalToConstant: 120).isActive = true
    }
    
    func collectionSelected(collection: Collections) {
        currentSelected = collection
        
        let context = persistenceController.container.viewContext
        let req: NSFetchRequest<Stickers> = Stickers.fetchRequest()
        req.predicate = NSPredicate(format: "collection=%@", currentSelected!)
        currentStickers = try? context.fetch(req)
        
        hintLabel.layer.opacity = currentStickers.count == 0 ? 1 : 0
        
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
        imageView = UIImageView(frame: CGRect(x: frame.width * 0.1, y: frame.width * 0.1, width: frame.width * 0.8, height: frame.height*0.8))
        labelView = UILabel(frame: CGRect(x: 0, y: 10, width: 50, height: 30))
        
        imageView.layer.cornerRadius = 16 - frame.width * 0.1
        imageView.clipsToBounds = true
        
        backgroundColor = UIColor(named: "ShallowShadowColor")
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
            layer.borderWidth = 1
            backgroundColor = UIColor(named: "ShadowColor")
        } else {
            layer.borderWidth = 0
            backgroundColor = UIColor(named: "ShallowShadowColor")
        }
    }
}
