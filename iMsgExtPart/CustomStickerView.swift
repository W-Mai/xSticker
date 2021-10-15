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
        createStickerBrowser()
    }
    
    func createStickerBrowser() {
        let stickerBrowser = MSStickerBrowserViewController()
        addChild(stickerBrowser)
        view.addSubview(stickerBrowser.view)
        
        stickerBrowser.stickerBrowserView.dataSource = self
        stickerBrowser.stickerBrowserView.backgroundColor = #colorLiteral(red: 0.1764705926, green: 0.01176470611, blue: 0.5607843399, alpha: 1)
        
        stickerBrowser.view.frame = view.frame
    }
    
    @objc func buttonOnClick(){
        self.requestPresentationStyle(.compact)
        let layout = MSMessageTemplateLayout()
        
        let context = persistenceController.container.viewContext
        
        let req: NSFetchRequest<Item> = Item.fetchRequest()
        let res = try? context.fetch(req)
        
        layout.caption = "你好👋"
        layout.image = UIImage(named: "plus.circle")
        layout.subcaption = "\(res?.last?.timestamp)"
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

