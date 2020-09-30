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
        case "CurrentUser": self = .currentUser
        default: self = .singleModel(rawValue)
        }
    }
    
    var rawValue: String {
        switch self {
        case .currentUser: return "CurrentUser"
        case .singleModel(let id): return id
        }
    }
    typealias RawValue = String
    
    case currentUser
    case singleModel(_: String)
    
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
    
    static func save(_ image: UIImage, isTemporary: Bool = false) throws -> URL {
        if isTemporary {
            return try save(image, path: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).path)
        } else {
            return try save(image, path: "\(UUID().uuidString)")
        }
    }
    
    private static func save(_ image: UIImage, path: String) throws -> URL {
        try DataManager.instance.storage.save(image, path: path)
    }
    
    static func fetchImage(at url: URL) throws -> UIImage? {
        try DataManager.instance.storage.fetchImage(at: url)
    }
}
