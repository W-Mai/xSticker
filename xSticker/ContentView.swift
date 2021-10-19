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

// MARK: - 🏞预览
struct ContentView_Previews: PreviewProvider {
    static let persistenceController = PersistenceController.preview
    
    static var previews: some View {
        ContentView(persistenceController: PersistenceController.preview).environment(\.managedObjectContext, persistenceController.container.viewContext)
    }
}

// MARK: - 🌅主视图
struct ContentView: View {
    var persistence: PersistenceController
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var envSettings: EnvSettings
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Collections.order, ascending: true)])
    private var collections: FetchedResults<Collections>
    
    init(persistenceController: PersistenceController) {
        persistence = persistenceController
    }
    
    @State var isShowingAbout = false
    
    var body: some View {
        NavigationView{
            ScrollView(.vertical){
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), alignment: .top)], spacing: 10) {
                    ForEach(collections){ item in
                        if !(envSettings.isEditing && item == persistence.defaultCollection){
                        NavigationLink(
                            destination: StickerCollectionView(persistence: persistence, collection: item),
                            label: {
                                OneCollectionEntryView(persistence: persistence,
                                                       item: Binding(get: { item }, set: { v in }))
                                    .animation(.spring(response: 0.3, dampingFraction: 0.8))
                            }).contextMenu(item == persistence.defaultCollection ? nil : ContextMenu{
                                Text("\(item.name ?? "")")
                                Divider()
                                Button {
                                    item.order = 1
                                    persistence.reorder()
                                } label: {
                                    Text("移到前面去！")
                                }
                                Button {
                                    deleteCollection(collection: item)
                                } label: {
                                    Text("删除「\(item.name ?? "")」").foregroundColor(.red)
                                }
                            })
                        }
                    }
                }.padding()
            }.navigationBarTitle(Text("俺的Sticker"))
            .navigationViewStyle(DoubleColumnNavigationViewStyle())
            .navigationBarItems(trailing: HStack(spacing: 20){
                Button {
                    envSettings.isEditing.toggle()
                } label: {
                    Image(systemName: !envSettings.isEditing ? "square.and.pencil" : "checkmark.circle")
                }
                   
                if !envSettings.isEditing {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            let collection = persistence.addCollection(with: "Collection")
                            _ = stickerManager.createCollectionDir(for: collection)
                        }
                    } label: {
                        Image(systemName: "rectangle.stack.badge.plus")
                    }
                    if UIDevice.current.userInterfaceIdiom != .pad {
                        Button {
                            isShowingAbout = true
                        } label: {
                            Text("🤔")
                        }
                    }
                }
            }.animation(.spring(response: 0.3, dampingFraction: 0.6)))
            .sheet(isPresented: $isShowingAbout) {
                VStack(spacing: 30){
                    xAbout()
                    
                    Text("快快") + Text("选中").bold() + Text("、") + Text("创建").bold() + Text("、") + Text("修改").bold() + Text("自己喜欢的表情包叭!")
                    
                    Spacer()
                }.padding([.top], 100)
                .foregroundColor(Color("AccentColor"))
            }
            
            VStack(spacing: 30){
                xAbout()
                Text("打开侧边栏") + Text("选中").bold() + Text("、") + Text("创建").bold() + Text("、") + Text("修改").bold() + Text("自己喜欢的表情包叭!")
                Spacer()
            }.foregroundColor(Color("AccentColor"))
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
    
    private func deleteCollection(collection: Collections) {
        _ = stickerManager.delete(collection: collection)
        persistence.removeCollection(of: collection)
    }
}

// MARK: - 🕳️一个Collection的入口按钮样子
struct OneCollectionEntryView : View {
    var persistence: PersistenceController
    @Binding var item: Collections
    
    @EnvironmentObject var envSettings: EnvSettings
    
    @State var isShowingAlert = false
    
    var body: some View{
        VStack(spacing: 10){
            VStack{
                Image(uiImage: stickerManager.get(profile: item))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 96, height: 96, alignment: .center)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }.padding(2)
            .background(Color("AccentColor").opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: Color("AccentColor").opacity(0.2), radius: 6, x: 0, y: 5)
            Text("\(item == persistence.defaultCollection ? "我喜欢" : (item.name ?? "Deleted"))")
                .font(.body)
                .lineLimit(1)
                .minimumScaleFactor(0.3)
        }.overlay(VStack {HStack{
            Button {
                isShowingAlert = true
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .imageScale(.large)
                    .foregroundColor(.red)
            }.alert(isPresented: $isShowingAlert) {
                Alert(title: Text("您真的要残忍的删除我「\(item.name ?? "已删除")」了么"),
                      primaryButton: .default(Text("对，很凶残！"), action: {
                        print(item)
                        _ = stickerManager.delete(collection: item)
                        persistence.removeCollection(of: item)
                      }), secondaryButton: .cancel())
            }
            Spacer()
        }
        Spacer()
        }.offset(x: -8, y: -8)
        .opacity(envSettings.isEditing ? 1 : 0)
        )
        
    }
}

