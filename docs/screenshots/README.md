# Screenshots

This directory contains screenshots and demo images for the `react-native-files-picker` package.

## Required Screenshots

### Example App Screenshots
- `example-app-main.png` - Main screen showing all picker buttons
- `example-app-images.png` - Image picker in action
- `example-app-videos.png` - Video picker in action
- `example-app-files.png` - File picker in action
- `example-app-results.png` - Results display with metadata

### Platform-Specific Screenshots
- `android-photo-picker.png` - Android 13+ Photo Picker
- `android-saf-picker.png` - Android ≤12 Storage Access Framework
- `ios-phpicker.png` - iOS 16+ PHPickerViewController
- `ios-image-picker.png` - iOS 14/15 UIImagePickerController fallback

### Permission Screenshots
- `no-permissions-android.png` - Android app info showing no storage permissions
- `no-permissions-ios.png` - iOS app info showing no photo library permissions

## How to Take Screenshots

### 1. Run the Example App
```bash
cd example
npm run android  # or npm run ios
```

### 2. Take Screenshots
1. **Main Screen**: Show all picker buttons
2. **Picker in Action**: Show system picker open
3. **Results**: Show selected files with metadata
4. **App Settings**: Show no permissions requested

### 3. Screenshot Guidelines
- Use high resolution (at least 1080p)
- Show real device screens (not emulator)
- Include both light and dark mode if possible
- Crop to remove status bar and navigation
- Use consistent styling

## File Naming Convention
- `{feature}-{platform}-{description}.png`
- Example: `picker-android-photo-picker.png`
- Example: `results-ios-metadata-display.png`

## Image Optimization
- Compress images for web (use tools like ImageOptim)
- Keep file sizes under 500KB each
- Use PNG for screenshots with text
- Use JPG for photos/demos
