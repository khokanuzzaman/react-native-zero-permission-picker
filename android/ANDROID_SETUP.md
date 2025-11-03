# Android Setup Guide

## Automatic Linking

For React Native 0.60+, the module should automatically link during `react-native link`.

## Manual Setup

If you need to link manually:

### 1. Update `android/settings.gradle`

```gradle
include ':react-native-files-picker'
project(':react-native-files-picker').projectDir = new File(rootProject.projectDir, '../node_modules/react-native-files-picker/android')
```

### 2. Update `android/app/build.gradle`

```gradle
dependencies {
    // ... existing dependencies ...
    implementation project(':react-native-files-picker')
}
```

### 3. Register Module in MainApplication.kt/Java

**Kotlin:**
```kotlin
import com.reactnative.zeropermissionpicker.RNZeroPermissionPickerPackage

class MainApplication : Application(), ReactApplication {
    override fun getPackages(): List<ReactPackage> {
        return listOf(
            MainReactPackage(),
            RNZeroPermissionPickerPackage()
        )
    }
}
```

**Java:**
```java
import com.reactnative.zeropermissionpicker.RNZeroPermissionPickerPackage;

public class MainApplication extends Application implements ReactApplication {
    @Override
    protected List<ReactPackage> getPackages() {
        return Arrays.asList(
            new MainReactPackage(),
            new RNZeroPermissionPickerPackage()
        );
    }
}
```

## No Permissions Required

This module **does not require any manifest permissions**. It uses:
- **Android 13+**: System Photo Picker (scoped access, no permissions)
- **Android ≤12**: Storage Access Framework (scoped access, no permissions)

Both approaches grant temporary access to user-selected files only, without requiring `READ_EXTERNAL_STORAGE`, `READ_MEDIA_*`, or other broad permissions.

## Target API

- **Min SDK**: 21 (Android 5.0)
- **Target SDK**: 33+ (Android 13+) recommended
- **Compile SDK**: 33+

## Dependencies

The module uses:
- React Native Core
- AndroidX Activity (for Activity Results)
- AndroidX AppCompat
- AndroidX ExifInterface (for EXIF handling)

These are automatically included via the build.gradle file.
