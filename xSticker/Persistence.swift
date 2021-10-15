//
//  Persistence.swift
//  xSticker
//
//  Created by W-Mai on 2021/10/14.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<10 {
            let newItem = Stickers(context: viewContext)
            newItem.name = UUID().uuidString
            newItem.image = UUID()
        }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentCloudKitContainer

    var defaultCollection: Collections!
    
    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "xSticker")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            let rootPath = GroupRootPath
            
            // Create a store description for a local store
            let localStoreLocation = URL(fileURLWithPath: rootPath.path + "/local.store")
            let localStoreDescription =
                NSPersistentStoreDescription(url: localStoreLocation)
            localStoreDescription.configuration = "Default"
            
            container.persistentStoreDescriptions = [
                localStoreDescription
            ]
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                Typical reasons for an error here include:
                * The parent directory does not exist, cannot be created, or disallows writing.
                * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                * The device is out of space.
                * The store could not be migrated to the current model version.
                Check the error message to determine what the actual problem was.
                */
                
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        defaultCollection = initDefaultCollection()
        _ = stickerManager.createCollectionDir(for: defaultCollection)
    }
    
    func initDefaultCollection() -> Collections{
        let context = container.viewContext
        
        let fetchReq: NSFetchRequest<Collections> = Collections.fetchRequest()
        fetchReq.predicate = NSPredicate(format: "name=%@", "DefaultStickerCollection")
        
        let res = try? context.fetch(fetchReq)
        if res == nil || res?.count == 0 {
            let collection = Collections(context: context)
            collection.id = UUID()
            collection.name = "DefaultStickerCollection"
            collection.author = "xSticker"
            collection.createDate = Date()
            collection.collectionDescription = "The default collection of stickers"
            
            try? context.save()
            
            return collection
        }
        return res!.first!
    }
}
