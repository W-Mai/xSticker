//
//  KeyboardStickerManagerView.swift
//  xSticker
//
//  Created by W-Mai on 2021/10/22.
//

import SwiftUI

class CollectionModel: ObservableObject {
    @Published var v: Collections!
}

struct KeyboardStickerManagerView: View {
    @ObservedObject var collection: CollectionModel
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], alignment: .center, spacing: nil, pinnedViews: [], content: {
            Text(collection.v.name ?? "name")
            Text(collection.v.author ?? "author")
        })
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
        KeyboardStickerManagerView(collection: collectionModel)
    }
}
