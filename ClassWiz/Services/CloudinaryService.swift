//
//  CloudinaryService.swift
//  ClassWiz
//

import Foundation
import Cloudinary

enum CloudinaryError: Error {
    case uploadFailed(String)
    case invalidConfig
}

class CloudinaryService {
    static let shared = CloudinaryService()
    
    private var cloudinary: CLDCloudinary?
    
    private init() {
        setup()
    }
    
    private func setup() {
        guard let path = Bundle.main.path(forResource: ".env", ofType: nil),
              let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            print("Could not load .env file")
            return
        }
        
        var configDict = [String: String]()
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let parts = line.split(separator: "=", maxSplits: 1).map(String.init)
            if parts.count == 2 {
                configDict[parts[0]] = parts[1]
            }
        }
        
        if let urlString = configDict["CLOUDINARY_URL"], let config = CLDConfiguration(cloudinaryUrl: urlString) {
            cloudinary = CLDCloudinary(configuration: config)
            return
        }
        
        guard let cloudName = configDict["CLOUDINARY_CLOUD_NAME"],
              let apiKey = configDict["CLOUDINARY_API_KEY"],
              let apiSecret = configDict["CLOUDINARY_API_SECRET"] else {
            return
        }
        
        let config = CLDConfiguration(cloudName: cloudName, apiKey: apiKey, apiSecret: apiSecret)
        cloudinary = CLDCloudinary(configuration: config)
    }
    
    func uploadImage(data: Data, completion: @escaping (Result<String, Error>) -> Void) {
        guard let cloudinary = cloudinary else {
            completion(.failure(CloudinaryError.invalidConfig))
            return
        }
        
        let params = CLDUploadRequestParams()
        
        cloudinary.createUploader().signedUpload(data: data, params: params, progress: nil) { result, error in
            if let error = error {
                completion(.failure(error))
            } else if let url = result?.secureUrl {
                completion(.success(url))
            } else {
                completion(.failure(CloudinaryError.uploadFailed("Unknown error")))
            }
        }
    }
    
    func uploadFile(url: URL, completion: @escaping (Result<String, Error>) -> Void) {
        guard let cloudinary = cloudinary else {
            completion(.failure(CloudinaryError.invalidConfig))
            return
        }
        
        let params = CLDUploadRequestParams()
        
        cloudinary.createUploader().signedUpload(url: url, params: params, progress: nil) { result, error in
            if let error = error {
                completion(.failure(error))
            } else if let secureUrl = result?.secureUrl {
                completion(.success(secureUrl))
            } else {
                completion(.failure(CloudinaryError.uploadFailed("Unknown error")))
            }
        }
    }
}
