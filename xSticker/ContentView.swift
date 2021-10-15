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
                    ForEach(0..<1){ item in
                        NavigationLink(
                            destination: StickerCollectionView(persistence: persistence),
                            label: {
                                VStack(spacing: 10){
                                    Image(systemName: "plus")
                                        .frame(width: 100, height: 100, alignment: .center)
                                        .background(Color.white)
                                        .cornerRadius(20)
                                        .shadow(radius: 10)
                                    Text("\(persistence.defaultCollection.name!)")
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
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Stickers.order, ascending: true)])
    private var items: FetchedResults<Stickers>
    
    @State var isImagePickerViewPresented = false

    @State var currentDrag: Stickers?
    
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
                            .cornerRadius(20)
                            .shadow(radius: 10)
                        Text("添加")
                            .font(.body)
                            .lineLimit(1)
                            .minimumScaleFactor(0.3)
                    }
                })
                
                ForEach(items){ item in
                    NavigationLink(
                        destination: StickerDetailView(sticker: item, persistence: persistence),
                        label: {
                            VStack(spacing: 10){
                                Image(uiImage: stickerManager.get(sticker: item))
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100, alignment: .center)
                                    .background(Color.white)
                                    .cornerRadius(20)
                                    .shadow(radius: 10)
                                Text("\(item.name!)\(item.order)")
                                    .font(.body)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.3)
                            }
                        })
//                        .onDrag({
//                            currentDrag = item
//                            return NSItemProvider(object: NSString(string: item.name!))
//                        })
//                        .onDrop(of: [.text], delegate: StickerDragRelocateDelegate(item: item, listData: items, current: $currentDrag, persistence: persistence))
                }
            }.padding()
            
        }
        .animation(.easeInOut)
        .navigationTitle(persistence.defaultCollection.name!)
        .sheet(isPresented: $isImagePickerViewPresented){
            ImagePickerView(
                filter: .any(of: [.images, .livePhotos]),
                selectionLimit: 0,
                delegate: ImagePickerView.Delegate(
                    isPresented: $isImagePickerViewPresented,
                    didCancel: { (phPickerViewController) in print("Did Cancel: \(phPickerViewController)") },
                    didSelect: { (result) in
                        let phPickerViewController = result.picker
                        let images = result.images
                        print("Did Select images: \(images) from \(phPickerViewController)")
                        let pickedImages = images
                        
                        for img in pickedImages {
                            let sticker = persistence.addSticker(with: "Sticker", in: persistence.defaultCollection)
                            let stauts = stickerManager.save(image: img, named: sticker)
                            if stauts {
                                sticker.hasSaved = true
                                persistence.save()
                            }
                        }
                    },
                    didFail: { (imagePickerError) in
                        let phPickerViewController = imagePickerError.picker
                        let error = imagePickerError.error
                        print("Did Fail with error: \(error) in \(phPickerViewController)")
                    }
                )
            )
            
        }
    }
}

struct StickerDetailView: View {
    var sticker: Stickers
    var persistence: PersistenceController
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    var body: some View {
        Form{
            Section(
                header:
                    Image(uiImage: stickerManager.get(sticker: sticker))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()
            ){
                List{
                    Text(sticker.name ?? "")
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

struct StickerDragRelocateDelegate: DropDelegate {
    let item: Stickers
    var listData: FetchedResults<Stickers>
    @Binding var current: Stickers?
    
    let persistence: PersistenceController
    
    func dropEntered(info: DropInfo) {
        print(item)
//        withAnimation(.easeInOut) {
//            if item != current {
//                let from = listData.firstIndex(of: current!)!
//                let to = listData.firstIndex(of: item)!
//                if item.image! != current!.image! {
//                    current!.order = Int64(to > from ? FetchedResults<Stickers>.Index(item.order + 1) : to)
//                    print("!!!!!!!!!!!")
//                }
//                print(from, to, item.image, current?.image)
//                
//                persistence.save()
//            }
//                        persistence.reorder(for: item.collection!)
//        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        self.current = nil
        return true
    }
}
