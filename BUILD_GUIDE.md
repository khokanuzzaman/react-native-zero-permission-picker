# Build & Development Guide

## Quick Start

### Install Dependencies

```bash
npm install
```

### Build TypeScript

```bash
npm run build
```

This compiles `src/` to `lib/` with full type definitions.

### Watch Mode

```bash
npm run watch
```

Automatically recompiles on changes.

### Type Checking

```bash
npm run type-check
```

Validates TypeScript without emitting files.

### Linting

```bash
npm run lint
```

Checks code style.

### Run Tests

```bash
npm run test
```

## Development Workflow

### 1. Modify TypeScript API

Edit `src/` files:
- `index.ts` - Main API and types
- `implementation.ts` - Validation and error handling
- `NativeModule.ts` - Native bridge

Build with:
```bash
npm run watch
```

### 2. Modify Android Native Module

Edit `android/src/main/java/com/reactnative/zeropermissionpicker/`:
- `RNZeroPermissionPickerModule.kt` - Main module logic
- `RNZeroPermissionPickerPackage.kt` - Module registration
- `PickerFileHelper.kt` - File operations

The module is automatically linked in example apps via Gradle.

### 3. Modify iOS Native Module

Edit `ios/`:
- `RNZeroPermissionPicker.swift` - Main module and delegates
- `PickerFileHelper.swift` - File operations

The module is automatically linked via CocoaPods.

### 4. Update Example App

Edit `example/App.tsx`:
- Test new features
- Update UI for new options
- Add new demo buttons

```bash
cd example
npx react-native run-ios
# or
npx react-native run-android
```

## Building for NPM

### Prepare for Publication

1. Update version in `package.json`:
```json
{
  "version": "0.2.0"
}
```

2. Build TypeScript:
```bash
npm run build
```

3. Verify files:
```bash
npm pack --dry-run
```

This shows what will be published (per `files` in package.json).

### Publish to NPM

```bash
npm publish
```

Or with a public scope:
```bash
npm publish --access public
```

### Tag Git Release

```bash
git tag v0.2.0
git push origin v0.2.0
```

## File Organization

### TypeScript Sources (`src/`)

**index.ts** - Public API
- Type exports: `MediaKind`, `FileKind`, `PickedItem`, `PickError`
- Option interfaces: `BasePickOptions`, `ImageOptions`, `FilePickerOptions`
- Function exports: `pickMedia`, `pickFiles`, etc.

**NativeModule.ts** - Bridge to native
- `RNZeroPermissionPicker` object
- Maps TypeScript calls to native module
- Platform-specific handling

**implementation.ts** - Business logic
- Input validation functions
- Error creation and handling
- Orchestration of native calls

### Android Module (`android/`)

**RNZeroPermissionPickerModule.kt**
```kotlin
@ReactMethod
fun pickMedia(options: ReadableMap, promise: Promise)
// Launches Photo Picker (API 33+) or SAF (API 21-32)

@ReactMethod
fun pickFiles(options: ReadableMap, promise: Promise)
// Launches SAF for general file picking

@ReactMethod
fun isSystemPhotoPickerAvailable(promise: Promise)
// Returns true on API 33+

@ReactMethod
fun clearCachedFiles(promise: Promise)
// Clears app cache directory
```

**PickerFileHelper.kt**
- `persistFile()` - Copies SAF/Photo Picker URIs into app storage when needed
- `transformImageIfNeeded()` - Handles EXIF stripping, HEIC conversion, compression, resizing
- `metadata()` - Extracts filename, MIME type, dimensions, duration, size
- `clearCache()` - Clears cache directory

### iOS Module (`ios/`)

**RNZeroPermissionPicker.swift**
```swift
@objc func pickMedia(_ options: NSDictionary, resolver: ..., rejecter: ...)
// iOS 16+: PHPickerViewController
// iOS 14/15: UIImagePickerController fallback

@objc func pickFiles(_ options: NSDictionary, resolver: ..., rejecter: ...)
// UIDocumentPickerViewController for all file types

@objc func isSystemPhotoPickerAvailable(_ resolve: ..., rejecter: ...)
// Always true on iOS

@objc func clearCachedFiles(_ resolve: ..., rejecter: ...)
// Clears cached files
```

