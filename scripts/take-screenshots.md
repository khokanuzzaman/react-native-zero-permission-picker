# Screenshot Capture Guide

This guide helps you capture screenshots for the `react-native-zero-permission-picker` documentation.

## Prerequisites

1. **Physical Device**: Use a real Android/iOS device (not emulator)
2. **App Installed**: The example app should be running
3. **Screenshot Tools**: 
   - Android: Built-in screenshot (Power + Volume Down)
   - iOS: Built-in screenshot (Power + Home or Power + Volume Up)

## Screenshot Checklist

### 1. Example App Screenshots

#### Main Screen
- [ ] Launch the example app
- [ ] Take screenshot showing all buttons
- [ ] Save as: `docs/screenshots/example-app-main.png`

#### Image Picker in Action
- [ ] Tap "Pick Images" button
- [ ] Take screenshot of system picker open
- [ ] Save as: `docs/screenshots/example-app-images.png`

#### Video Picker in Action
- [ ] Tap "Pick Videos" button
- [ ] Take screenshot of video picker
- [ ] Save as: `docs/screenshots/example-app-videos.png`

#### File Picker in Action
- [ ] Tap "Pick Any Files" button
- [ ] Take screenshot of file picker
- [ ] Save as: `docs/screenshots/example-app-files.png`

#### Results Display
- [ ] Select some files
- [ ] Take screenshot showing results with metadata
- [ ] Save as: `docs/screenshots/example-app-results.png`

### 2. Platform-Specific Pickers

#### Android Photo Picker (API 33+)
- [ ] Use Android 13+ device
- [ ] Take screenshot of Photo Picker
- [ ] Save as: `docs/screenshots/android-photo-picker.png`

#### Android SAF (≤12)
- [ ] Use Android 12 or lower device
- [ ] Take screenshot of Storage Access Framework
- [ ] Save as: `docs/screenshots/android-saf-picker.png`

#### iOS PHPicker (16+)
- [ ] Use iOS 16+ device
- [ ] Take screenshot of PHPickerViewController
- [ ] Save as: `docs/screenshots/ios-phpicker.png`

#### iOS Image Picker (15)
- [ ] Use iOS 15 device
- [ ] Take screenshot of UIImagePickerController
- [ ] Save as: `docs/screenshots/ios-image-picker.png`

### 3. Permission Screenshots

#### Android App Info
- [ ] Go to Settings > Apps > Zero Permission Picker
- [ ] Take screenshot showing no storage permissions
- [ ] Save as: `docs/screenshots/no-permissions-android.png`

#### iOS App Info
- [ ] Go to Settings > Privacy & Security > Photos
- [ ] Take screenshot showing app not listed
- [ ] Save as: `docs/screenshots/no-permissions-ios.png`

## Screenshot Guidelines

### Quality
- **Resolution**: At least 1080p
- **Format**: PNG for screenshots with text
- **Size**: Compress to under 500KB each
- **Aspect Ratio**: Match device screen ratio

### Content
- **Crop**: Remove status bar and navigation
- **Focus**: Show relevant UI elements clearly
- **Consistency**: Use same device orientation
- **Lighting**: Good lighting, no shadows

### File Naming
- Use descriptive names
- Include platform when relevant
- Use kebab-case (lowercase with hyphens)
- Include version numbers if needed

## Tools for Screenshot Processing

### Image Optimization
```bash
# Install ImageOptim (macOS)
brew install --cask imageoptim

# Or use online tools
# - TinyPNG
# - Compressor.io
# - Squoosh.app
```

### Batch Processing
```bash
# Resize all screenshots to max width 800px
find docs/screenshots -name "*.png" -exec convert {} -resize 800x800\> {} \;

# Optimize all PNG files
find docs/screenshots -name "*.png" -exec pngquant --ext .png --force {} \;
```

## Upload to Repository

After taking screenshots:

1. **Add to git**:
   ```bash
   git add docs/screenshots/
   git commit -m "Add screenshots for documentation"
   git push
   ```

2. **Verify in GitHub**: Check that images display correctly in README

3. **Update documentation**: Add any missing screenshot references

## Troubleshooting

### Screenshots Not Displaying
- Check file paths are correct
- Ensure images are committed to git
- Verify file extensions (.png, .jpg)
- Check file sizes aren't too large

### Poor Quality Screenshots
- Use physical device instead of emulator
- Ensure good lighting
- Use high-resolution device
- Crop unnecessary elements

### Missing Screenshots
- Use placeholder images temporarily
- Add TODO comments in documentation
- Create issue to track missing screenshots
