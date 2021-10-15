//
//  ContentView.swift
//  xSticker
//
//  Created by W-Mai on 2021/10/14.
//

import SwiftUI
import CoreData
import ImagePickerView

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
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Collections.createDate, ascending: false)])
    private var collections: FetchedResults<Collections>
    
    init(persistenceController: PersistenceController) {
        let url = Bundle.main.bundleURL.path + "/TmpStickers" + "/ld.jpg"
        NSLog("???%@", url)
        
        let url2 = Bundle.main.url(forResource: "ld", withExtension: "jpg")?.path
        NSLog("???%@", url2!)
        
        persistence = persistenceController
    }
    
    var body: some View {
        NavigationView{
            ScrollView(.vertical){
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 20) {
                    ForEach(collections){ item in
                        NavigationLink(
                            destination: StickerCollectionView(persistence: persistence),
                            label: {
                                VStack(spacing: 10){
                                    Image(uiImage: stickerManager.get(profile: item))
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100, alignment: .center)
                                        .background(Color.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                        .shadow(color: Color("ShadowColor").opacity(0.6), radius: 6, x: 0, y: 5)
                                    Text("\(item.name!)")
                                        .font(.body)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.3)
                                }
                            })
                    }
                }.padding()
            }.navigationTitle("Collection")
            .navigationViewStyle(StackNavigationViewStyle())
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
    
    @Environment(\.managedObjectContext) private var viewContext
//    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Stickers.addDate, ascending: false)], predicate: NSPredicate(format: "collection", persistence.defaultCollection))
    private var items: FetchRequest<Stickers>
    
    @State var isImagePickerViewPresented = false

    @State var isAnimating = false
    @State var isProccesing = false
    
    
    init(persistence: PersistenceController) {
        self.persistence = persistence
        self.items = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Stickers.addDate, ascending: false)], predicate: NSPredicate(format: "collection=%@", persistence.defaultCollection))
        
    }
    
    var body: some View {
        ScrollView(.vertical){
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 20) {
                Button(action: {
//                    _ = persistence.addSticker(with: "Sticker", in: persistence.defaultCollection)
                    isImagePickerViewPresented = true
                    
                }, label: {
                    VStack(spacing: 10){
                        Image(systemName: "plus")
                            .frame(width: 60, height: 60, alignment: .center)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .shadow(color: Color("ShadowColor").opacity(0.6), radius: 6, x: 0, y: 5)
                        Text("添加")
                            .font(.body)
                            .lineLimit(1)
                            .minimumScaleFactor(0.3)
                    }
                })
                
                ForEach(items.wrappedValue){ item in
                    NavigationLink(
                        destination: StickerDetailView(sticker: item, persistence: persistence),
                        label: {
                            VStack(spacing: 10){
                                Image(uiImage: stickerManager.get(sticker: item))
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100, alignment: .center)
//                                    .background(Color.white)
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
            }.padding()
            .animation(isAnimating ? .easeInOut : .none)
        }
        .navigationTitle(persistence.defaultCollection.name!)
        .sheet(isPresented: $isImagePickerViewPresented){
            ZStack{
                ImagePickerView(
                    filter: .any(of: [.images, .livePhotos]),
                    selectionLimit: 0,
                    delegate: ImagePickerView.Delegate(
                        isPresented: $isImagePickerViewPresented,
                        isProccesing: $isProccesing,
                        didCancel: { (phPickerViewController) in print("Did Cancel: \(phPickerViewController)") },
                        didSelect: { (result) in
                            isAnimating = true
                            DispatchQueue.main.async {
                                let phPickerViewController = result.picker
                                let images = result.images
                                print("Did Select images: \(images) from \(phPickerViewController)")
                                let pickedImages = images
                                for img in pickedImages {
                                    let sticker = persistence.addSticker(with: "Sticker", in: persistence.defaultCollection)
                                    let stauts = stickerManager.save(image: img, named: sticker)
                                    if stauts {
                                        sticker.hasSaved = true
                                    }
                                }
                                persistence.save()
                                isAnimating = false
                            }
                            
                            
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
                    Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()
            ){
                List{
                    Text(sticker.name ?? "")
                    Text(image.size.debugDescription)
                    Text(sticker.addDate ?? Date(), style: .date)
                    Text(sticker.collection?.name ?? "")
                }
                Button(action: {
                    sticker.hasSaved = false
                    let res = stickerManager.delete(sticker: sticker)
                    if res {
                        persistence.removeSticker(of: sticker)
                    }
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Text("删掉我吧！").foregroundColor(.red)
                })
            }
        }
    }
}
