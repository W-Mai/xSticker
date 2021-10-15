//
//  StickerManager.swift
//  xSticker
//
//  Created by W-Mai on 2021/10/15.
//

import Foundation
import UIKit

class StickerManager {
    static let defaultImagePath = Bundle.main.url(forResource: "ld", withExtension: "jpg")!
    static let defaultImage = UIImage(data: try! Data(contentsOf: defaultImagePath))!
    static let stickerMaxSize: CGFloat = 618
    
    var rootPath: URL
    var fsmngr: FileManager
    var resourcePath = "StickerCollections"
    
    init(root: URL) {
        rootPath = root.appendingPathComponent(resourcePath, isDirectory: true)
        fsmngr = FileManager()
        
        let rootPathExt = fsmngr.fileExists(atPath: rootPath.path)
        if !rootPathExt {
            NSLog("Root Path Not Exist, Creating")
            do{
                try fsmngr.createDirectory(at: rootPath, withIntermediateDirectories: false)
            } catch {
                NSLog("Create Path Failed")
            }
        }
    }
    
    func save(image : UIImage, named sticker: Stickers) -> Bool {
        let savePath = get(path: sticker)!
        print(savePath)
        let size = image.size
        print(size)
        
        let saveRes: Bool
        if size.width > StickerManager.stickerMaxSize || size.height > StickerManager.stickerMaxSize {
            // 计算尺寸
            let maxLength = max(size.width, size.height)
            let newSize: CGSize
            let ratio: CGFloat
            if size.width == maxLength {
                ratio = StickerManager.stickerMaxSize / size.width
                newSize = CGSize(width: StickerManager.stickerMaxSize, height: size.height * ratio)
            } else {
                ratio = StickerManager.stickerMaxSize / size.height
                newSize = CGSize(width: size.width * ratio, height: StickerManager.stickerMaxSize)
            }
            // 获取处理后的图像
            UIGraphicsBeginImageContext(newSize)
            image.draw(in: CGRect(origin: CGPoint(x: 0, y: 0), size: newSize))
            let newImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            
            saveRes = fsmngr.createFile(atPath: savePath.path, contents: newImage.pngData())
        } else {
            saveRes = fsmngr.createFile(atPath: savePath.path, contents: image.pngData())
        }
        
        print(saveRes)
        return saveRes
    }
    
    func delete(sticker: Stickers) -> Bool {
        let path = get(path: sticker)!
        do {
            try fsmngr.removeItem(at: path)
        } catch {
            NSLog("Delete Sticker %@ Failed, because: %@", sticker.name!, error.localizedDescription)
            return false
        }
        return true
    }
    
    func get(sticker: Stickers) -> UIImage{
        let readPath = get(path: sticker)
        if readPath == nil {
            return StickerManager.defaultImage
        }
        
        let imgData = try? Data(contentsOf: readPath!)
        
        guard imgData != nil else {
            return StickerManager.defaultImage
        }
        return UIImage(data: imgData!)!
    }
    
    func get(path sticker: Stickers) -> URL? {
        let collection = sticker.collection
        if collection == nil {
            return nil
        }
        var savePath = rootPath.appendingPathComponent(collection!.id!.uuidString, isDirectory: true)
        savePath.appendPathComponent(sticker.image!.uuidString, isDirectory: false)
        savePath.appendPathExtension("png")
        return savePath
    }
    
    func createCollectionDir(for collection: Collections) -> Bool {
        let collectionPath = rootPath.appendingPathComponent(collection.id!.uuidString, isDirectory: true)
        let collectionExt = fsmngr.fileExists(atPath: collectionPath.path)
        if !collectionExt {
            NSLog("Collection %@ Path Not Exist, Creating", collection.id!.uuidString)
            do{
                try fsmngr.createDirectory(at: collectionPath, withIntermediateDirectories: false)
            } catch {
                NSLog("Create %@ Path Failed. At Path: %@. Because: %@", collection.id!.uuidString, collectionPath.path, error.localizedDescription)
                return false
            }
        }
        return true
    }
}

let GroupRootPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.xSticker")!
let stickerManager = StickerManager(root: GroupRootPath)
