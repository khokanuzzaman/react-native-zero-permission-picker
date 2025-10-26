# Quick Start Guide

## Installation

```bash
npm install react-native-zero-permission-picker
# or
yarn add react-native-zero-permission-picker
```

### iOS Setup

```bash
cd ios && pod install && cd ..
```

## Basic Usage

### Pick Images

```typescript
import { pickMedia } from 'react-native-zero-permission-picker';

const pickImages = async () => {
  try {
    const items = await pickMedia('image', {
      multiple: true,
      copyToCache: true,
      stripEXIF: false,
    });
    
    items.forEach(item => {
      console.log('Image URI:', item.uri);
      console.log('Size:', item.size, 'bytes');
      console.log('Dimensions:', item.width, ' x ', item.height);
    });
  } catch (error) {
    console.error('Error picking images:', error);
  }
};
```

### Pick Videos

```typescript
const pickVideos = async () => {
  const items = await pickMedia('video', {
    multiple: true,
  });
  
  items.forEach(item => {
    console.log('Video URI:', item.uri);
    console.log('Duration:', item.durationMs, 'ms');
  });
};
```

### Pick Any Files

```typescript
import { pickFiles } from 'react-native-zero-permission-picker';

const pickFiles = async () => {
  const items = await pickFiles('any', {
    multiple: true,
  });
  
  items.forEach(item => {
    console.log('File:', item.displayName);
    console.log('MIME type:', item.mimeType);
    console.log('Size:', item.size);
  });
};
```

### Pick PDFs Specifically

```typescript
const pickPDFs = async () => {
  const items = await pickFiles('pdf', {
    multiple: true,
  });
};
```

## Image Compression

```typescript
const pickAndCompressImages = async () => {
  const items = await pickMedia('image', {
    multiple: true,
    copyToCache: true,
    compressImage: {
      quality: 0.8,      // 0.0 to 1.0
      maxWidth: 1920,
      maxHeight: 1920,
    },
    stripEXIF: true,
  });
};
```

## Display Images

```typescript
import { Image } from 'react-native';

// Using the URI directly
<Image source={{ uri: item.uri }} style={{ width: 200, height: 200 }} />
```

## Check Photo Picker Availability

```typescript
import { isSystemPhotoPickerAvailable } from 'react-native-zero-permission-picker';

const checkAvailability = async () => {
  const available = await isSystemPhotoPickerAvailable();
  if (available) {
    console.log('Using modern photo picker');
  } else {
    console.log('Using fallback picker');
  }
};
```

## Clear Cache

```typescript
import { clearCachedFiles } from 'react-native-zero-permission-picker';

const clearCache = async () => {
  try {
    await clearCachedFiles();
    console.log('Cache cleared successfully');
  } catch (error) {
    console.error('Failed to clear cache:', error);
  }
};
```

## Error Handling

```typescript
import { PickError } from 'react-native-zero-permission-picker';

try {
  const items = await pickMedia('image', { multiple: true });
} catch (error) {
  const err = error as PickError;
  
  switch (err.code) {
    case 'USER_CANCELLED':
      console.log('User cancelled the picker');
      break;
    case 'PICKER_FAILED':
      console.log('Picker failed to open');
      break;
    case 'COPY_FAILED':
      console.log('Failed to copy file to cache');
      break;
    default:
      console.log('Unknown error:', err.message);
  }
}
```

## Complete Example

See the [example app](./example/App.tsx) for a complete implementation with UI components.

## Type Definitions

```typescript
interface PickedItem {
  id: string;
  uri: string;
  displayName: string;
  mimeType: string;
  size: number;
  width?: number;
  height?: number;
  durationMs?: number;
  exifStripped?: boolean;
}

interface PickError {
  code: 'USER_CANCELLED' | 'PICKER_FAILED' | 'COPY_FAILED' | 'INVALID_PARAMS';
  message: string;
}
```

## Platform Support

- ✅ Android 5.0+ (API 21+)
- ✅ iOS 14.0+
- ✅ React Native 0.61+

### Platform-Specific Features

**Android 13+**: Uses system Photo Picker (no permissions needed)  
**Android ≤12**: Uses Storage Access Framework  
**iOS 14+**: Uses PHPickerViewController  
**iOS 13**: Uses UIImagePickerController  

## Common Use Cases

### Upload to Server

```typescript
const uploadImages = async () => {
  const items = await pickMedia('image', { multiple: true, copyToCache: true });
  
  for (const item of items) {
    const formData = new FormData();
    formData.append('file', {
      uri: item.uri,
      type: item.mimeType,
      name: item.displayName,
    });
    
    await fetch('https://your-server.com/upload', {
      method: 'POST',
      body: formData,
    });
  }
};
```

### Display Grid of Images

```typescript
import { FlatList, Image } from 'react-native';

<FlatList
  data={items}
  numColumns={3}
  renderItem={({ item }) => (
    <Image source={{ uri: item.uri }} style={{ width: 100, height: 100 }} />
  )}
/>
```

## Need Help?

- Check the [example app](./example/) for working code
- See the [full documentation](./README.md)
- Open an issue on GitHub
