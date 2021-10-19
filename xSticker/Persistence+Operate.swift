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
        sticker.order = 0
        
        save()
        
        print(count(collection: collection))
        if count(collection: collection) == 1 {
            collection.profile = sticker.image
            save()
        }
        
        reorder(for: collection)
        return sticker
    }
    
    func removeSticker(of sticker: Stickers) {
        let collection = sticker.collection!
        container.viewContext.delete(sticker)
        save()
    }
    
    func addCollection(with name: String) -> Collections {
        let collection = Collections(context: container.viewContext)
        
        collection.author = "xSticker"
        collection.collectionDescription = "It's a collection"
        collection.createDate = Date()
        collection.id = UUID()
        collection.name = name
        collection.order = 1
        
        reorder()
        save()
        return collection
    }
    
    func removeCollection(of collection: Collections) {
        container.viewContext.delete(collection)
        
        save()
    }
    
    func count(collection: Collections) -> Int {
        container.viewContext.refresh(collection, mergeChanges: false)
        let context = container.viewContext
        let req: NSFetchRequest<Stickers> = Stickers.fetchRequest()
        
        req.predicate = NSPredicate(format: "collection=%@", collection)
        
        if let num = try? context.count(for: req) {
            return num
        }
        return 0
    }
    
    func reorder(for collection: Collections){
        let context = container.viewContext
        let req: NSFetchRequest<Stickers> = Stickers.fetchRequest()
        req.predicate = NSPredicate(format: "collection=%@", collection)
        req.sortDescriptors = [NSSortDescriptor(keyPath: \Stickers.order, ascending: true)]
        let items = try! context.fetch(req)
        
        for index in 0..<items.count {
            items[index].order = Int64(index + 1)
        }
        save()
    }
    
    func reorder() {
        let context = container.viewContext
        let req: NSFetchRequest<Collections> = Collections.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(keyPath: \Collections.order, ascending: true)]
        let items = try! context.fetch(req)
        
        for index in 1..<items.count {
            items[index].order  = Int64(index + 1)
        }
        save()
    }
}

@propertyWrapper struct LocalSetingWrapper {
    private var name: String
    private var context: NSManagedObjectContext
    
    var wrappedValue: String? {
        set {
            let req: NSFetchRequest<LocalSettings> = LocalSettings.fetchRequest()
            req.predicate = NSPredicate(format: "name=%@", self.name)
            guard let res = try? context.fetch(req) else { return }
            guard let first = res.first else { return }
            
            first.val = newValue
            try? context.save()
        }
        get {
            let req: NSFetchRequest<LocalSettings> = LocalSettings.fetchRequest()
            req.predicate = NSPredicate(format: "name=%@", self.name)
            guard let res = try? context.fetch(req) else { return nil }
            guard let first = res.first else {
                let l = LocalSettings(context: context)
                l.name = name
                l.val = nil
                return nil
            }
            return first.val
        }
    }
    
    init(name: String, _ persistence: PersistenceController) {
        self.name = name
        self.context = persistence.container.viewContext
    }
}

class LocalSettingsManager {
    var persistence: PersistenceController
    
    var lastUsedCollection: LocalSetingWrapper /// UUID
    
    init(with persistence: PersistenceController) {
        self.persistence = persistence
        
        lastUsedCollection = LocalSetingWrapper(name: "LastUsedCollection", persistence)
    }
}
