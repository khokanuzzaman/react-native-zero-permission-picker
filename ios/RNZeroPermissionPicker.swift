import AVFoundation
import Foundation
import PhotosUI
import UniformTypeIdentifiers
import UIKit

struct PickerSharedOptions {
  let copyToCache: Bool
  let includeFileSize: Bool
  let includeDimensions: Bool
  let imageOptions: ImageProcessingOptions
}

struct PickerBridgeError: Error {
  let code: String
  let message: String
  let underlying: Error?
}

@objc(RNZeroPermissionPickerModule)
class RNZeroPermissionPickerModule: NSObject, RCTBridgeModule {
  static func moduleName() -> String! {
    "RNZeroPermissionPicker"
  }

  static func requiresMainQueueSetup() -> Bool {
    true
  }

  private let fileHelper = PickerFileHelper()

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
      let sharedOptions = self.sharedOptions(from: options)

      if #available(iOS 16, *) {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = multiple ? 0 : 1
        configuration.preferredAssetRepresentationMode = .current
        if let filter = self.pickerFilter(for: kind) {
          configuration.filter = filter
        }

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = PickerDelegate(
          options: sharedOptions,
          fileHelper: self.fileHelper,
          resolver: resolver,
          rejecter: rejecter
        )
        rootViewController.present(picker, animated: true)
      } else {
        self.presentLegacyPicker(
          kind: kind,
          options: sharedOptions,
          resolver: resolver,
          rejecter: rejecter,
          from: rootViewController
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
      let sharedOptions = self.sharedOptions(from: options)

      let documentPicker = UIDocumentPickerViewController(
        forOpeningContentTypes: self.documentTypes(for: kind)
      )
      documentPicker.allowsMultipleSelection = multiple
      documentPicker.delegate = DocumentPickerDelegate(
        options: sharedOptions,
        fileHelper: self.fileHelper,
        resolver: resolver,
        rejecter: rejecter
      )
      rootViewController.present(documentPicker, animated: true)
    }
  }

  @objc
  func isSystemPhotoPickerAvailable(
    _ resolve: RCTPromiseResolveBlock,
    rejecter: @escaping RCTPromiseRejectBlock
  ) {
    resolve(true)
  }

  @objc
  func clearCachedFiles(
    _ resolve: RCTPromiseResolveBlock,
    rejecter: @escaping RCTPromiseRejectBlock
  ) {
    do {
      try fileHelper.clearCache()
      resolve(nil)
    } catch {
      rejecter("IO_ERROR", "Failed to clear cache", error)
    }
  }

  // MARK: - Helpers

  private func sharedOptions(from dictionary: NSDictionary) -> PickerSharedOptions {
    let copyToCache = dictionary["copyToCache"] as? Bool ?? true
    let stripEXIF = dictionary["stripEXIF"] as? Bool ?? false
    let compress = dictionary["compress"] as? Bool ?? false
    let quality = dictionary["quality"] as? Double ?? 0.9
    let maxLongEdge = (dictionary["maxLongEdge"] as? NSNumber)?.intValue
    let convertHeicToJpeg = dictionary["convertHeicToJpeg"] as? Bool ?? true
    let includeFileSize = dictionary["includeFileSize"] as? Bool ?? true
    let includeDimensions = dictionary["includeDimensions"] as? Bool ?? true

    let imageOptions = ImageProcessingOptions(
      stripExif: stripEXIF,
      compress: compress,
      quality: quality,
      maxLongEdge: maxLongEdge,
      convertHeicToJpeg: convertHeicToJpeg
    )

    return PickerSharedOptions(
      copyToCache: copyToCache,
      includeFileSize: includeFileSize,
      includeDimensions: includeDimensions,
      imageOptions: imageOptions
    )
  }

  @available(iOS 16, *)
  private func pickerFilter(for kind: String) -> PHPickerFilter? {
    switch kind {
    case "image":
      return .images
    case "video":
      return .videos
    case "mixed":
      return PHPickerFilter.any(of: [.images, .videos])
    default:
      return nil
    }
  }

  private func documentTypes(for kind: String) -> [UTType] {
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
      return [.plainText, .text]
    case "zip":
      return [.zip]
    default:
      return [.item]
    }
  }

  private func presentLegacyPicker(
    kind: String,
    options: PickerSharedOptions,
    resolver: @escaping RCTPromiseResolveBlock,
    rejecter: @escaping RCTPromiseRejectBlock,
    from viewController: UIViewController
  ) {
    let picker = UIImagePickerController()
    picker.delegate = ImagePickerDelegate(
      options: options,
      fileHelper: fileHelper,
      resolver: resolver,
      rejecter: rejecter
    )

    picker.sourceType = .photoLibrary
    switch kind {
    case "image":
      picker.mediaTypes = ["public.image"]
    case "video":
      picker.mediaTypes = ["public.movie"]
    default:
      picker.mediaTypes = ["public.image", "public.movie"]
    }

    viewController.present(picker, animated: true)
  }
}

