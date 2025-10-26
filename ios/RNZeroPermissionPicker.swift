import Foundation
import PhotosUI
import UIKit
import AVFoundation
import ImageIO

@objc(RNZeroPermissionPickerModule)
class RNZeroPermissionPickerModule: NSObject, RCTBridgeModule {
  static func moduleName() -> String! {
    return "RNZeroPermissionPicker"
  }

  static func requiresMainQueueSetup() -> Bool {
    return true
  }

  weak var delegate: RCTBridgeModule?
  private var fileHelper: PickerFileHelper?

  override init() {
    super.init()
    fileHelper = PickerFileHelper()
  }

  @objc
  func pickMedia(
    _ options: NSDictionary,
    resolver: @escaping RCTPromiseResolveBlock,
    rejecter: @escaping RCTPromiseRejectBlock
  ) {
    DispatchQueue.main.async {
      guard let rootViewController = RCTSharedApplication()?.delegate?.window??.rootViewController else {
        rejecter("IO_ERROR", "No root view controller", nil)
        return
      }

      let kind = options["kind"] as? String ?? "mixed"
      let multiple = options["multiple"] as? Bool ?? false
      let copyToCache = options["copyToCache"] as? Bool ?? true
      let stripEXIF = options["stripEXIF"] as? Bool ?? false
      let compress = options["compress"] as? Bool ?? false
      let quality = options["quality"] as? Double ?? 0.9
      let maxLongEdge = options["maxLongEdge"] as? NSNumber
      let convertHeicToJpeg = options["convertHeicToJpeg"] as? Bool ?? true

      if #available(iOS 16, *) {
        var config = PHPickerConfiguration()
        
        // Configure filter
        var filters: [PHPickerFilter] = []
        if kind == "image" {
          filters.append(.images)
        } else if kind == "video" {
          filters.append(.videos)
        } else if kind == "mixed" {
          filters.append(.images)
          filters.append(.videos)
        }
        
        if !filters.isEmpty {
          config.filter = PHPickerFilter.any(of: filters)
        }
        
        config.selectionLimit = multiple ? 0 : 1
        config.preferredAssetRepresentationMode = .current

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = PickerDelegate(
          resolver: resolver,
          rejecter: rejecter,
          fileHelper: fileHelper,
          stripEXIF: stripEXIF,
          compress: compress,
          quality: quality,
          maxLongEdge: maxLongEdge?.intValue,
          convertHeicToJpeg: convertHeicToJpeg,
          copyToCache: copyToCache
        )
        rootViewController.present(picker, animated: true)
      } else {
        // iOS 15 - Use UIImagePickerController
        self.pickMediaLegacy(
          kind: kind,
          multiple: multiple,
          copyToCache: copyToCache,
          resolver: resolver,
          rejecter: rejecter,
          rootViewController: rootViewController
        )
      }
    }
  }

  @objc
  func pickFiles(
    _ options: NSDictionary,
    resolver: @escaping RCTPromiseResolveBlock,
    rejecter: @escaping RCTPromiseRejectBlock
  ) {
    DispatchQueue.main.async {
      guard let rootViewController = RCTSharedApplication()?.delegate?.window??.rootViewController else {
        rejecter("IO_ERROR", "No root view controller", nil)
        return
      }

      let kind = options["kind"] as? String ?? "any"
      let multiple = options["multiple"] as? Bool ?? false
      let copyToCache = options["copyToCache"] as? Bool ?? true

      let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: self.getContentTypes(for: kind))
      documentPicker.allowsMultipleSelection = multiple
      documentPicker.delegate = DocumentPickerDelegate(
        resolver: resolver,
        rejecter: rejecter,
        fileHelper: fileHelper,
        copyToCache: copyToCache
      )
      
      rootViewController.present(documentPicker, animated: true)
    }
  }

  @objc
  func isSystemPhotoPickerAvailable(
    _ resolve: RCTPromiseResolveBlock,
    rejecter: @escaping RCTPromiseRejectBlock
  ) {
    // iOS always has photo picker support
    resolve(true)
  }

  @objc
  func clearCachedFiles(
    _ resolve: RCTPromiseResolveBlock,
    rejecter: @escaping RCTPromiseRejectBlock
  ) {
    do {
      try fileHelper?.clearCache()
      resolve(nil)
    } catch {
      rejecter("IO_ERROR", "Failed to clear cache", error)
    }
  }

  private func pickMediaLegacy(
    kind: String,
    multiple: Bool,
    copyToCache: Bool,
    resolver: @escaping RCTPromiseResolveBlock,
    rejecter: @escaping RCTPromiseRejectBlock,
    rootViewController: UIViewController
  ) {
    let imagePicker = UIImagePickerController()
    imagePicker.delegate = ImagePickerDelegate(
      resolver: resolver,
      rejecter: rejecter,
      fileHelper: fileHelper,
      copyToCache: copyToCache
    )
    
    if kind == "image" {
      imagePicker.sourceType = .photoLibrary
      imagePicker.mediaTypes = ["public.image"]
    } else if kind == "video" {
      imagePicker.sourceType = .photoLibrary
      imagePicker.mediaTypes = ["public.movie"]
    } else {
      imagePicker.sourceType = .photoLibrary
      imagePicker.mediaTypes = ["public.image", "public.movie"]
    }
    
    rootViewController.present(imagePicker, animated: true)
  }

  private func getContentTypes(for kind: String) -> [UTType] {
    switch kind {
    case "image":
      return [.image]
    case "video":
      return [.movie]
    case "pdf":
      return [.pdf]
    case "audio":
      return [.audio]
    case "text":
      return [.text, .plainText]
    case "zip":
      return [.zip]
    default:
      return [.item]
    }
  }
}

// MARK: - PHPickerDelegate

