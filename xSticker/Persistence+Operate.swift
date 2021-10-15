//
//  Persistence+Operate.swift
//  xSticker
//
//  Created by W-Mai on 2021/10/15.
//

import Foundation
import CoreData

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
        
        reorder(for: collection)
        return sticker
    }
    
    func removeSticker(of sticker: Stickers) {
        let collection = sticker.collection!
        container.viewContext.delete(sticker)
        reorder(for: collection)
    }
    
    func count(collection: Collections) -> Int64 {
        let context = container.viewContext
        let req: NSFetchRequest<Collections> = Collections.fetchRequest()
        
        if let num = try? context.count(for: req) {
            return Int64(num)
        }
        return 0
    }
    
    func reorder(for collection: Collections){
        let context = container.viewContext
        let req: NSFetchRequest<Stickers> = Stickers.fetchRequest()
        req.predicate = NSPredicate(format: "collection=%@", collection)
        let items = try! context.fetch(req)
        
        for item in items {
            item.order = Int64(items.firstIndex(of: item)! * 10)
        }
        save()
    }
}