// MARK: - PHPicker Delegate

class PickerDelegate: NSObject, PHPickerViewControllerDelegate {
  private let options: PickerSharedOptions
  private let fileHelper: PickerFileHelper
  private let resolver: RCTPromiseResolveBlock
  private let rejecter: RCTPromiseRejectBlock
  private let processingQueue = DispatchQueue(
    label: "com.reactnative.zeropermissionpicker.processing",
    qos: .userInitiated
  )
  private let syncQueue = DispatchQueue(label: "com.reactnative.zeropermissionpicker.sync")
  private var items: [[String: Any]] = []
  private var firstError: PickerBridgeError?

  init(
    options: PickerSharedOptions,
    fileHelper: PickerFileHelper,
    resolver: @escaping RCTPromiseResolveBlock,
    rejecter: @escaping RCTPromiseRejectBlock
  ) {
    self.options = options
    self.fileHelper = fileHelper
    self.resolver = resolver
    self.rejecter = rejecter
  }

  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    picker.dismiss(animated: true)

    guard !results.isEmpty else {
      resolver([])
      return
    }

    let group = DispatchGroup()

    for result in results {
      group.enter()
      processingQueue.async {
        self.process(result: result) { outcome in
          self.syncQueue.async {
            switch outcome {
            case .success(let item):
              self.items.append(item)
            case .failure(let error):
              if self.firstError == nil {
                self.firstError = error
              }
            }
            group.leave()
          }
        }
      }
    }

    group.notify(queue: .main) {
      if let error = self.firstError {
        self.rejecter(error.code, error.message, error.underlying)
      } else {
        self.resolver(self.items)
      }
    }
  }

  private func process(
    result: PHPickerResult,
    completion: @escaping (Result<[String: Any], PickerBridgeError>) -> Void
  ) {
    let provider = result.itemProvider
    let suggestedName = provider.suggestedName

    if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
      loadFile(from: provider, typeCandidates: [.image, .jpeg, .png], suggestedName: suggestedName) { outcome in
        completion(outcome.flatMap { url in self.handleImage(at: url, suggestedName: suggestedName) })
      }
    } else if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
      loadFile(from: provider, typeCandidates: [.movie, .mpeg4Movie, .quickTimeMovie], suggestedName: suggestedName) { outcome in
        completion(outcome.map { self.buildMetadata(for: $0, suggestedName: suggestedName, includeDuration: true) })
      }
    } else {
      loadFile(from: provider, typeCandidates: [.item, .data], suggestedName: suggestedName) { outcome in
        completion(outcome.map { self.buildMetadata(for: $0, suggestedName: suggestedName, includeDuration: false) })
      }
    }
  }

  private func handleImage(
    at url: URL,
    suggestedName: String?
  ) -> Result<[String: Any], PickerBridgeError> {
    do {
      let processed = try fileHelper.processImageIfNeeded(at: url, options: options.imageOptions)
      var item = buildMetadata(for: processed.url, suggestedName: suggestedName, includeDuration: false)
      if let mimeType = processed.mimeType {
        item["mimeType"] = mimeType
      }
      if processed.exifStripped {
        item["exifStripped"] = true
      }
      return .success(item)
    } catch {
      return .failure(
        PickerBridgeError(
          code: "PROCESSING_ERROR",
          message: "Failed to process selected image",
          underlying: error
        )
      )
    }
  }

  private func buildMetadata(
    for url: URL,
    suggestedName: String?,
    includeDuration: Bool
  ) -> [String: Any] {
    fileHelper.metadata(
      for: url,
      displayName: suggestedName,
      includeFileSize: options.includeFileSize,
      includeDimensions: options.includeDimensions,
      includeDuration: includeDuration
    )
  }

  private func loadFile(
    from provider: NSItemProvider,
    typeCandidates: [UTType],
    suggestedName: String?,
    completion: @escaping (Result<URL, PickerBridgeError>) -> Void
  ) {
    guard let type = typeCandidates.first else {
      completion(
        .failure(
          PickerBridgeError(
            code: "UNSUPPORTED_TYPE",
            message: "Unsupported item type",
            underlying: nil
          )
        )
      )
      return
    }

    provider.loadFileRepresentation(forTypeIdentifier: type.identifier) { url, error in
      if let url = url {
        do {
          let persisted = try self.fileHelper.persistFile(
            at: url,
            preferredName: suggestedName,
            copyToCache: self.options.copyToCache
          )
          completion(.success(persisted))
        } catch {
          completion(
            .failure(
              PickerBridgeError(
                code: "IO_ERROR",
                message: "Failed to persist selected item",
                underlying: error
              )
            )
          )
        }
      } else if let error = error {
        completion(
          .failure(
            PickerBridgeError(
              code: "IO_ERROR",
              message: "Failed to read selected item",
              underlying: error
            )
          )
        )
      } else {
        self.loadFile(
          from: provider,
          typeCandidates: Array(typeCandidates.dropFirst()),
          suggestedName: suggestedName,
          completion: completion
        )
      }
    }
  }
}

