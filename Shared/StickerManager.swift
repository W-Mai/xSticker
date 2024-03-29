//
//  StickerManager.swift
//  xSticker
//
//  Created by W-Mai on 2021/10/15.
//

import Foundation
import UIKit

class StickerManager {
    static let defaultImagePath = Bundle.main.url(forResource: "tempLogo", withExtension: "png")!
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
    
    func save(image : UIImage, named sticker: Stickers, downscaleRate: Double = 1) -> Bool {
        let savePath = get(path: sticker)!
        print(savePath)
        let size = image.size
        print(size)
        var toSavedImage: UIImage
        let localScale = StickerManager.stickerMaxSize * CGFloat(downscaleRate)
        
        var saveRes: Bool
        if size.width > localScale || size.height > localScale {
            // 计算尺寸
            let maxLength = max(size.width, size.height)
            let newSize: CGSize
            let ratio: CGFloat
            if size.width == maxLength {
                ratio = localScale / size.width
                newSize = CGSize(width: localScale, height: size.height * ratio)
            } else {
                ratio = localScale / size.height
                newSize = CGSize(width: size.width * ratio, height: localScale)
            }
            // 获取处理后的图像
            UIGraphicsBeginImageContext(newSize)
            image.draw(in: CGRect(origin: CGPoint(x: 0, y: 0), size: newSize))
            let newImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            
            toSavedImage = newImage
        } else {
            toSavedImage = image
        }
        
        saveRes = fsmngr.createFile(atPath: savePath.path, contents: toSavedImage.pngData())
        
        if saveRes {
            let fileSize: Int64 = get(size: sticker)
            if fileSize > 500 * 1024 {
                NSLog("Too Large, need to downscale.")
                saveRes = save(image: toSavedImage, named: sticker, downscaleRate: 0.8 )
            }
        }
       
        print(saveRes)
        return saveRes
    }
    
    func delete(sticker: Stickers) -> Bool {
        let path = get(path: sticker)!
        do {
            try fsmngr.removeItem(at: path)
        } catch {
            NSLog("Delete Sticker %@ Failed, because: %@", sticker.image!.uuidString, error.localizedDescription)
            return false
        }
        return true
    }
    
    func delete(collection: Collections) -> Bool {
        let path = get(path: collection)
        do {
            try fsmngr.removeItem(at: path)
        } catch {
            NSLog("Delete Collection %@ Failed, because: %@", collection.id!.uuidString, error.localizedDescription)
            return false
        }
        return true
    }
    
    func get(sticker: Stickers, targetSize: CGFloat? = nil) -> UIImage{
        guard let readPath = get(path: sticker)
        else {
            return StickerManager.defaultImage
        }
        
        if targetSize != nil {
            let img = downsample(imageAt: readPath, targetMaxSize: targetSize!)
            return img
        } else {
            guard let imgData = try? Data(contentsOf: readPath)
            else { return StickerManager.defaultImage }
            guard let img = UIImage(data: imgData)
            else { return StickerManager.defaultImage }
            return img
        }
    }
    
    func get(profile collection: Collections, targetSize: CGFloat = 300) -> UIImage {
        guard collection.profile != nil else { return StickerManager.defaultImage }
        
        guard let sticker = collection.stickerSet?.first(where: { item in
            (item as! Stickers).image == collection.profile
        }) as? Stickers
        else { return StickerManager.defaultImage }
        
        return get(sticker: sticker, targetSize: targetSize)
    }
    
    func get(path sticker: Stickers) -> URL? {
        let collection = sticker.collection
        if collection == nil {
            return nil
        }
        guard let collectionId = collection!.id
        else { return nil }
        
        var savePath = rootPath.appendingPathComponent(collectionId.uuidString, isDirectory: true)
        savePath.appendPathComponent(sticker.image!.uuidString, isDirectory: false)
        savePath.appendPathExtension("png")
        return savePath
    }
    
    func get(path collection: Collections) -> URL {
        return rootPath.appendingPathComponent(collection.id!.uuidString, isDirectory: true)
    }
    
    func get(sizeStr sticker: Stickers) -> String {
        return String(format: "%.2f KB", Float(get(size: sticker)) / 1024)
    }
    
    func get(size sticker: Stickers) -> Int64 {
        guard let path = get(path: sticker) else { return 0 }
        guard let attr = try? fsmngr.attributesOfItem(atPath: path.path) else { return 0 }
        let size = (attr[FileAttributeKey.size] as? Int64) ?? 0
        
        return size
    }
    
    func createCollectionDir(for collection: Collections) -> Bool {
        let collectionPath = get(path: collection)
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

let GroupRootPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.studio.xclz.xSticker")!
let stickerManager = StickerManager(root: GroupRootPath)

func downsample(imageAt imageURL: URL, targetMaxSize: CGFloat) -> UIImage {

    //生成CGImageSourceRef 时，不需要先解码。
    let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
    let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, imageSourceOptions)!
    let maxDimensionInPixels = targetMaxSize
    
    //kCGImageSourceShouldCacheImmediately
    //在创建Thumbnail时直接解码，这样就把解码的时机控制在这个downsample的函数内
    let downsampleOptions = [kCGImageSourceCreateThumbnailFromImageAlways: true,
                                 kCGImageSourceShouldCacheImmediately: true,
                                 kCGImageSourceCreateThumbnailWithTransform: true,
                                      kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels] as [CFString : Any] as CFDictionary
    //生成
    let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions)!
    return UIImage(cgImage: downsampledImage)
}
