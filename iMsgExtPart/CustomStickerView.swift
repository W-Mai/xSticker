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

public extension UIView {
    typealias ConstraintsTupleStretched = (top:NSLayoutConstraint, bottom:NSLayoutConstraint, leading:NSLayoutConstraint, trailing:NSLayoutConstraint)
    func addSubviewStretched(subview:UIView?, insets: UIEdgeInsets = UIEdgeInsets() ) -> ConstraintsTupleStretched? {
        guard let subview = subview else {
            return nil
        }
        
        subview.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subview)
        
        let constraintLeading = NSLayoutConstraint(item: subview, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: insets.left)
        addConstraint(constraintLeading)
        
        let constraintTrailing = NSLayoutConstraint(item: self,
                                                    attribute: .right,
                                                    relatedBy: .equal,
                                                    toItem: subview,
                                                    attribute: .right,
                                                    multiplier: 1,
                                                    constant: insets.right)
        addConstraint(constraintTrailing)
        
        let constraintTop = NSLayoutConstraint(item: subview,
                                               attribute: .top,
                                               relatedBy: .equal,
                                               toItem: self,
                                               attribute: .top,
                                               multiplier: 1,
                                               constant: insets.top)
        addConstraint(constraintTop)
        
        let constraintBottom = NSLayoutConstraint(item: self,
                                                  attribute: .bottom,
                                                  relatedBy: .equal,
                                                  toItem: subview,
                                                  attribute: .bottom,
                                                  multiplier: 1,
                                                  constant: insets.bottom)
        addConstraint(constraintBottom)
        return (constraintTop, constraintBottom, constraintLeading, constraintTrailing)
    }
    
}


extension MessagesViewController: MSStickerBrowserViewDataSource {
    func initView() -> Void {
        view.backgroundColor = UIColor(named: "BGColor")
        
        collectionPickerViewController.backgroundColor = UIColor(named: "BGColor")
        
        createStickerBrowser()
        createColletionSelector()
        BindConstraint()
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
//        stickerPickerViewController.addSubview(stickerBrowser.stickerBrowserView)
        
        
        
//        view.addSubviewStretched(subview: stickerBrowser.view, insets: UIEdgeInsets(top: 80, left: 0, bottom: 0, right: 0))
//        let BorderedBackgroundInset = UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
//        view?.addSubviewStretched(calendar.view, insets: BorderedBackgroundInset)
        
        view.addSubview(stickerBrowser.view)
        
        stickerBrowser.view.translatesAutoresizingMaskIntoConstraints = false
        
        stickerBrowser.stickerBrowserView.dataSource = self
        stickerBrowser.stickerBrowserView.backgroundColor = UIColor(named: "BGColor")
//        NSLayoutConstraint.activate([
//            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
//            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
//        ])
        
//
//        view.addConstraint(NSLayoutConstraint(item: stickerBrowser.view!, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1, constant: 0))
//        view.addConstraint(NSLayoutConstraint(item: stickerBrowser.view!, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0))
//        view.addConstraint(NSLayoutConstraint(item: view!, attribute: .right, relatedBy: .equal, toItem: stickerBrowser.view, attribute: .right, multiplier: 1, constant: 0))
//        view.addConstraint(NSLayoutConstraint(item: view!, attribute: .bottom, relatedBy: .equal, toItem: stickerBrowser.view, attribute: .bottom, multiplier: 1, constant: 0))
    }
    
    func createColletionSelector() {
        let fllayout = UICollectionViewFlowLayout()
        collectionView = UICollectionView(frame: collectionPickerViewController.bounds, collectionViewLayout: fllayout)
        
        collectionViewDelegateAndDataSource = MyCollectionDelegate(persistence: persistenceController, defaultCollection: currentSelected, onSelected: collectionSelected(collection:))
        collectionView.delegate = collectionViewDelegateAndDataSource
        collectionView.dataSource = collectionViewDelegateAndDataSource
        
        collectionView.backgroundColor = UIColor(named: "BGColor")
        collectionView.showsHorizontalScrollIndicator = false
        
        fllayout.minimumInteritemSpacing = 5
        fllayout.scrollDirection = .horizontal
        fllayout.itemSize = CGSize(width: 50, height: 50)
        fllayout.sectionInset.left = 20
        
        collectionView.contentSize = fllayout.collectionViewContentSize
        collectionView.isPagingEnabled = false
        collectionView.decelerationRate = .fast
        
        collectionView.register(MyCollectionCell.self, forCellWithReuseIdentifier: "Cell")
        collectionPickerViewController.addSubviewStretched(subview: collectionView)
//        view.addSubviewStretched(subview: collectionPickerViewController, insets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))
        
        collectionSelected(collection: currentSelected)
    }
    
    func BindConstraint() {
        view.addConstraint(NSLayoutConstraint(item: stickerBrowser.view!, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: stickerBrowser.view!, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: view!, attribute: .right, relatedBy: .equal, toItem: stickerBrowser.view, attribute: .right, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: view!, attribute: .bottom, relatedBy: .equal, toItem: stickerBrowser.view, attribute: .bottom, multiplier: 1, constant: 100))
        
        
//        view.addConstraint(NSLayoutConstraint(item: collectionView!, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1, constant: 0))
//        view.addConstraint(NSLayoutConstraint(item: collectionView!, attribute: .top, relatedBy: .equal, toItem: collectionView, attribute: .bottom, multiplier: 1, constant: 80))
//        view.addConstraint(NSLayoutConstraint(item: view!, attribute: .right, relatedBy: .equal, toItem: collectionView, attribute: .right, multiplier: 1, constant: 0))
//        view.addConstraint(NSLayoutConstraint(item: view!, attribute: .bottom, relatedBy: .equal, toItem: collectionView, attribute: .bottom, multiplier: 1, constant: 0))

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
