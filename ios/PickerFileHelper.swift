import AVFoundation
import Foundation
import UniformTypeIdentifiers
import UIKit

struct ImageProcessingOptions {
  let stripExif: Bool
  let compress: Bool
  let quality: Double
  let maxLongEdge: Int?
  let convertHeicToJpeg: Bool

  func requiresProcessing(for type: UTType?) -> ImageProcessingIntent {
    guard let type, type.conforms(to: .image) else {
      return .noChange
    }

    let shouldResize = (maxLongEdge ?? 0) > 0
    let shouldCompress = compress
    let shouldConvertHeic =
      convertHeicToJpeg && (type.conforms(to: .heic) || type.conforms(to: .heif))

    if stripExif || shouldResize || shouldCompress || shouldConvertHeic {
      return ImageProcessingIntent(
        shouldReencode: true,
        stripExif: stripExif || shouldConvertHeic
      )
    }

    return .noChange
  }
}

struct ImageProcessingIntent {
  let shouldReencode: Bool
  let stripExif: Bool

  static let noChange = ImageProcessingIntent(shouldReencode: false, stripExif: false)
}

struct ImageProcessingResult {
  let url: URL
  let mimeType: String?
  let exifStripped: Bool
}

enum PickerFileHelperError: Error {
  case imageDecodingFailed
  case imageEncodingFailed
}

final class PickerFileHelper {
  private let fileManager = FileManager.default
  private let cacheDirectory: URL
  private let tempDirectory: URL

  init() {
    let cachesURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    cacheDirectory = cachesURL.appendingPathComponent("rn-zero-permission-picker", isDirectory: true)
    tempDirectory =
      fileManager.temporaryDirectory.appendingPathComponent(
        "rn-zero-permission-picker",
        isDirectory: true
      )

    try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    try? fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
  }

  func persistFile(
    at sourceURL: URL,
    preferredName: String?,
    copyToCache: Bool
  ) throws -> URL {
    let destinationDirectory = copyToCache ? cacheDirectory : tempDirectory
    if sourceURL.path.hasPrefix(destinationDirectory.path) {
      return sourceURL
    }

    let sanitizedName = sanitizedFileName(from: preferredName, fallbackURL: sourceURL)
    let destinationURL = uniqueURL(
      for: sanitizedName,
      in: destinationDirectory,
      defaultExtension: sourceURL.pathExtension
    )

    if fileManager.fileExists(atPath: destinationURL.path) {
      try fileManager.removeItem(at: destinationURL)
    }

    try fileManager.copyItem(at: sourceURL, to: destinationURL)
    return destinationURL
  }

  func writeData(
    _ data: Data,
    preferredName: String?,
    copyToCache: Bool,
    defaultExtension: String
  ) throws -> URL {
    let destinationDirectory = copyToCache ? cacheDirectory : tempDirectory
    let sanitizedName = sanitizedFileName(from: preferredName, fallbackExtension: defaultExtension)
    let destinationURL = uniqueURL(for: sanitizedName, in: destinationDirectory, defaultExtension: defaultExtension)
    try data.write(to: destinationURL, options: .atomic)
    return destinationURL
  }

  func processImageIfNeeded(
    at url: URL,
    options: ImageProcessingOptions
  ) throws -> ImageProcessingResult {
    let type = contentType(for: url)
    let intent = options.requiresProcessing(for: type)
    guard intent.shouldReencode else {
      return ImageProcessingResult(url: url, mimeType: type?.preferredMIMEType, exifStripped: false)
    }

    guard let image = UIImage(contentsOfFile: url.path) else {
      throw PickerFileHelperError.imageDecodingFailed
    }

    let resizedImage: UIImage
    if let maxEdge = options.maxLongEdge, maxEdge > 0 {
      resizedImage = image.scaledTo(longEdge: CGFloat(maxEdge))
    } else {
      resizedImage = image
    }

    let clampedQuality = max(0.0, min(1.0, options.quality))
    let quality = options.compress ? clampedQuality : 0.95

    guard let data = resizedImage.jpegData(compressionQuality: CGFloat(quality)) else {
      throw PickerFileHelperError.imageEncodingFailed
    }

    let destinationURL = uniqueURL(
      for: "image_\(Int(Date().timeIntervalSince1970))_\(UUID().uuidString.prefix(8)).jpg",
      in: cacheDirectory,
      defaultExtension: "jpg"
    )
    try data.write(to: destinationURL, options: .atomic)

    if url != destinationURL, fileManager.fileExists(atPath: url.path) {
      try? fileManager.removeItem(at: url)
    }

    return ImageProcessingResult(
      url: destinationURL,
      mimeType: "image/jpeg",
      exifStripped: intent.stripExif
    )
  }

