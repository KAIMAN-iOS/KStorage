//
//  Storage.swift
//  CovidApp
//
//  Created by jerome on 31/03/2020.
//  Copyright © 2020 Jerome TONNELIER. All rights reserved.
//

import UIKit
import Photos

public typealias Handler<T> = (Result<T, Error>) -> Void
public typealias StorageKey = String
public protocol StorableKey {
    var key: StorageKey { get }
}

protocol ReadableStorage {
    func fetchValue(for key: String) throws -> Data
    func fetchValue(for key: String, handler: @escaping Handler<Data>)
}

protocol WritableStorage {
    func save(value: Data, for key: String) throws -> URL
    func save(value: Data, for key: String, handler: @escaping Handler<URL>)
    func deleteValue(for key: String) throws -> URL
    func deleteValue(for key: String, handler: @escaping Handler<URL>)
}

typealias Storage = ReadableStorage & WritableStorage
public enum StorageError: Error {
    case notFound
    case cantWrite(Error)
}

class DiskStorage {
    private let queue: DispatchQueue
    private let fileManager: FileManager
    private let path: URL
    
    init(
        path: URL,
        queue: DispatchQueue = .init(label: "DiskCache.Queue"),
        fileManager: FileManager = FileManager.default
    ) {
        self.path = path
        self.queue = queue
        self.fileManager = fileManager
    }
}

extension DiskStorage: WritableStorage {
    func deleteValue(for key: String) throws -> URL {
        let url = path.appendingPathComponent(key)
        do {
            try FileManager.default.removeItem(at: url)
            return url
        }
        catch {
           throw StorageError.cantWrite(error)
       }
    }
    
    func deleteValue(for key: String, handler: @escaping Handler<URL>) {
        queue.async {
            do {
                let url = try self.deleteValue(for: key)
                handler(.success(url))
            } catch {
                handler(.failure(error))
            }
        }
    }
    
    func save(value: Data, for key: String) throws -> URL {
        let url = path.appendingPathComponent(key)
        do {
            try self.createFolders(in: url)
            try value.write(to: url, options: .atomic)
            return url
        } catch {
            throw StorageError.cantWrite(error)
        }
    }
    
    func save(value: Data, for key: String, handler: @escaping Handler<URL>) {
        queue.async {
            do {
                let url = try self.save(value: value, for: key)
                handler(.success(url))
            } catch {
                handler(.failure(error))
            }
        }
    }
}

extension DiskStorage {
    private func createFolders(in url: URL) throws {
        let folderUrl = url.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: folderUrl.path) {
            try fileManager.createDirectory(
                at: folderUrl,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }
}

extension DiskStorage: ReadableStorage {
    func fetchValue(for key: String) throws -> Data {
        let url = path.appendingPathComponent(key)
        guard let data = fileManager.contents(atPath: url.path) else {
            throw StorageError.notFound
        }
        return data
    }
    
    func fetchValue(for key: String, handler: @escaping Handler<Data>) {
        queue.async {
            do {
                let res = try self.fetchValue(for: key)
                handler(.success(res))
                } catch (let error) {
                    handler(.failure(error))
                }
        }
    }
}
/* USE =
 struct Timeline: Codable {
 let tweets: [String]
 }
 
 let path = URL(fileURLWithPath: NSTemporaryDirectory())
 let disk = DiskStorage(path: path)
 let storage = CodableStorage(storage: disk)
 
 let timeline = Timeline(tweets: ["Hello", "World", "!!!"])
 try storage.save(timeline, for: "timeline")
 let cached: Timeline = try storage.fetch(for: "timeline")
 */
class CodableStorage {
    fileprivate let storage: DiskStorage
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    init(
        storage: DiskStorage,
        decoder: JSONDecoder = .init(),
        encoder: JSONEncoder = .init()
    ) {
        self.storage = storage
        self.decoder = decoder
        self.encoder = encoder
    }
    
    func fetch<T: Decodable>(for key: String) throws -> T {
        let data = try storage.fetchValue(for: key)
        return try decoder.decode(T.self, from: data)
    }
    
    @discardableResult
    func save<T: Encodable>(_ value: T, for key: String) throws -> URL {
        let data = try encoder.encode(value)
        return try storage.save(value: data, for: key)
    }
    
    func deleteValue(for key: StorageKey) throws {
        _ = try storage.deleteValue(for: key)
    }
}

public class DataStorage {
    public enum StorageError: Error {
        case cantRetrieveDataFromImage
    }
    private static let instance = DataStorage()
    private let storage = CodableStorage(storage: DiskStorage(path: URL(fileURLWithPath: DataStorage.storageDirectoryPath)))
    
    public init() {
    }
    
    /**
     Saves an image as Data on Disk an returns
     
     - returns:
     the url of the saved image Data if sucess
     
     - throws:
     error if the storage fails
     
     - parameters:
        - image : the image to save
        - completion : an optionnal completion block to handle various type of image compression (HEIC for instance)
        - path : the path to add to the default Storage Directory when savinf the image
        - saveToCamera : a boolean indicating wether to save the image on the uer's camera roll
     */
    public func save(_ image: UIImage, completion: ((UIImage) -> Data)? = nil, path: String, saveToCamera: Bool = false) throws -> URL {
        guard let data = completion?(image) ?? image.jpegData(compressionQuality: 0.8) else {
            throw StorageError.cantRetrieveDataFromImage
        }
        
        let url = try storage.storage.save(value: data, for: path)
        if saveToCamera {
            saveToCameraRoll(image: image)
        }
        return url
    }
    
    private func saveToCameraRoll(image: UIImage) {
        guard PHPhotoLibrary.authorizationStatus() == .authorized else {
            PHPhotoLibrary.requestAuthorization({ status in
                switch status {
                case .authorized: UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                default: ()
                }
            })
            return
        }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
    
    public func fetchImage(at url: URL, commponent: String? = nil) throws -> UIImage? {
        let data = try storage.storage.fetchValue(for: commponent ?? url.lastPathComponent)
        return UIImage(data: data)
    }
    
    public func fetch<T: Decodable>(for key: StorageKey) throws -> T {
        return try storage.fetch(for: key)
    }
    
    public func save<T: Encodable>(_ value: T, for key: StorageKey) throws {
        try storage.save(value, for: key)
    }
    
    public func deleteValue(for key: StorageKey) throws {
        try storage.deleteValue(for: key)
    }
    
    // Change this value if you want to change the default storage folder
    public static var storageFolder = "Storage"
    public static var storageDirectoryPath: String = FileManager.default.urls(for: .documentDirectory,
                                                                              in: .userDomainMask).first!.appendingPathComponent(DataStorage.storageFolder).path
    // creates the storage directory if not exists
    public func handleStorageDirectory(with path: String = DataStorage.storageDirectoryPath) {
        if FileManager.default.fileExists(atPath: path) == false {
            do {
                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error)
            }
        }
    }
}

public extension URL {
    static var documentDirectoryPath: String {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    }
}