// MARK: - 😊贴纸集内容视图
struct StickerCollectionView: View {
    var persistence: PersistenceController
    var collection: Collections
    
    @Environment(\.managedObjectContext) private var viewContext
    private var items: FetchRequest<Stickers>
    
    @State var isImagePickerViewPresented = false
    @State var isCollectionInfoViewPresented = false
    
    @State var isAnimating = false
    @State var isProccesing = false
    @State var isShowingStickerDetails = false
    
    let collectionName: String!
    
    init(persistence: PersistenceController, collection: Collections) {
        self.persistence = persistence
        self.collection = collection
        self.items = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Stickers.order, ascending: true)], predicate: NSPredicate(format: "collection=%@", self.collection))
        collectionName = collection == persistence.defaultCollection ? "我喜欢" : (collection.name ?? "已删除")
    }
    
    // MARK: 🏷️一个表情
    fileprivate func OneStickerShowView(_ item: Stickers) -> some View {
        return VStack(spacing: 10){
            VStack{
                Image(uiImage: stickerManager.get(sticker: item))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 96, height: 96, alignment: .center)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }.padding(2)
            .background(Color("AccentColor").opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: Color("AccentColor").opacity(0.2), radius: 6, x: 0, y: 5)
            Text("\(item.name ?? "已删除")")
                .font(.body)
                .lineLimit(1)
                .minimumScaleFactor(0.3)
        }.padding(10)
        .drawingGroup()
    }
    
    // MARK: - 🌁图片选择器
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
                                
                                let sticker = persistence.addSticker(with: "贴贴", in: collection)
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
    
    // MARK: - 💾当前集合关于页面
    fileprivate func CurrentInfomationView() -> some View {
        let image = stickerManager.get(profile: collection, targetSize: 600)
        return
            NavigationView{
                Form{
                    Section(
                        header:
                            HStack(alignment: .center){
                                VStack{
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxWidth: 300)
                                        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                                }
                                .padding()
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 46, style: .continuous))
                                .padding(2)
                                .background(Color("AccentColor"))
                                .clipShape(RoundedRectangle(cornerRadius: 48, style: .continuous))
                                .padding([.bottom], 30)
                            }.frame(maxWidth: .infinity)
                    ){
                        List{
                            if collection == persistence.defaultCollection {
                                Label("我喜欢", systemImage: "square.grid.2x2")
                            } else {
                                NavigationEditor(
                                    title: "贴贴集名字", systemImage: "square.grid.2x2",
                                    text: Binding(get: { collection.name ?? "" }, set: { v in collection.name = v }))
                            }
                            NavigationEditor(
                                title: "贴贴集作者", systemImage: "person.circle",
                                text: Binding(get: { collection.author ?? "" }, set: { v in collection.author = v }))
                            NavigationEditor(
                                title: "贴贴集描述", systemImage: "doc.plaintext",
                                text: Binding(get: { collection.collectionDescription ?? "" }, set: { v in collection.collectionDescription = v }),
                                longTextMode: true)
                        }
                    }
                    
                    Section {
                        Label("\(image.size.width, specifier: "%.1f") x \(image.size.height, specifier: "%.1f")", systemImage: "aspectratio")
                        Label("\(collection.stickerSet?.count ?? 0)", systemImage: "number")
                        Label("\(collection.createDate ?? Date(), formatter: itemFormatter)", systemImage: "calendar")
                    }
                    
                    Section{
                        if collection == persistence.defaultCollection && items.wrappedValue.count != 0 {
                            Button(action: {
                                items.wrappedValue.forEach { sticker in
                                    _ = stickerManager.delete(sticker: sticker)
                                    persistence.removeSticker(of: sticker)
                                    print(sticker)
                                }
                                isCollectionInfoViewPresented = false
                            }, label: {
                                Label("清空「我喜欢」", systemImage: "trash.circle")
                                    .foregroundColor(.red)
                            })
                        } else if collection != persistence.defaultCollection {
                            Button(action: {
                                _ = stickerManager.delete(collection: collection)
                                persistence.removeCollection(of: collection)
                                isCollectionInfoViewPresented = false
                            }, label: {
                                Label("删掉我呗", systemImage: "trash.circle")
                                    .foregroundColor(.red)
                            })
                        }
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
                                .padding()
                                .frame(width: 60, height: 60, alignment: .center)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .shadow(color: Color("ShadowColor").opacity(0.3), radius: 6, x: 0, y: 5)
                        }.padding(30)
                    })
                    
                    ForEach(items.wrappedValue){ item in
                        NavigationLink(
                            destination: StickerDetailView(sticker: item, persistence: persistence),
                            label: {
                                OneStickerShowView(item)
                            }
                        )
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
            .sheet(isPresented: $isCollectionInfoViewPresented, onDismiss: {
                persistence.save()
            }) {
                CurrentInfomationView()
            }
            
            if isAnimating {
                Color.white.opacity(0.1)
            }
        }
    }
}


