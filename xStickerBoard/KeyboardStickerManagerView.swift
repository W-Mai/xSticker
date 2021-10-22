//
//  KeyboardStickerManagerView.swift
//  xSticker
//
//  Created by W-Mai on 2021/10/22.
//

import SwiftUI
import CoreData

class CollectionModel: ObservableObject {
    @Published var v: Collections!
}

struct KeyboardStickerManagerView: View {
    var persistence: PersistenceController
    @ObservedObject var collection: CollectionModel
    
    
    init(collection: CollectionModel, persistence: PersistenceController) {
        self.persistence = persistence
        self.collection = collection
    }
    
    var body: some View {
        KeyboardStickerManagerContentView(collection: collection.v, persistence: persistence)
    }
}

struct KeyboardStickerManagerContentView: View {
    var persistence: PersistenceController
    var collection: Collections
    
    var stickers: FetchRequest<Stickers>
    
    init(collection: Collections, persistence: PersistenceController) {
        self.collection = collection
        self.persistence = persistence
        
        self.stickers = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Stickers.order, ascending: true)], predicate: NSPredicate(format: "collection=%@", self.collection))
    }
    
    var body: some View{
        ScrollView(.vertical){
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], alignment: .center, spacing: nil, pinnedViews: [], content: {
                ForEach(stickers.wrappedValue){ sticker in
                    Image(uiImage: stickerManager.get(sticker: sticker, targetSize: 80))
                        .resizable()
                        .frame(width: 60, height: 60, alignment: .center)
                        .onDrag({ NSItemProvider(object: stickerManager.get(sticker: sticker)) })
                }
            }).padding()
        }
    }
}

struct KeyboardStickerManagerView_Previews: PreviewProvider {
    static var persistence = PersistenceController.preview
    static var collection: Collections {
        let c = Collections(context: persistence.container.viewContext)
        c.author = "aaa"
        c.name = "bbb"
        return c
    }
    static var collectionModel :CollectionModel{
        let model = CollectionModel()
        model.v = collection
        return model
    }
    
    static var previews: some View {
        KeyboardStickerManagerView(collection: collectionModel, persistence: persistence)
    }
}
