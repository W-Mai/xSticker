//
//  xStickerApp.swift
//  xSticker
//
//  Created by W-Mai on 2021/10/14.
//

import SwiftUI

@main
struct xStickerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView(persistenceController: persistenceController)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
