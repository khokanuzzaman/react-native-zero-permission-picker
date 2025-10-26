# react-native-zero-permission-picker

[![npm version](https://badge.fury.io/js/react-native-zero-permission-picker.svg)](https://badge.fury.io/js/react-native-zero-permission-picker)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Zero-permission file picker for React Native - select images, videos, and files on iOS and Android without requesting storage permissions.

## ✨ Features

- 🚫 **Zero Runtime Permissions** - No storage/photo/video permissions required
- 📱 **Modern APIs** - Uses Android Photo Picker (API 33+) and iOS PHPicker (iOS 16+)
- 🔄 **Backward Compatible** - Falls back to SAF (Android ≤12) and UIImagePickerController (iOS 15)
- 🎯 **Multiple Selection** - Pick multiple files at once
- 🖼️ **Image Processing** - Optional compression and EXIF stripping
- 📊 **Rich Metadata** - File size, dimensions, duration, MIME type
- 💾 **File Caching** - Automatic cache management
- 🔧 **TypeScript** - Full type safety
- ⚡ **Lightweight** - Minimal dependencies

## 🚀 Quick Start

### Installation

```bash
npm install react-native-zero-permission-picker
# or
yarn add react-native-zero-permission-picker
```

### iOS Setup

```bash
cd ios && pod install && cd ..
```

### Basic Usage

```typescript
import { pickMedia, pickFiles } from 'react-native-zero-permission-picker';

// Pick images
const images = await pickMedia('image', {
  multiple: true,
  copyToCache: true,
});

// Pick videos
const videos = await pickMedia('video', {
  multiple: true,
});

// Pick any files
const files = await pickFiles('any', {
  multiple: true,
});
```

## 📖 API Reference

### `pickMedia(kind, options)`

Pick images, videos, or mixed media.

**Parameters:**
- `kind: 'image' | 'video' | 'mixed'` - Type of media to pick
- `options: PickMediaOptions` - Configuration options

**Returns:** `Promise<PickedItem[]>`

**Example:**
```typescript
const items = await pickMedia('image', {
  multiple: true,
  copyToCache: true,
  stripEXIF: true,
  compressImage: {
    quality: 0.8,
    maxWidth: 1920,
    maxHeight: 1920,
  },
});
```

### `pickFiles(kind, options)`

Pick documents and files.

**Parameters:**
- `kind: 'any' | 'pdf' | 'video'` - Type of files to pick
- `options: PickFilesOptions` - Configuration options

**Returns:** `Promise<PickedItem[]>`

**Example:**
```typescript
const pdfs = await pickFiles('pdf', {
  multiple: true,
});
```

### `isSystemPhotoPickerAvailable()`

Check if the system photo picker is available.

**Returns:** `Promise<boolean>`

### `clearCachedFiles()`

Clear all cached files.

**Returns:** `Promise<void>`

## 🔧 Options

### PickMediaOptions

```typescript
interface PickMediaOptions {
  multiple?: boolean;           // Allow multiple selection
  copyToCache?: boolean;        // Copy files to app cache
  stripEXIF?: boolean;          // Remove EXIF data (images only)
  compressImage?: {             // Image compression (images only)
    quality: number;            // 0.0 to 1.0
    maxWidth: number;
    maxHeight: number;
  };
}
```

### PickFilesOptions

```typescript
interface PickFilesOptions {
  multiple?: boolean;           // Allow multiple selection
}
```

## 📊 Return Value

### PickedItem

```typescript
interface PickedItem {
  id: string;                   // Unique identifier
  uri: string;                  // File URI
  displayName: string;          // Original filename
  mimeType: string;             // MIME type
  size: number;                 // File size in bytes
  width?: number;               // Image width (images only)
  height?: number;              // Image height (images only)
  durationMs?: number;          // Video duration (videos only)
  exifStripped?: boolean;       // EXIF was removed
}
```

## 🎯 Platform Support

| Platform | API | Requirements |
|----------|-----|--------------|
| Android 13+ | Photo Picker | No permissions |
| Android ≤12 | Storage Access Framework | No permissions |
| iOS 16+ | PHPickerViewController | No permissions |
| iOS 15 | UIImagePickerController | No permissions |

## 📱 Examples

### Display Images

```typescript
import { Image } from 'react-native';

const images = await pickMedia('image', { multiple: true });

images.forEach(item => (
  <Image 
    source={{ uri: item.uri }} 
    style={{ width: 200, height: 200 }} 
  />
));
```

### Upload Files

```typescript
const files = await pickFiles('any', { multiple: true, copyToCache: true });

for (const file of files) {
  const formData = new FormData();
  formData.append('file', {
    uri: file.uri,
    type: file.mimeType,
    name: file.displayName,
  });
  
  await fetch('https://api.example.com/upload', {
    method: 'POST',
    body: formData,
  });
}
```

### Image Grid

```typescript
import { FlatList, Image } from 'react-native';

<FlatList
  data={images}
  numColumns={3}
  renderItem={({ item }) => (
    <Image 
      source={{ uri: item.uri }} 
      style={{ width: 100, height: 100 }} 
    />
  )}
/>
```

## 🛠️ Development

### Building

```bash
npm run build
```

### Type Checking

```bash
npm run type-check
```

### Linting

```bash
npm run lint
```

## 📄 License

MIT - see [LICENSE](LICENSE) for details.

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📞 Support

- 📖 [Documentation](https://github.com/yourusername/react-native-zero-permission-picker#readme)
- 🐛 [Issues](https://github.com/yourusername/react-native-zero-permission-picker/issues)
- 💬 [Discussions](https://github.com/yourusername/react-native-zero-permission-picker/discussions)

## 🙏 Acknowledgments

- Android Photo Picker API
- iOS PHPickerViewController
- React Native Community
- All contributors

---

**Made with ❤️ for the React Native community**