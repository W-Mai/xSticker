//
//  ContentView.swift
//  xSticker
//
//  Created by W-Mai on 2021/10/14.
//

import SwiftUI
import CoreData

struct ContentView: View {
    var persistence: PersistenceController
    
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Stickers.name, ascending: true)])
    private var items: FetchedResults<Stickers>

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
                            destination: Text("Destination"),
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
                    //                    ForEach(items) { item in
                    //                        NavigationLink(
                    //                            destination: Text("Destination"),
                    //                            label: {
                    //                                VStack{
                    //                                    Image(systemName: "plus")
                    //                                    Text("\(item.name!)")
                    //                                }.frame(width: 100, height: 100, alignment: .center)
                    //                            })
                    //                    }
                    //                    .onDelete(perform: deleteItems)
                }.padding()
            }.navigationTitle("Collection")
            .navigationViewStyle(DoubleColumnNavigationViewStyle())
            //            .navigationBarItems(trailing: HStack {
            //                Button(action: addItem) {
            //                    Label("Add Item", systemImage: "plus")
//                }
//                EditButton()
//            })
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
            offsets.map { items[$0] }.forEach(viewContext.delete)

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
