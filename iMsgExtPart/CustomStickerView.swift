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

extension MessagesViewController {
    func initView() -> Void {
        let button = UIButton()
        button.frame = view.frame
        button.setTitle("Click me", for: .normal)
        
        button.backgroundColor = #colorLiteral(red: 0.2196078449, green: 0.007843137719, blue: 0.8549019694, alpha: 1)
        button.addTarget(self, action: #selector(buttonOnClick), for: .touchUpInside)

        view.addSubview(button)
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
}