// MARK: - Document Picker Delegate

class DocumentPickerDelegate: NSObject, UIDocumentPickerDelegate {
  private let options: PickerSharedOptions
  private let fileHelper: PickerFileHelper
  private let resolver: RCTPromiseResolveBlock
  private let rejecter: RCTPromiseRejectBlock

  init(
    options: PickerSharedOptions,
    fileHelper: PickerFileHelper,
    resolver: @escaping RCTPromiseResolveBlock,
    rejecter: @escaping RCTPromiseRejectBlock
  ) {
    self.options = options
    self.fileHelper = fileHelper
    self.resolver = resolver
    self.rejecter = rejecter
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    controller.dismiss(animated: true)

    var collected: [[String: Any]] = []

    for url in urls {
      var accessGranted = url.startAccessingSecurityScopedResource()
      defer {
        if accessGranted {
          url.stopAccessingSecurityScopedResource()
        }
      }

      do {
        let persisted = try fileHelper.persistFile(
          at: url,
          preferredName: url.lastPathComponent,
          copyToCache: options.copyToCache
        )
        let item = fileHelper.metadata(
          for: persisted,
          displayName: url.lastPathComponent,
          includeFileSize: options.includeFileSize,
          includeDimensions: options.includeDimensions,
          includeDuration: options.includeDimensions
        )
        collected.append(item)
      } catch {
        rejecter("IO_ERROR", "Failed to save selected document", error)
        return
      }
    }

    resolver(collected)
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    controller.dismiss(animated: true)
    resolver([])
  }
}

// MARK: - UIImagePickerController Delegate

class ImagePickerDelegate: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  private let options: PickerSharedOptions
  private let fileHelper: PickerFileHelper
  private let resolver: RCTPromiseResolveBlock
  private let rejecter: RCTPromiseRejectBlock

  init(
    options: PickerSharedOptions,
    fileHelper: PickerFileHelper,
    resolver: @escaping RCTPromiseResolveBlock,
    rejecter: @escaping RCTPromiseRejectBlock
  ) {
    self.options = options
    self.fileHelper = fileHelper
    self.resolver = resolver
    self.rejecter = rejecter
  }

  func imagePickerController(
    _ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
  ) {
    picker.dismiss(animated: true)

    var collected: [[String: Any]] = []

    if let mediaURL = info[.mediaURL] as? URL {
      do {
        let persisted = try fileHelper.persistFile(
          at: mediaURL,
          preferredName: mediaURL.lastPathComponent,
          copyToCache: options.copyToCache
        )
        let item = fileHelper.metadata(
          for: persisted,
          displayName: mediaURL.lastPathComponent,
          includeFileSize: options.includeFileSize,
          includeDimensions: false,
          includeDuration: true
        )
        collected.append(item)
      } catch {
        rejecter("IO_ERROR", "Failed to persist selected video", error)
        return
      }
    } else if let imageURL = info[.imageURL] as? URL {
      switch handleStillImage(at: imageURL, suggestedName: imageURL.lastPathComponent) {
      case .success(let item):
        collected.append(item)
      case .failure(let error):
        rejecter(error.code, error.message, error.underlying)
        return
      }
    } else if let image = info[.originalImage] as? UIImage {
      guard let data = image.jpegData(compressionQuality: CGFloat(max(0.0, min(1.0, options.imageOptions.quality)))) else {
        rejecter("PROCESSING_ERROR", "Failed to encode selected image", nil)
        return
      }
      do {
        let persisted = try fileHelper.writeData(
          data,
          preferredName: "photo.jpg",
          copyToCache: options.copyToCache,
          defaultExtension: "jpg"
        )
        switch handleStillImage(at: persisted, suggestedName: "photo.jpg") {
        case .success(let item):
          collected.append(item)
        case .failure(let error):
          rejecter(error.code, error.message, error.underlying)
          return
        }
      } catch {
        rejecter("IO_ERROR", "Failed to write selected image", error)
        return
      }
    }

    resolver(collected)
  }

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true)
    resolver([])
  }

  private func handleStillImage(at url: URL, suggestedName: String?) -> Result<[String: Any], PickerBridgeError> {
    do {
      let processed = try fileHelper.processImageIfNeeded(at: url, options: options.imageOptions)
      var item = fileHelper.metadata(
        for: processed.url,
        displayName: suggestedName,
        includeFileSize: options.includeFileSize,
        includeDimensions: options.includeDimensions,
        includeDuration: false
      )
      if let mimeType = processed.mimeType {
        item["mimeType"] = mimeType
      }
      if processed.exifStripped {
        item["exifStripped"] = true
      }
      return .success(item)
    } catch {
      return .failure(
        PickerBridgeError(
          code: "PROCESSING_ERROR",
          message: "Failed to process selected image",
          underlying: error
        )
      )
    }
  }
}
