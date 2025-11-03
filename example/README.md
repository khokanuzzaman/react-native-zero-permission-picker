# Zero Permission Picker Example App

This is a working example demonstrating how to use the `react-native-files-picker` package.

## Features Demonstrated

### 📸 Media Picking
- **Pick Images** - Select one or more images
- **Pick Videos** - Select one or more videos
- **Pick Mixed** - Select both images and videos together

### 📄 File Picking
- **Pick Any Files** - Select any file type
- **Pick PDFs** - Select PDF documents specifically

### 🎯 Key Features
- Zero runtime permissions required
- Multiple file selection
- Displays file metadata (size, dimensions, duration)
- Shows thumbnails for selected images
- EXIF stripping available
- Cache management

## How to Run

### Prerequisites
- Node.js installed
- Android Studio with Android SDK
- Physical Android device connected OR Android emulator running
- Device/emulator API level 21+

### Step 1: Install Dependencies
```bash
cd example
npm install
```

### Step 2: Start Metro Bundler
```bash
npm start
```
Metro will start on port 8081. Keep this terminal window open.

### Step 3: Build and Run on Android
Open a new terminal window:
```bash
cd example
npm run android
```

This will:
1. Build the Android app (first time takes 5-10 minutes)
2. Install the app on your connected device
3. Launch the app automatically

## What to Expect

When the app launches, you'll see:

### Main Screen
![Main Screen](../docs/screenshots/example-app-main.jpeg)

- **Header**: "Zero Permission Picker" with description
- **Media Picking Section** with 3 buttons:
  - Pick Images
  - Pick Videos  
  - Pick Mixed (Images & Videos)
- **File Picking Section** with 2 buttons:
  - Pick Any Files
  - Pick PDFs
- **Info Section** showing:
  - Photo Picker availability status
  - Number of selected items

### Using the App

1. **Tap any button** (e.g., "Pick Images")
2. **System picker opens** - Native Android/iOS file picker appears
3. **Select files** - Choose one or multiple files
4. **Results display** below showing:
   ![Selected Items](../docs/screenshots/selected-item.jpeg)
   - Thumbnails for images
   - File metadata (name, size, dimensions, etc.)
   - URI for each selected file

### Expected Behavior

#### Android
- **Android 13+**: Photo Picker appears (no permissions needed)
- **Android ≤12**: Storage Access Framework (SAF) picker opens
- **Selected files** are copied to app cache automatically

#### iOS
- **iOS 14+**: PHPickerViewController opens
- **iOS 14/15**: UIImagePickerController as fallback
- **Files** accessible via returned URIs

## Example Output

When you pick images, you'll see something like:

```
Selected Items: 2

Item 1
image/jpeg
URI: content://...
ID: 550e8400-e29b-41d4-a716-446655440000
Size: 245.76 KB
Dimensions: 1080 × 1920px
```

## Troubleshooting

### Build Fails
- Make sure Android SDK is installed
- Check that `ANDROID_HOME` environment variable is set
- Ensure device is connected: `adb devices`

### App Crashes
- Check Metro bundler logs
- Look for errors in `adb logcat`
- Verify React Native version compatibility (0.61+)

### No Files Selected
- System picker behavior is normal - user can cancel
- Check that you granted proper permissions if using old Android versions

## Code Examples

See `App.tsx` for complete implementation examples of:
- Picking different media types
- Handling errors
- Displaying selected files
- Clearing cache
- Checking photo picker availability
