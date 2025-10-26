export type MediaKind = 'image' | 'video' | 'mixed';
export type FileKind = 'any' | 'image' | 'video' | 'pdf' | 'audio' | 'text' | 'zip' | 'custom';

export interface BasePickOptions {
  /** Allow multiple selection. Default: false */
  multiple?: boolean;
  /** Copy selected files to app cache for guaranteed read access. Default: true */
  copyToCache?: boolean;
  /** Include file size in returned metadata. Default: true */
  includeFileSize?: boolean;
  /** Include image dimensions in returned metadata. Default: true */
  includeDimensions?: boolean;
  /** Filter by MIME types, e.g., ['image/jpeg','image/png']. */
  preferredMimeTypes?: string[];
  /** Filter by file extensions, e.g., ['jpg','png','pdf']. */
  preferredExtensions?: string[];
}

export interface ImageOptions {
  /** Strip EXIF metadata on-device for privacy. Default: false */
  stripEXIF?: boolean;
  /** JPEG quality 0..1 when compression enabled. Default: 0.9 */
  quality?: number;
  /** Resize long-edge to this pixel size. If omitted, keep original. Default: undefined */
  maxLongEdge?: number;
  /** Enable on-device compression pipeline. Default: false */
  compress?: boolean;
  /** Convert HEIC/HEIF to JPEG when true (iOS). Default: true */
  convertHeicToJpeg?: boolean;
}

export interface FilePickerOptions extends BasePickOptions {
  /** Allow selecting directories (iOS ignores this). Default: false */
  allowDirectories?: boolean;
}

export interface PickedItem {
  /** Stable identifier from OS or generated UUID */
  id: string;
  /** App-readable URI (file:// if cached, content:// if not) */
  uri: string;
  /** Original filename */
  displayName?: string;
  /** MIME type, e.g., 'image/jpeg' */
  mimeType?: string;
  /** File size in bytes */
  size?: number;
  /** Image width in pixels (images only) */
  width?: number;
  /** Image height in pixels (images only) */
  height?: number;
  /** Video duration in milliseconds (videos only) */
  durationMs?: number;
  /** Whether EXIF was stripped from this image */
  exifStripped?: boolean;
}

export interface PickError extends Error {
  code:
    | 'CANCELED'
    | 'NO_SUPPORT'
    | 'EMPTY_SELECTION'
    | 'IO_ERROR'
    | 'UNSUPPORTED_TYPE'
    | 'PROCESSING_FAILED';
  cause?: unknown;
}

// Import implementations
import {
  pickMediaImpl,
  pickFilesImpl,
  isSystemPhotoPickerAvailableImpl,
  clearCachedFilesImpl,
} from './implementation';

/**
 * Pick images, videos, or both using the system picker.
 * - Android 13+: System Photo Picker
 * - Android ≤12: Storage Access Framework (SAF)
 * - iOS: PHPicker
 *
 * @param kind 'image', 'video', or 'mixed'
 * @param opts Options including compression, EXIF stripping, etc.
 * @returns Promise<PickedItem[]> Array of selected items (empty if canceled)
 * @throws PickError on failure
 */
export const pickMedia = pickMediaImpl;

/**
 * Pick general files using the system picker.
 * - iOS: UIDocumentPickerViewController
 * - Android: Storage Access Framework (SAF) with ACTION_OPEN_DOCUMENT
 *
 * @param kind Filter type: 'any', 'image', 'video', 'pdf', 'audio', 'text', 'zip', 'custom'
 * @param opts Options including file filters and caching
 * @returns Promise<PickedItem[]> Array of selected items
 * @throws PickError on failure
 */
export const pickFiles = pickFilesImpl;

/**
 * Check if the system Photo Picker is available.
 * Returns true on Android 13+ and always true on iOS.
 * Android ≤12 falls back to SAF (ACTION_OPEN_DOCUMENT).
 *
 * @returns Promise<boolean>
 */
export const isSystemPhotoPickerAvailable = isSystemPhotoPickerAvailableImpl;

/**
 * Clear all cached files created by the picker.
 * Safe to call repeatedly.
 */
export const clearCachedFiles = clearCachedFilesImpl;
