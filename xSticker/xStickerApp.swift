//
//  xStickerApp.swift
//  xSticker
//
//  Created by W-Mai on 2021/10/14.
//

import SwiftUI
import Foundation
import Photos

@main
struct xStickerApp: App {
    let persistenceController = PersistenceController.shared
    @ObservedObject var editMode = EnvSettings()
    
    init() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            print(status)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(persistenceController: persistenceController)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(editMode)
        }
    }
}
