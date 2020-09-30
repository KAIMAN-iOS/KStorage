//
//  DataManager.swift
//  CovidApp
//
//  Created by jerome on 02/04/2020.
//  Copyright © 2020 Jerome TONNELIER. All rights reserved.
//

import UIKit
import KStorage

enum DataManagerKey: RawRepresentable, StorableKey {
    init?(rawValue: String) {
        switch rawValue {
        case "luhsivchqdubipqubimb": self = .image
        default: return nil
        }
    }
    
    var rawValue: String {
        switch self {
        case .image: return "luhsivchqdubipqubimb"
        }
    }
    typealias RawValue = String
    
    case image
    
    var key: StorageKey {
        return StorageKey(rawValue)
    }
}

class DataManager {
    static let instance: DataManager = DataManager()
    private var storage = DataStorage()
    let saveQueue = DispatchQueue.init(label: "ModelBackgroundSave", qos: .background)
    
    private init() {
        DataStorage().handleStorageDirectory()
    }
    
    func retrieve<T: Decodable>(for key: StorageKey) throws -> T {
        do {
            return try DataManager.instance.storage.fetch(for: key)
        }
        catch {
            throw StorageError.notFound
        }
    }
    
    static func save(_ image: UIImage, isTemporary: Bool = false, saveToCamera: Bool = false) throws -> URL {
        if isTemporary {
            return try save(image, path: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).path, saveToCamera: saveToCamera)
        } else {
            return try save(image, path: "\(DataManagerKey.image.rawValue)", saveToCamera: saveToCamera)
        }
    }
    
    private static func save(_ image: UIImage, path: String, saveToCamera: Bool = false) throws -> URL {
        try DataManager.instance.storage.save(image, path: path, saveToCamera: saveToCamera)
    }
    
    static func fetchImage(for key: StorageKey) throws -> UIImage? {
        try DataManager.instance.storage.fetchImage(at: URL(fileURLWithPath: DataStorage.storageDirectoryPath + "/\(key)"))
    }
}
