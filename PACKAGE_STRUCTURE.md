# Package Structure & Architecture

## Directory Layout

```
react-native-zero-permission-picker/
├── src/                           # TypeScript source files
│   ├── index.ts                  # Main API exports and type definitions
│   ├── NativeModule.ts           # Bridge to native modules
│   └── implementation.ts         # Validation and native method wrappers
├── android/                       # Android native module
│   ├── src/main/java/com/reactnative/zeropermissionpicker/
│   │   ├── RNZeroPermissionPickerModule.kt       # Main Kotlin module
│   │   ├── RNZeroPermissionPickerPackage.kt      # React Native package
│   │   └── PickerFileHelper.kt                   # File handling utilities
│   ├── build.gradle              # Gradle build configuration
│   └── ANDROID_SETUP.md          # Setup instructions
├── ios/                           # iOS native module
│   ├── RNZeroPermissionPicker.swift              # Main Swift module
│   ├── PickerFileHelper.swift                    # File handling utilities
│   └── iOS_SETUP.md              # Setup instructions
├── example/                       # Example React Native app
│   └── App.tsx                   # Full-featured example with UI
├── __tests__/                     # Test files
│   └── index.test.ts             # Basic tests
├── lib/                           # Compiled JavaScript (generated)
├── package.json                  # Package metadata and dependencies
├── tsconfig.json                 # TypeScript configuration
├── jest.config.js                # Jest test configuration
├── react-native-zero-permission-picker.podspec  # iOS CocoaPods spec
├── README.md                     # Main documentation
├── LICENSE                       # MIT License
├── PACKAGE_STRUCTURE.md          # This file
└── .gitignore                    # Git ignore rules
```

## Architecture Overview

### TypeScript Layer (`src/`)

The public API is defined in TypeScript with full type safety:

- **index.ts**: Exports all public types and functions (pickMedia, pickFiles, etc.)
- **NativeModule.ts**: Bridge that connects to native module implementations
- **implementation.ts**: Input validation, error handling, and orchestration

### Android Native Module (`android/`)

**Language**: Kotlin (with Java interop)

**Key Components**:
- **RNZeroPermissionPickerModule.kt**: React Native module implementing `pickMedia` and `pickFiles` via native intents
- **RNZeroPermissionPickerPackage.kt**: React Native package for module registration
- **PickerFileHelper.kt**: Handles file caching, EXIF removal, compression, and metadata extraction

**Implementation Strategy**:
- Android 13+ (API 33+): Uses `MediaStore.ACTION_PICK_IMAGES` (system Photo Picker)
- Android ≤12 (API 21-32): Uses `Intent.ACTION_OPEN_DOCUMENT` (Storage Access Framework)
- No storage permissions are requested

### iOS Native Module (`ios/`)

**Language**: Swift 5

**Key Components**:
- **RNZeroPermissionPicker.swift**: Main module with delegates for PHPicker, UIDocumentPicker, and legacy UIImagePickerController
- **PickerFileHelper.swift**: Handles file metadata extraction and caching
- Delegates handle different picker types:
  - `PickerDelegate`: Handles PHPickerViewController (iOS 16+)
  - `DocumentPickerDelegate`: Handles UIDocumentPickerViewController
  - `ImagePickerDelegate`: Handles UIImagePickerController (iOS 15)

**Implementation Strategy**:
- iOS 16+: Uses PHPickerViewController (modern, no permissions)
- iOS 15: Fallback to UIImagePickerController (requires no manifest permissions)
- No Photo Library permissions are requested

### Example App (`example/`)

A full-featured React Native app demonstrating:
- All picker types (images, videos, mixed, files, PDFs)
- Image compression and EXIF stripping
- Metadata display (size, dimensions, duration)
- Error handling
- File caching and clearing

The app has a beautiful, modern UI with proper error handling and loading states.

## Data Flow

### Image/Video Picking Flow

