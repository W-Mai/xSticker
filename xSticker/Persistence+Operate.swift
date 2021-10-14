//
//  Persistence+Operate.swift
//  xSticker
//
//  Created by W-Mai on 2021/10/15.
//

import Foundation

extension PersistenceController {
    func save() {
        do {
            try container.viewContext.save()
        } catch {
            exit(-1)
        }
    }
    
    func addSticker(with name: String, in collection: Collections) -> Stickers {
        let sticker = Stickers(context: container.viewContext)
        
        sticker.addDate = Date()
        sticker.collection = collection
        sticker.image = UUID()
        sticker.name = name
        
        save()
        return sticker
    }
    
    func removeSticker(of sticker: Stickers) {
        container.viewContext.delete(sticker)
        save()
    }
}
