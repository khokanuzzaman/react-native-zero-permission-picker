import Foundation
import AVFoundation
import UIKit

class PickerFileHelper {
  private let cacheDir: URL
  
  init() {
    let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
    cacheDir = paths[0].appendingPathComponent("rn-zero-permission-picker", isDirectory: true)
    
    try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
  }
  
  func saveImageData(_ data: Data) -> String? {
    let filename = "image_\(Date().timeIntervalSince1970)_\(UUID().uuidString.prefix(8)).jpg"
    let fileURL = cacheDir.appendingPathComponent(filename)
    
    do {
      try data.write(to: fileURL)
      return fileURL.path
    } catch {
      return nil
    }
  }
  
  func getPickedItemMap(url: URL) -> [String: Any] {
    var item: [String: Any] = [
      "id": UUID().uuidString,
      "uri": url.path,
      "displayName": url.lastPathComponent
    ]
    
    // Get MIME type
    let mimeType = getMimeType(for: url)
    if !mimeType.isEmpty {
      item["mimeType"] = mimeType
    }
    
    // Get file size
    if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) {
      if let fileSize = attributes[.size] as? Int {
        item["size"] = fileSize
      }
    }
    
    // Get dimensions for images
    if mimeType.hasPrefix("image/") {
      if let image = UIImage(contentsOfFile: url.path) {
        item["width"] = Int(image.size.width)
        item["height"] = Int(image.size.height)
      }
    }
    
    // Get duration for videos
    if mimeType.hasPrefix("video/") {
      let asset = AVAsset(url: url)
      let duration = CMTimeGetSeconds(asset.duration)
      if !duration.isNaN && !duration.isInfinite {
        item["durationMs"] = Int(duration * 1000)
      }
    }
    
    return item
  }
  
  func clearCache() throws {
    try FileManager.default.removeItem(at: cacheDir)
    try FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
  }
  
  private func getMimeType(for url: URL) -> String {
    let pathExtension = url.pathExtension.lowercased()
    
    let mimeTypes: [String: String] = [
      "jpg": "image/jpeg",
      "jpeg": "image/jpeg",
      "png": "image/png",
      "gif": "image/gif",
      "webp": "image/webp",
      "mp4": "video/mp4",
      "mov": "video/quicktime",
      "avi": "video/x-msvideo",
      "pdf": "application/pdf",
      "doc": "application/msword",
      "docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
      "txt": "text/plain",
      "zip": "application/zip",
    ]
    
    return mimeTypes[pathExtension] ?? "application/octet-stream"
  }
}