```
User calls pickMedia('image', opts)
    ↓
TypeScript validation (implementation.ts)
    ↓
Native bridge (NativeModule.ts)
    ↓
Native implementation (iOS/Android)
    ├─ Launch system picker
    ├─ User selects files
    ├─ Process (compress, strip EXIF if requested)
    ├─ Copy to cache (if enabled)
    └─ Extract metadata
    ↓
Return PickedItem[] array
```

### File Picking Flow

```
User calls pickFiles('pdf', opts)
    ↓
TypeScript validation
    ↓
Native bridge
    ↓
Native implementation
    ├─ Launch UIDocumentPickerViewController (iOS)
    ├─ Or ACTION_OPEN_DOCUMENT intent (Android)
    ├─ User selects files
    ├─ Copy to cache (if enabled)
    └─ Extract metadata
    ↓
Return PickedItem[] array
```

## Error Handling

All errors are wrapped in `PickError` with standardized codes:
- `CANCELED`: User dismissed picker
- `IO_ERROR`: File I/O operation failed
- `UNSUPPORTED_TYPE`: Invalid media/file kind
- `PROCESSING_FAILED`: Compression, EXIF removal, etc. failed
- `NO_SUPPORT`: Feature not supported on platform/API level

## Zero-Permission Strategy

### Why No Permissions?

1. **System Pickers Grant Scoped Access**: iOS PHPicker and Android Photo Picker provide temporary access to user-selected files only
2. **No Broad Storage Access**: We never request `READ_EXTERNAL_STORAGE` or `READ_MEDIA_*`
3. **Temporary URIs**: Files are typically accessed via content:// URIs with limited validity
4. **App Cache Copy**: By caching selected files, we ensure long-term access without permissions

### Platform-Specific Details

**Android**:
- Photo Picker (API 33+): Scoped access, no permissions
- SAF (API 21-32): Scoped access via ACTION_OPEN_DOCUMENT, no permissions
- Both grant temporary access to selected files only

**iOS**:
- PHPicker (iOS 16+): Scoped access, no Photo Library permission needed
- UIImagePickerController (iOS 15): Scoped access, no Photo Library permission needed
- UIDocumentPicker: No permissions required for scoped file access

## Build & Distribution

### Development Build

```bash
npm run build     # Compile TypeScript
npm run watch     # Watch mode
npm run type-check # Type checking
npm run lint      # Linting
npm run test      # Run tests
```

### NPM Publication

Files included in distribution:
- `src/` - TypeScript source
- `lib/` - Compiled JavaScript with type definitions
- `android/` - Android native module
- `ios/` - iOS native module
- `react-native-zero-permission-picker.podspec` - CocoaPods spec
- `README.md`, `LICENSE`, `package.json`

## Compatibility

### React Native
- Minimum: 0.61.0
- Supports 0.61+ up to latest versions

### iOS
- Minimum: iOS 15
- Target: iOS 15+ (iOS 16+ uses PHPicker, iOS 15 uses legacy UIImagePickerController)

### Android
- Minimum: API 21 (Android 5.0)
- Target: API 33+ (Android 13+) recommended
- Gracefully handles API 21-32 via SAF

### TypeScript
- TypeScript 5.0+
- Strict mode enabled
- Full JSDoc documentation

## Dependencies

### Runtime
- react (peer)
- react-native (peer)

### Development
- typescript
- jest
- eslint
- @types/react-native
- @types/react

### Native (Auto-resolved)
- Android: React Native Core, AndroidX, Kotlin Runtime
- iOS: React Native Core, PhotosUI framework

## Future Enhancement Points

1. **Camera Capture**: Could add camera capture functionality
2. **Cloud Integrations**: Could add Drive/Dropbox support (separate module)
3. **Advanced Filtering**: Could add more granular MIME type filtering
4. **Batch Operations**: Could optimize multiple file handling
5. **Progress Tracking**: Could add compression progress callbacks
