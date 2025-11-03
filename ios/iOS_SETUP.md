# iOS Setup Guide

## Automatic Linking

For React Native 0.60+, the module should automatically link during `pod install`.

## Manual Setup

If you need to link manually:

### 1. Add to `Podfile`

```ruby
target 'YourAppName' do
  pod 'react-native-files-picker', :path => '../node_modules/react-native-files-picker'
end
```

### 2. Install Pods

```bash
cd ios
pod install
cd ..
```

### 3. Update Xcode Linking (if needed)

In Xcode:
1. Select your project
2. Select your target
3. Go to Build Phases → Link Binary With Libraries
4. Add `RNZeroPermissionPicker.framework` if not already present

## Info.plist

No permissions are required in `Info.plist`. The system pickers don't require privacy declarations for scoped file access.

## Supported iOS Versions

- **iOS 16+**: Uses modern PHPickerViewController with multi-select
- **iOS 14-15**: Falls back to UIImagePickerController (single select)
- **iOS <14**: Not supported

## Framework Dependencies

The module requires:
- PhotosUI.framework (iOS 16+)
- UIKit.framework
- AVFoundation.framework
- ImageIO.framework

These are standard iOS frameworks included in the build.

## Swift Compatibility

The module is written in Swift and requires:
- Swift 5.0+
- iOS deployment target: 14.0+

Xcode will handle Swift interoperability automatically for Objective-C projects.

## Build Issues

If you encounter build errors:

1. **Clean build**: `rm -rf ios/Pods && cd ios && pod install && cd ..`
2. **Update CocoaPods**: `pod repo update`
3. **Check Xcode version**: Ensure Xcode 14+ for Swift 5.5+ support

## Testing

To test iOS implementation:

```bash
cd example
npx react-native run-ios
```

This will launch the example app on the default simulator.