Delegates:
- `PickerDelegate` - PHPickerViewController delegate
- `DocumentPickerDelegate` - UIDocumentPickerViewController delegate
- `ImagePickerDelegate` - UIImagePickerController delegate (iOS 14/15)

**PickerFileHelper.swift**
- `persistFile()` / `writeData()` - Ensure selected files have persisted URLs
- `processImageIfNeeded()` - Handles EXIF stripping, HEIC conversion, compression, resizing
- `metadata()` - Extract MIME type, size, dimensions, duration
- `clearCache()` - Clear cache and temp directories

## Testing

### Unit Tests

```bash
npm run test
```

Tests are in `__tests__/index.test.ts` and verify:
- Type exports
- Function exports
- Input validation
- Error handling

### Integration Testing

Use the example app:

```bash
cd example
npm install
npx react-native run-ios    # or run-android
```

Test scenarios:
1. Pick single image
2. Pick multiple images
3. Pick videos
4. Pick mixed media
5. Pick PDFs
6. Compress images
7. Strip EXIF
8. Clear cache
9. Cancel picker
10. Error handling

## Troubleshooting

### TypeScript Compilation Errors

```bash
npm run type-check
```

Check for:
- Missing type definitions
- Incompatible types
- Import errors

### iOS Build Errors

```bash
cd ios && pod install --repo-update && cd ..
```

Then rebuild:
```bash
cd example && npx react-native run-ios
```

### Android Build Errors

```bash
cd android && ./gradlew clean build && cd ..
```

Common issues:
- Gradle version conflicts
- Missing Kotlin dependencies
- SDK version mismatches

### Native Module Not Linked

**iOS**:
```bash
cd ios && pod install && cd ..
```

**Android**:
```bash
npx react-native link react-native-files-picker
```

## Code Quality

### Type Safety

All TypeScript uses strict mode:
```json
{
  "compilerOptions": {
    "strict": true
  }
}
```

Features:
- No implicit `any`
- No implicit `any[]`
- Check function returns
- Check null/undefined

### Error Handling

All errors are `PickError`:
```typescript
export interface PickError extends Error {
  code: 'CANCELED' | 'IO_ERROR' | 'UNSUPPORTED_TYPE' | ...;
  cause?: unknown;
}
```

### Validation

Input validation in `implementation.ts`:
- Checks `MediaKind` and `FileKind` values
- Validates option types
- Checks option ranges (quality 0..1, sizes > 0)

## Performance Considerations

### Image Compression

- Default quality: 0.9
- Resize by long edge (maintains aspect ratio)
- Only applied if `compress: true`

### EXIF Removal

- Strips metadata by re-encoding to JPEG
- Default: `false` (skip for performance)
- Enable only if privacy required

### File Caching

- Default: enabled (`copyToCache: true`)
- Copies to app cache directory
- Enables long-term access without permissions
- Can clear with `clearCachedFiles()`

### Metadata Extraction

- Image dimensions: Decoded with `inJustDecodeBounds`
- Video duration: Extracted via `MediaMetadataRetriever`
- File size: From file attributes
- Only extracted if requested

## Security Notes

1. **No Broad Permissions**: Never requests storage access
2. **Scoped Access**: All file access via system pickers
3. **EXIF Privacy**: Can strip metadata on-device
4. **File Isolation**: Cached files stored in app cache only
5. **No Cloud Upload**: Files never sent anywhere (user controls)

## Contributing

When adding features:

1. Update TypeScript types in `src/index.ts`
2. Add validation in `src/implementation.ts`
3. Update native implementations
4. Add tests in `__tests__/index.test.ts`
5. Update example app to demonstrate feature
6. Document in `README.md`

## Release Checklist

- [ ] Update `package.json` version
- [ ] Run `npm run build`
- [ ] Run `npm run type-check`
- [ ] Run `npm run test`
- [ ] Update `README.md` if needed
- [ ] Test example app on iOS and Android
- [ ] Commit changes
- [ ] Create git tag
- [ ] Run `npm publish`

## Resources

- [React Native Native Modules](https://reactnative.dev/docs/native-modules-intro)
- [Android Photo Picker API](https://developer.android.com/about/versions/13/features#photo-picker)
- [iOS PHPicker](https://developer.apple.com/documentation/photokit/phpicker)
- [Storage Access Framework](https://developer.android.com/guide/topics/providers/document-provider)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)
