//
//  ContentView.swift
//  xSticker
//
//  Created by W-Mai on 2021/10/14.
//

import SwiftUI
import CoreData

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static let persistenceController = PersistenceController.preview
    
    static var previews: some View {
        ContentView(persistenceController: PersistenceController.preview).environment(\.managedObjectContext, persistenceController.container.viewContext)
    }
}

struct ContentView: View {
    var persistence: PersistenceController
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Collections.createDate, ascending: true)])
    private var collections: FetchedResults<Collections>
    
    init(persistenceController: PersistenceController) {
        persistence = persistenceController
    }
    
    var body: some View {
        NavigationView{
            ScrollView(.vertical){
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), alignment: .top)], spacing: 20) {
                    ForEach(collections){ item in
                        NavigationLink(
                            destination: StickerCollectionView(persistence: persistence, collection: item),
                            label: {
                                VStack(spacing: 10){
                                    Image(uiImage: stickerManager.get(profile: item))
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100, alignment: .center)
                                        .background(Color.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                        .shadow(color: Color("ShadowColor").opacity(0.6), radius: 6, x: 0, y: 5)
                                    Text("\(item == persistence.defaultCollection ? "我喜欢" : (item.name ?? "Deleted"))")
                                        .font(.body)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.3)
                                }
                            })
                    }
                }.padding()
            }.navigationBarTitle(Text("俺的Sticker"))
            .navigationViewStyle(StackNavigationViewStyle())
            .navigationBarItems(trailing: HStack(spacing: 20){
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        let collection = persistence.addCollection(with: "Collection")
                        _ = stickerManager.createCollectionDir(for: collection)
                    }
                } label: {
                    Image(systemName: "rectangle.stack.badge.plus")
                }
                Button {
                    
                } label: {
                    Text("🤔")
                }
            })
        }
        
    }
    
    private func addItem() {
        
        withAnimation {
            let collection = persistence.defaultCollection
            
            let sticker = Stickers(context: viewContext)
            sticker.collection = collection
            sticker.image = UUID()
            sticker.name = UUID().uuidString
            
            try? viewContext.save()
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            //            offsets.map { items[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}


struct StickerCollectionView: View {
    var persistence: PersistenceController
    var collection: Collections
    
    @Environment(\.managedObjectContext) private var viewContext
    private var items: FetchRequest<Stickers>
    
    @State var isImagePickerViewPresented = false
    @State var isCollectionInfoViewPresented = false
    
    @State var isAnimating = false
    @State var isProccesing = false
    
    let collectionName: String!
    
    init(persistence: PersistenceController, collection: Collections) {
        self.persistence = persistence
        self.collection = collection
        self.items = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Stickers.addDate, ascending: false)], predicate: NSPredicate(format: "collection=%@", self.collection))
        collectionName = collection == persistence.defaultCollection ? "我喜欢" : (collection.name ?? "已删除")
    }
    
    fileprivate func OneStickerShowView(_ item: FetchedResults<Stickers>.Element) -> some View {
        return NavigationLink(
            destination: StickerDetailView(sticker: item, persistence: persistence),
            label: {
                VStack(spacing: 10){
                    Image(uiImage: stickerManager.get(sticker: item))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100, alignment: .center)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: Color("ShadowColor").opacity(0.6), radius: 6, x: 0, y: 5)
                    Text("\(item.name!)\(item.order)")
                        .font(.body)
                        .lineLimit(1)
                        .minimumScaleFactor(0.3)
                }.padding(10)
                .drawingGroup()
            }
        )
    }
    
    fileprivate func CurrentImagePickerView() -> some View {
        return ZStack{
            ImagePickerView(
                filter: .any(of: [.images, .livePhotos]),
                selectionLimit: 0,
                delegate: ImagePickerView.Delegate(
                    isPresented: $isImagePickerViewPresented,
                    isProccesing: $isProccesing,
                    didCancel: { (phPickerViewController) in print("Did Cancel: \(phPickerViewController)") },
                    didSelect: { (result) in
                        isAnimating = true
                        let phPickerViewController = result.picker
                        let images = result.images
                        print("Did Select images: \(images) from \(phPickerViewController)")
                        let pickedImages = images
                        DispatchQueue.main.async {
                            for img in pickedImages {
                                
                                let sticker = persistence.addSticker(with: "Sticker", in: collection)
                                let stauts = stickerManager.save(image: img, named: sticker)
                                if stauts {
                                    sticker.hasSaved = true
                                    persistence.save()
                                }
                            }
                        }
                        isAnimating = false
                    },
                    didFail: { (imagePickerError) in
                        let phPickerViewController = imagePickerError.picker
                        let error = imagePickerError.error
                        print("Did Fail with error: \(error) in \(phPickerViewController)")
                    }
                )
            ).blur(radius: isProccesing ? 5 : 0)
            
            if isProccesing {
                Color.white.opacity(0.1)
                    .overlay(
                        ProgressView()
                            .scaleEffect(3)
                    )
            }
        }
    }
    
    fileprivate func CurrentInfomationView() -> some View {
        let image = stickerManager.get(profile: collection, targetSize: 600)
        return
            NavigationView{
                Form{
                    Section(
                        header:
                            VStack{
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                            }
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 46, style: .continuous))
                            .padding([.vertical], 30)
                        
                    ){
                        List{
                            Text(collection.name ?? "")
                            Text(collection.collectionDescription ?? "")
                            Text(image.size.debugDescription)
                            Text(collection.createDate ?? Date(), style: .date)
                            Text("\(collection.stickerSet?.count ?? 0)")
                        }
                    }
                    if collection == persistence.defaultCollection && items.wrappedValue.count != 0 {
                        Button(action: {
                            items.wrappedValue.forEach { sticker in
                                _ = stickerManager.delete(sticker: sticker)
                                persistence.removeSticker(of: sticker)
                                print(sticker)
                            }
                            isCollectionInfoViewPresented = false
                        }, label: {
                            Text("清空「我喜欢」").foregroundColor(.red)
                        })
                    } else if collection != persistence.defaultCollection {
                        Button(action: {
                            _ = stickerManager.delete(collection: collection)
                            persistence.removeCollection(of: collection)
                            isCollectionInfoViewPresented = false
                        }, label: {
                            Text("删掉我吧！").foregroundColor(.red)
                        })
                    }
                }
                .navigationBarTitle(self.collectionName)
                .navigationBarItems(trailing: Button(action: {
                    isCollectionInfoViewPresented = false
                }, label: {
                    Text("好")
                }))
            }
    }
    
    var body: some View {
        ZStack {
            ScrollView(.vertical){
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), alignment: .top)], spacing: 20) {
                    Button(action: {
                        isImagePickerViewPresented = true
                    }, label: {
                        VStack(spacing: 10){
                            Image(systemName: "heart.circle")
                                .resizable()
                                .foregroundColor(.red)
                                .padding()
                                .frame(width: 60, height: 60, alignment: .center)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .shadow(color: Color("ShadowColor").opacity(0.3), radius: 6, x: 0, y: 5)
                        }.padding(30)
                    })
                    
                    ForEach(items.wrappedValue){ item in
                        OneStickerShowView(item)
                    }
                }.padding()
                .animation(isAnimating ? .easeInOut(duration: 0.3) : .none)
            }
            .navigationTitle(collectionName)
            .navigationBarItems(trailing: HStack {
                Button {
                    isCollectionInfoViewPresented = true
                } label: {
                    Image(systemName: "info.circle")
                }
            })
            .sheet(isPresented: $isImagePickerViewPresented){
                CurrentImagePickerView()
            }
            .sheet(isPresented: $isCollectionInfoViewPresented) {
                CurrentInfomationView()
            }
            
            if isAnimating {
                Color.white.opacity(0.1)
            }
        }
    }
}

struct StickerDetailView: View {
    var sticker: Stickers
    var persistence: PersistenceController
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    var body: some View {
        let image = stickerManager.get(sticker: sticker)
        
        Form{
            Section(
                header:
                    VStack{
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                    }
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 46, style: .continuous))
                    .padding([.bottom], 30)
            ){
                List{
                    Text(sticker.name ?? "")
                    Text(image.size.debugDescription)
                    Text(sticker.addDate ?? Date(), style: .date)
                    Text(sticker.collection?.name ?? "")
                }
                Button(action: {
                    sticker.hasSaved = false
                    _ = stickerManager.delete(sticker: sticker)
                    persistence.removeSticker(of: sticker)
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Text("删掉我吧！").foregroundColor(.red)
                })
            }
        }.navigationBarTitle(sticker.name ?? "已删除")
    }
}
