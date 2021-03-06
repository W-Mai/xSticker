//
//  ContentView.swift
//  xSticker
//
//  Created by W-Mai on 2021/10/14.
//

import SwiftUI
import AVKit
import CoreData
import UniformTypeIdentifiers

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

// MARK: - πι’θ§
struct ContentView_Previews: PreviewProvider {
    static let persistenceController = PersistenceController.preview
    
    static var previews: some View {
        ContentView(persistenceController: PersistenceController.preview).environment(\.managedObjectContext, persistenceController.container.viewContext)
    }
}

// MARK: - πδΈ»θ§εΎ
struct ContentView: View {
    var persistence: PersistenceController
    var localSettingsManager :LocalSettingsManager!
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var envSettings: EnvSettings
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Collections.order, ascending: true)])
    private var collections: FetchedResults<Collections>
    
    @State var needShowWelcome: Bool = false
    
    init(persistenceController: PersistenceController) {
        persistence = persistenceController
        localSettingsManager = LocalSettingsManager(with: persistence)
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
                                    Text("η§»ε°ει’ε»οΌ")
                                }
                                Divider()
                                Button {
                                    deleteCollection(collection: item)
                                } label: {
                                    Text("ε ι€γ\(item.name ?? "")γ").foregroundColor(.red)
                                }
                            })
                        }
                    }
                }.padding()
            }.navigationBarTitle(Text("δΏΊηSticker"))
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
                            Text("π€")
                        }
                    }
                }
            }.animation(.spring(response: 0.3, dampingFraction: 0.6)))
            .sheet(isPresented: $isShowingAbout) {
                VStack(spacing: 30){
                    xAbout()

                    Text("εΏ«εΏ«") + Text("ιδΈ­").bold() + Text("γ") + Text("εε»Ί").bold() + Text("γ") + Text("δΏ?ζΉ").bold() + Text("θͺε·±εζ¬’ηθ‘¨ζεε­!")

                    Spacer()
                }.padding([.top], 100)
                .foregroundColor(Color("AccentColor"))
            }
            .sheet(isPresented: $needShowWelcome) {
                welcomePage(showing: $needShowWelcome)
                    .onDisappear {
                        localSettingsManager.lastSoftwareVersion.wrappedValue = getVerStr()
                    }
            }.onAppear {
                needShowWelcome = localSettingsManager.lastSoftwareVersion.wrappedValue != getVerStr()
            }
            
            VStack(spacing: 30){
                xAbout()
                Text("ζεΌδΎ§θΎΉζ ") + Text("ιδΈ­").bold() + Text("γ") + Text("εε»Ί").bold() + Text("γ") + Text("δΏ?ζΉ").bold() + Text("θͺε·±εζ¬’ηθ‘¨ζεε­!")
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

struct welcomePage: View {
    @Binding var showing: Bool
    
    var body: some View{
        let url = Bundle.main.url(forResource: "keyboardSettingPlay", withExtension: "mp4")!
        let av = AVPlayer(url: url)
        let ob = av.addBoundaryTimeObserver(forTimes: [NSValue(time: CMTime(seconds: 4, preferredTimescale: 1))], queue: .main) {
            print("over")
            av.seek(to: .zero)
            av.play()
        }
        return VStack{
            Text("ζ¬’θΏδ½Ώη¨π").font(.largeTitle).padding([.top], 40)
            Spacer()
            Form{
                Section{
                    Text("+ ζ¬ζ¬‘ζ΄ζ°ζ΄ζ°δΊδΈδΊζ΄ζ°ππ").font(.title3)
                }
                Section{
                    
                    HStack{
                        VideoPlayer(player: av).frame(width: 280, height: 300).onAppear {
                            av.play()
                        }.clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    }.frame(maxWidth: .infinity)
                    Text("ζ¬η¨εΊεε«θ΄΄ηΊΈι?ηζ©ε±οΌηΉε»δΈι’ηζι?ζεΌθ?Ύη½?οΌηΆεε―ε¨ι?ηιι‘Ήεε?ε¨θ?Ώι?ιι‘Ή")
                    Button(action:{
                        guard let url = URL(string: UIApplication.openSettingsURLString) else {
                            return
                        }
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }, label:{
                        Label("ζεΌxStickerηη³»η»θ?Ύη½?", systemImage: "gear")
                    })
                }
                Section{
                    Button {
                        showing = false
                        
                    } label: {
                        HStack{
                            Text("εΌε§δ½Ώη¨οΌ")
                                .font(.title2)
                        }.frame(maxWidth: .infinity)
                    }
                }
            }
            Spacer()
        }.onDisappear(){
            av.removeTimeObserver(ob)
        }
    }
}

// MARK: - π³οΈδΈδΈͺCollectionηε₯ε£ζι?ζ ·ε­
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
            Text("\(item == persistence.defaultCollection ? "ζεζ¬’" : (item.name ?? "Deleted"))")
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
                Alert(title: Text("ζ¨ηηθ¦ζ?εΏηε ι€ζγ\(item.name ?? "ε·²ε ι€")γδΊδΉ"),
                      primaryButton: .default(Text("ε―ΉοΌεΎεΆζ?οΌ"), action: {
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

// MARK: - πθ΄΄ηΊΈιεε?Ήθ§εΎ
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
    
    @State var isIn = false
    
    let collectionName: String!
    
    @State var currentProviderItem: NSItemProvider?
    
    init(persistence: PersistenceController, collection: Collections) {
        self.persistence = persistence
        self.collection = collection
        self.items = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Stickers.order, ascending: true)], predicate: NSPredicate(format: "collection=%@", self.collection))
        collectionName = collection == persistence.defaultCollection ? "ζεζ¬’" : (collection.name ?? "ε·²ε ι€")
    }
    
    // MARK: π·οΈδΈδΈͺθ‘¨ζ
    fileprivate func OneStickerShowView(_ item: Stickers) -> some View {
        return VStack(spacing: 10){
            VStack{
                Image(uiImage: stickerManager.get(sticker: item))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 66, height: 66, alignment: .center)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }.padding(2)
            .background(Color("AccentColor").opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color("AccentColor").opacity(0.2), radius: 6, x: 0, y: 5)
            Text("\(item.name ?? "ε·²ε ι€")")
                .font(.footnote)
                .lineLimit(1)
                .minimumScaleFactor(0.3)
        }.padding(10)
        .drawingGroup()
    }
    
    // MARK: - πεΎηιζ©ε¨
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
                                
                                let sticker = persistence.addSticker(with: "θ΄΄θ΄΄", in: collection)
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
    
    // MARK: - πΎε½ειεε³δΊι‘΅ι’
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
                                Label("ζεζ¬’", systemImage: "square.grid.2x2")
                            } else {
                                NavigationEditor(
                                    title: "θ΄΄θ΄΄ιεε­", systemImage: "square.grid.2x2",
                                    text: Binding(get: { collection.name ?? "" }, set: { v in collection.name = v }))
                            }
                            NavigationEditor(
                                title: "θ΄΄θ΄΄ιδ½θ", systemImage: "person.circle",
                                text: Binding(get: { collection.author ?? "" }, set: { v in collection.author = v }))
                            NavigationEditor(
                                title: "θ΄΄θ΄΄ιζθΏ°", systemImage: "doc.plaintext",
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
                                Label("ζΈη©Ίγζεζ¬’γ", systemImage: "trash.circle")
                                    .foregroundColor(.red)
                            })
                        } else if collection != persistence.defaultCollection {
                            Button(action: {
                                _ = stickerManager.delete(collection: collection)
                                persistence.removeCollection(of: collection)
                                isCollectionInfoViewPresented = false
                            }, label: {
                                Label("ε ζζε", systemImage: "trash.circle")
                                    .foregroundColor(.red)
                            })
                        }
                    }
                }
                .navigationBarTitle(self.collectionName)
                .navigationBarItems(trailing: Button(action: {
                    isCollectionInfoViewPresented = false
                }, label: {
                    Text("ε₯½")
                }))
            }
    }
    
    @State var showAlertTTT = false
    @State var importedCount: Int = 0
    //MARK: πδΈ»θ¦ε¨θΏζΎη€ΊοΌStickersοΌ
    var body: some View {
        ZStack {
            ScrollView(.vertical){
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 70), alignment: .top)], spacing: 10) {
                    Button(action: {
                        isImagePickerViewPresented = true
                    }, label: {
                        VStack(spacing: 10){
                            Image(systemName: "heart.circle")
                                .resizable()
                                .padding()
                                .frame(width: 60, height: 60, alignment: .center)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                                .shadow(color: Color("ShadowColor").opacity(0.3), radius: 6, x: 0, y: 5)
                        }.padding(15)
                    }).overlay(
                        HStack{
                            Image(systemName: "hand.tap.fill")
                                .foregroundColor(Color("AccentColor"))
                                .rotationEffect(Angle(degrees: -30)).imageScale(.large)
                            Text("ηΉζζ·»ε θͺε·±εζ¬’ηStickerε§οΌπ")
                                .minimumScaleFactor(0.3)
                                .multilineTextAlignment(.center)
                                .frame(width: 160, height: 40, alignment: .center)
                                .padding(10)
                                .background(Color("ItemBackgroundColor"))
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        }
                        .rotationEffect(Angle(degrees: 30), anchor: UnitPoint(x: 0, y: 0))
                        .offset(x: 132, y: 20)
                        .opacity(items.wrappedValue.count == 0 ? 1 : 0)
                    )
                    
                    ForEach(items.wrappedValue){ item in
                        NavigationLink(
                            destination: StickerDetailView(sticker: item, persistence: persistence),
                            label: {
                                OneStickerShowView(item)
                            }
                        ).contextMenu(ContextMenu{
                            Text("\(item.name ?? "")")
                            Divider()
                            Button {
                                item.order = 0
                                persistence.reorder(for: collection)
                            } label: {
                                Text("η§»ε°ει’ε»οΌ")
                            }
                            Divider()
                            Button {
                                deleteSticker(sticker: item)
                            } label: {
                                Text("ε ι€γ\(item.name ?? "")γ").foregroundColor(.red)
                            }
                        }).onDrag {
                            currentProviderItem = NSItemProvider(object: stickerManager.get(sticker: item))
                            currentProviderItem?.registerItem(forTypeIdentifier: "xsticker-item", loadHandler: { h, c, t in })
                            return currentProviderItem!
                        }
                    }.animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 1))
                }.padding()
                .animation(isAnimating ? .easeInOut(duration: 0.3) : .none)
            }
            .onDrop(of: [UTType.image], isTargeted: $isIn, perform: { providers in
//                print(currentProviderItem, providers.first?.registeredTypeIdentifiers, isIn)
                importedCount = importStickers(providers: providers)
                if importedCount > 0 {
                    showAlertTTT = true
                }
                return importedCount > 0
            })
            .alert(isPresented: $showAlertTTT, content: {
                Alert(title: Text("δΈε±ζθΏζ₯δΊ\(importedCount)δΈͺε¦"))
            })
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
    
    func deleteSticker(sticker: Stickers) {
        _ = stickerManager.delete(sticker: sticker)
        persistence.removeSticker(of: sticker)
    }
    
    func importStickers(providers: [NSItemProvider]) -> Int {
        var count = 0
        isAnimating = true
        for pro in providers {
            // ι²ζ­’θͺζε―Όε₯
            if pro.registeredTypeIdentifiers.contains("xsticker-item") {
                continue
            }
            pro.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { data, error in
                let img: UIImage?
                switch data {
                case let image as Data :
                    img = UIImage(data: image)
                case let url as URL:
                    print(url)
                    let imgData = (try? Data(contentsOf: url)) ?? nil
                    if imgData == nil {
                        img = nil
                    } else {
                        img = UIImage(data: imgData!)
                    }
                default:
                    img = nil
                }
                
                if img == nil { return }
                
                let sticker = persistence.addSticker(with: "θ΄΄θ΄΄", in: collection)
                let stauts = stickerManager.save(image: img!, named: sticker)
                if stauts {
                    sticker.hasSaved = true
                    persistence.save()
                    count += 1
                }
            }
        }
        isAnimating = false
        return count
    }
}


// MARK: - π¦ΈββοΈθ΄΄ηΊΈθ―¦η»εε?Ήθ§εΎ
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
                        title: "θ΄΄θ΄΄εε­", systemImage: "square.grid.2x2",
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
                    Label("θ?Ύη½?γ\(sticker.name ?? "ε·²ε ι€")γδΈΊε°ι’", systemImage: "heart.text.square")
                }
            }
            
            Section{
                Button(action: {
                    sticker.hasSaved = false
                    _ = stickerManager.delete(sticker: sticker)
                    persistence.removeSticker(of: sticker)
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Label("ε ζζε", systemImage: "trash.circle")
                        .foregroundColor(.red)
                })
            }
        }.navigationBarTitle(sticker.name ?? "ε·²ε ι€")
        .onDisappear {
            persistence.save()
        }
    }
}


// MARK: - πε―ΌθͺηΌθΎε¨οΌεΆε?ε°±ζ―ηΌθΎε¨ε―δ»₯ιθΏε―Όθͺε―Όθͺε°οΌ
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


// MARK: - π―ε³δΊ
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
