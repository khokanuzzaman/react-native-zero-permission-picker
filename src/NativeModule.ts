import { NativeModules, Platform } from 'react-native';

const LINKING_ERROR = `The package 'react-native-files-picker' doesn't seem to be linked. 
Make sure:
- You have run \`npm install react-native-files-picker\`
- You rebuilt the app after installing the package
- You have Android/iOS native modules properly configured`;

const ZeroPermissionPickerModule = NativeModules.RNZeroPermissionPicker
  ? NativeModules.RNZeroPermissionPicker
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

interface NativePickedItem {
  id: string;
  uri: string;
  displayName?: string;
  mimeType?: string;
  size?: number;
  width?: number;
  height?: number;
  durationMs?: number;
  exifStripped?: boolean;
}

interface NativePickMediaOptions {
  kind: 'image' | 'video' | 'mixed';
  multiple?: boolean;
  copyToCache?: boolean;
  includeFileSize?: boolean;
  includeDimensions?: boolean;
  preferredMimeTypes?: string[];
  preferredExtensions?: string[];
  stripEXIF?: boolean;
  quality?: number;
  maxLongEdge?: number;
  compress?: boolean;
  convertHeicToJpeg?: boolean;
}

interface NativePickFilesOptions {
  kind?: string;
  multiple?: boolean;
  copyToCache?: boolean;
  includeFileSize?: boolean;
  includeDimensions?: boolean;
  preferredMimeTypes?: string[];
  preferredExtensions?: string[];
  allowDirectories?: boolean;
}

export const RNZeroPermissionPicker = {
  pickMedia(opts: NativePickMediaOptions): Promise<NativePickedItem[]> {
    return ZeroPermissionPickerModule.pickMedia(opts);
  },

  pickFiles(opts: NativePickFilesOptions): Promise<NativePickedItem[]> {
    return ZeroPermissionPickerModule.pickFiles(opts);
  },

  isSystemPhotoPickerAvailable(): Promise<boolean> {
    if (Platform.OS === 'ios') {
      return Promise.resolve(true);
    }
    return ZeroPermissionPickerModule.isSystemPhotoPickerAvailable();
  },

  clearCachedFiles(): Promise<void> {
    return ZeroPermissionPickerModule.clearCachedFiles();
  },
};