  func metadata(
    for url: URL,
    displayName: String?,
    includeFileSize: Bool,
    includeDimensions: Bool,
    includeDuration: Bool
  ) -> [String: Any] {
    var item: [String: Any] = [
      "id": UUID().uuidString,
      "uri": url.path,
      "displayName": displayName ?? url.lastPathComponent
    ]

    let resourceValues = try? url.resourceValues(forKeys: [.contentTypeKey, .fileSizeKey])
    let type = resourceValues?.contentType ?? UTType(filenameExtension: url.pathExtension)

    if let mimeType = type?.preferredMIMEType {
      item["mimeType"] = mimeType
    }

    if includeFileSize, let size = resourceValues?.fileSize {
      item["size"] = size
    }

    if includeDimensions, type?.conforms(to: .image) == true {
      if let image = UIImage(contentsOfFile: url.path) {
        item["width"] = Int(image.size.width)
        item["height"] = Int(image.size.height)
      }
    }

    if includeDuration, type?.conforms(to: .movie) == true {
      let asset = AVAsset(url: url)
      let duration = CMTimeGetSeconds(asset.duration)
      if duration.isFinite, duration > 0 {
        item["durationMs"] = Int(duration * 1000)
      }
    }

    return item
  }

  func contentType(for url: URL) -> UTType? {
    if let resourceValues = try? url.resourceValues(forKeys: [.contentTypeKey]),
      let type = resourceValues.contentType
    {
      return type
    }
    if !url.pathExtension.isEmpty {
      return UTType(filenameExtension: url.pathExtension)
    }
    return nil
  }

  func clearCache() throws {
    if fileManager.fileExists(atPath: cacheDirectory.path) {
      try fileManager.removeItem(at: cacheDirectory)
    }
    try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

    if fileManager.fileExists(atPath: tempDirectory.path) {
      try fileManager.removeItem(at: tempDirectory)
    }
    try fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
  }

  // MARK: - Helpers

  private func sanitizedFileName(from preferredName: String?, fallbackURL: URL) -> String {
    if let preferredName,
      let sanitized = sanitize(preferredName),
      !sanitized.isEmpty
    {
      return sanitized
    }

    if let sanitized = sanitize(fallbackURL.lastPathComponent), !sanitized.isEmpty {
      return sanitized
    }

    return "file"
  }

  private func sanitizedFileName(from preferredName: String?, fallbackExtension: String) -> String {
    if let preferredName,
      let sanitized = sanitize(preferredName),
      !sanitized.isEmpty
    {
      return sanitized
    }
    let ext = fallbackExtension.isEmpty ? "dat" : fallbackExtension
    return "file.\(ext)"
  }

  private func sanitize(_ string: String) -> String? {
    var sanitized = string.trimmingCharacters(in: .whitespacesAndNewlines)
    sanitized = sanitized.replacingOccurrences(of: "[/:*?\"<>|]", with: "_", options: .regularExpression)
    sanitized = sanitized.replacingOccurrences(of: "..", with: "_")
    return sanitized
  }

  private func uniqueURL(
    for filename: String,
    in directory: URL,
    defaultExtension: String
  ) -> URL {
    var base = (filename as NSString).deletingPathExtension
    var ext = (filename as NSString).pathExtension

    if ext.isEmpty {
      ext = defaultExtension
    }
    if ext.isEmpty {
      ext = "dat"
    }

    var candidate = directory.appendingPathComponent("\(base).\(ext)")
    var counter = 0
    while fileManager.fileExists(atPath: candidate.path) {
      counter += 1
      candidate = directory.appendingPathComponent("\(base)_\(counter).\(ext)")
    }
    return candidate
  }
}

extension UIImage {
  fileprivate func scaledTo(longEdge: CGFloat) -> UIImage {
    guard longEdge > 0 else { return self }

    let maxSide = max(size.width, size.height)
    guard maxSide > longEdge else { return self }

    let scale = longEdge / maxSide
    let newSize = CGSize(width: size.width * scale, height: size.height * scale)

    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
    defer { UIGraphicsEndImageContext() }
    draw(in: CGRect(origin: .zero, size: newSize))
    return UIGraphicsGetImageFromCurrentImageContext() ?? self
  }
}