// MARK: - 🦸‍♀️贴纸详细内容视图
struct StickerDetailView: View {
    var sticker: Stickers
    var persistence: PersistenceController
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    var body: some View {
        let image = stickerManager.get(sticker: sticker)
        print(sticker)
        return Form{
            Section(
                header:
                    HStack(alignment: .center){
                        VStack{
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: 300)
                                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                        }
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 46, style: .continuous))
                        .padding(2)
                        .background(Color("AccentColor"))
                        .clipShape(RoundedRectangle(cornerRadius: 48, style: .continuous))
                        .padding([.bottom], 30)
                    }.frame(maxWidth: .infinity)
            ){
                List{
                    NavigationEditor(
                        title: "贴贴名字", systemImage: "square.grid.2x2",
                        text: Binding(get: { sticker.name ?? "" }, set: { v in sticker.name = v }))
                }
            }
            
            Section{
                Label("\(image.size.width, specifier: "%.1f") x \(image.size.height, specifier: "%.1f")", systemImage: "aspectratio")
                Label("\(sticker.addDate ?? Date(), formatter: itemFormatter)", systemImage: "calendar")
                Label("\(stickerManager.get(sizeStr: sticker))", systemImage: "doc")
                Label("\(sticker.order)", systemImage: "number.circle")
            }
            
            Section{
                Button {
                    let collection = sticker.collection
                    collection?.profile = sticker.image
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Label("设置「\(sticker.name ?? "已删除")」为封面", systemImage: "heart.text.square")
                }
            }
            
            Section{
                Button(action: {
                    sticker.hasSaved = false
                    _ = stickerManager.delete(sticker: sticker)
                    persistence.removeSticker(of: sticker)
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Label("删掉我呗", systemImage: "trash.circle")
                        .foregroundColor(.red)
                })
            }
        }.navigationBarTitle(sticker.name ?? "已删除")
        .onDisappear {
            persistence.save()
        }
    }
}


// MARK: - 🚄导航编辑器（其实就是编辑器可以通过导航导航到）
struct NavigationEditor: View {
    var title: String
    var systemImage: String
    @Binding var text: String
    var longTextMode = false
    
    var body: some View {
        NavigationLink(
            destination:
                NavigationEditorEditor(title: title, text: $text, longTextMode: longTextMode)
        ) {
            Label(text, systemImage: systemImage)
        }
    }
    
    private struct NavigationEditorEditor: View {
        var title: String
        @Binding var text: String
        var longTextMode: Bool
        
        @Environment(\.presentationMode) var presentationMode
        
        var body: some View {
            Form{
                if longTextMode {
                    TextEditor(text: $text).frame(minHeight: 300)
                } else {
                    MyTextField(text: $text) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }.navigationBarTitle(title)
        }
    }
}


// MARK: - 😯关于
struct xAbout: View {
    var body: some View{
        let info = Bundle.main.infoDictionary!
        let name = info["CFBundleDisplayName"] as! String
        let version = "Verison \(info["CFBundleShortVersionString"]!) build \(info["CFBundleVersion"]!)"
        VStack(alignment: .center, spacing: 20){
            Image("AppIcon-UsedForShowing").resizable().frame(width: 100, height: 100, alignment: .center).clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color("ShallowShadowColor"), radius: 10, x: 0.0, y: 0.0)
            Text("\(name)")
            Text(version)
            HStack{
                Image(systemName: "42.square")
                Text("SETTINGS.ABOUT.AUTHOR")
                Text("W-Mai").foregroundColor(.secondary)
            }
            HStack{
                Image(systemName: "house")
                Text("SETTINGS.ABOUT.STUDIO")
                Text("XCLZ STUDIO").foregroundColor(.secondary)
            }
        }.frame(maxWidth: .infinity)
    }
}