class PickerDelegate: NSObject, PHPickerViewControllerDelegate {
  let resolver: RCTPromiseResolveBlock
  let rejecter: RCTPromiseRejectBlock
  let fileHelper: PickerFileHelper?
  let stripEXIF: Bool
  let compress: Bool
  let quality: Double
  let maxLongEdge: Int?
  let convertHeicToJpeg: Bool
  let copyToCache: Bool

  init(
    resolver: @escaping RCTPromiseResolveBlock,
    rejecter: @escaping RCTPromiseRejectBlock,
    fileHelper: PickerFileHelper?,
    stripEXIF: Bool,
    compress: Bool,
    quality: Double,
    maxLongEdge: Int?,
    convertHeicToJpeg: Bool,
    copyToCache: Bool
  ) {
    self.resolver = resolver
    self.rejecter = rejecter
    self.fileHelper = fileHelper
    self.stripEXIF = stripEXIF
    self.compress = compress
    self.quality = quality
    self.maxLongEdge = maxLongEdge
    self.convertHeicToJpeg = convertHeicToJpeg
    self.copyToCache = copyToCache
  }

  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    picker.dismiss(animated: true)
    
    if results.isEmpty {
      resolver([])
      return
    }

    var pickedItems: [[String: Any]] = []
    let dispatchGroup = DispatchGroup()

    for result in results {
      dispatchGroup.enter()
      
      let itemProvider = result.itemProvider
      if itemProvider.canLoadObject(ofClass: UIImage.self) {
        itemProvider.loadObject(ofClass: UIImage.self) { image, error in
          defer { dispatchGroup.leave() }
          
          guard let image = image as? UIImage else {
            return
          }

          var processedImage = image
          var item: [String: Any] = [
            "id": UUID().uuidString,
            "mimeType": "image/jpeg"
          ]

          // Convert HEIC to JPEG if needed
          if self.convertHeicToJpeg {
            // Already done by UIImage
          }

          // Strip EXIF if requested
          if self.stripEXIF {
            processedImage = self.stripEXIFFromImage(image)
          }

          // Compress if requested
          if self.compress {
            let jpegData = processedImage.jpegData(compressionQuality: CGFloat(self.quality))
            if let data = jpegData {
              item["size"] = data.count
              if let uri = self.fileHelper?.saveImageData(data) {
                item["uri"] = uri
              }
            }
          } else {
            item["width"] = Int(processedImage.size.width)
            item["height"] = Int(processedImage.size.height)
          }

          pickedItems.append(item)
        }
      } else if itemProvider.canLoadObject(ofClass: AVAsset.self) {
        itemProvider.loadObject(ofClass: AVAsset.self) { asset, error in
          defer { dispatchGroup.leave() }
          
          guard let asset = asset as? AVAsset else {
            return
          }

          let duration = asset.duration.seconds
          var item: [String: Any] = [
            "id": UUID().uuidString,
            "mimeType": "video/mp4",
            "durationMs": Int(duration * 1000)
          ]

          pickedItems.append(item)
        }
      } else {
        dispatchGroup.leave()
      }
    }

    dispatchGroup.notify(queue: .main) {
      self.resolver(pickedItems)
    }
  }

  private func stripEXIFFromImage(_ image: UIImage) -> UIImage {
    // Remove EXIF by creating new image without metadata
    return image.withoutExif() ?? image
  }
}

// MARK: - DocumentPickerDelegate

class DocumentPickerDelegate: NSObject, UIDocumentPickerDelegate {
  let resolver: RCTPromiseResolveBlock
  let rejecter: RCTPromiseRejectBlock
  let fileHelper: PickerFileHelper?
  let copyToCache: Bool

  init(
    resolver: @escaping RCTPromiseResolveBlock,
    rejecter: @escaping RCTPromiseRejectBlock,
    fileHelper: PickerFileHelper?,
    copyToCache: Bool
  ) {
    self.resolver = resolver
    self.rejecter = rejecter
    self.fileHelper = fileHelper
    self.copyToCache = copyToCache
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    controller.dismiss(animated: true)
    
    var pickedItems: [[String: Any]] = []
    
    for url in urls {
      let item = fileHelper?.getPickedItemMap(url: url) ?? [:]
      pickedItems.append(item)
    }
    
    resolver(pickedItems)
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    controller.dismiss(animated: true)
    resolver([])
  }
}

// MARK: - ImagePickerDelegate (for iOS < 16)

class ImagePickerDelegate: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  let resolver: RCTPromiseResolveBlock
  let rejecter: RCTPromiseRejectBlock
  let fileHelper: PickerFileHelper?
  let copyToCache: Bool

  init(
    resolver: @escaping RCTPromiseResolveBlock,
    rejecter: @escaping RCTPromiseRejectBlock,
    fileHelper: PickerFileHelper?,
    copyToCache: Bool
  ) {
    self.resolver = resolver
    self.rejecter = rejecter
    self.fileHelper = fileHelper
    self.copyToCache = copyToCache
  }

  func imagePickerController(
    _ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
  ) {
    picker.dismiss(animated: true)
    
    var pickedItems: [[String: Any]] = []
    
    if let image = info[.originalImage] as? UIImage {
      var item: [String: Any] = [
        "id": UUID().uuidString,
        "mimeType": "image/jpeg",
        "width": Int(image.size.width),
        "height": Int(image.size.height)
      ]
      pickedItems.append(item)
    }
    
    resolver(pickedItems)
  }

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true)
    resolver([])
  }
}

// MARK: - Extension for EXIF removal

extension UIImage {
  func withoutExif() -> UIImage? {
    guard let imageData = self.jpegData(compressionQuality: 0.95) else {
      return nil
    }
    
    // Create new image data without EXIF
    return UIImage(data: imageData)
  }
}
