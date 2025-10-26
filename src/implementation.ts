import {
  MediaKind,
  FileKind,
  BasePickOptions,
  ImageOptions,
  FilePickerOptions,
  PickedItem,
  PickError,
} from './index';
import { RNZeroPermissionPicker } from './NativeModule';

/**
 * Create a PickError with proper error code
 */
function createPickError(
  message: string,
  code: PickError['code'],
  cause?: unknown
): PickError {
  const error = new Error(message) as PickError;
  error.code = code;
  error.cause = cause;
  return error;
}

/**
 * Validate media kind
 */
function validateMediaKind(kind: MediaKind): void {
  if (!['image', 'video', 'mixed'].includes(kind)) {
    throw createPickError(
      `Invalid media kind: ${kind}. Expected 'image', 'video', or 'mixed'.`,
      'UNSUPPORTED_TYPE'
    );
  }
}

/**
 * Validate file kind
 */
function validateFileKind(kind?: FileKind): void {
  const validKinds = [
    'any',
    'image',
    'video',
    'pdf',
    'audio',
    'text',
    'zip',
    'custom',
  ];
  if (kind && !validKinds.includes(kind)) {
    throw createPickError(
      `Invalid file kind: ${kind}. Expected one of: ${validKinds.join(', ')}`,
      'UNSUPPORTED_TYPE'
    );
  }
}

/**
 * Validate image options
 */
function validateImageOptions(opts?: ImageOptions): void {
  if (!opts) return;

  if (opts.quality !== undefined) {
    if (typeof opts.quality !== 'number' || opts.quality < 0 || opts.quality > 1) {
      throw createPickError(
        'Image quality must be between 0 and 1',
        'UNSUPPORTED_TYPE'
      );
    }
  }

  if (opts.maxLongEdge !== undefined) {
    if (typeof opts.maxLongEdge !== 'number' || opts.maxLongEdge <= 0) {
      throw createPickError(
        'maxLongEdge must be a positive number',
        'UNSUPPORTED_TYPE'
      );
    }
  }
}

/**
 * Validate base pick options
 */
function validateBaseOptions(opts?: BasePickOptions): void {
  if (!opts) return;

  if (
    opts.multiple !== undefined &&
    typeof opts.multiple !== 'boolean'
  ) {
    throw createPickError(
      'multiple must be a boolean',
      'UNSUPPORTED_TYPE'
    );
  }

  if (
    opts.copyToCache !== undefined &&
    typeof opts.copyToCache !== 'boolean'
  ) {
    throw createPickError(
      'copyToCache must be a boolean',
      'UNSUPPORTED_TYPE'
    );
  }

  if (
    opts.includeFileSize !== undefined &&
    typeof opts.includeFileSize !== 'boolean'
  ) {
    throw createPickError(
      'includeFileSize must be a boolean',
      'UNSUPPORTED_TYPE'
    );
  }

  if (
    opts.includeDimensions !== undefined &&
    typeof opts.includeDimensions !== 'boolean'
  ) {
    throw createPickError(
      'includeDimensions must be a boolean',
      'UNSUPPORTED_TYPE'
    );
  }

  if (opts.preferredMimeTypes && !Array.isArray(opts.preferredMimeTypes)) {
    throw createPickError(
      'preferredMimeTypes must be an array of strings',
      'UNSUPPORTED_TYPE'
    );
  }

  if (opts.preferredExtensions && !Array.isArray(opts.preferredExtensions)) {
    throw createPickError(
      'preferredExtensions must be an array of strings',
      'UNSUPPORTED_TYPE'
    );
  }
}

/**
 * Generate a stable ID using simple UUID v4-like approach
 */
function generateId(): string {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    const v = c === 'x' ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

/**
 * Ensure picked items have IDs
 */
function ensurePickedItemIds(items: PickedItem[]): PickedItem[] {
  return items.map((item) => ({
    ...item,
    id: item.id || generateId(),
  }));
}

/**
 * Implementation of pickMedia
 */
export async function pickMediaImpl(
  kind: MediaKind,
  opts?: BasePickOptions & ImageOptions
): Promise<PickedItem[]> {
  try {
    validateMediaKind(kind);
    validateBaseOptions(opts);
    validateImageOptions(opts);

    const nativeOpts = {
      kind,
      multiple: opts?.multiple ?? false,
      copyToCache: opts?.copyToCache ?? true,
      includeFileSize: opts?.includeFileSize ?? true,
      includeDimensions: opts?.includeDimensions ?? true,
      preferredMimeTypes: opts?.preferredMimeTypes,
      preferredExtensions: opts?.preferredExtensions,
      stripEXIF: opts?.stripEXIF ?? false,
      quality: opts?.quality ?? 0.9,
      maxLongEdge: opts?.maxLongEdge,
      compress: opts?.compress ?? false,
      convertHeicToJpeg: opts?.convertHeicToJpeg ?? true,
    };

    const items = await RNZeroPermissionPicker.pickMedia(nativeOpts);
    
    if (!Array.isArray(items)) {
      throw createPickError(
        'Native module returned invalid response',
        'IO_ERROR'
      );
    }

    if (items.length === 0) {
      // User canceled or didn't select anything
      return [];
    }

    return ensurePickedItemIds(items);
  } catch (error) {
    if (error instanceof Error && 'code' in error) {
      throw error as PickError;
    }

    const message = error instanceof Error ? error.message : 'Unknown error';
    throw createPickError(
      `Failed to pick media: ${message}`,
      'IO_ERROR',
      error
    );
  }
}

/**
 * Implementation of pickFiles
 */
export async function pickFilesImpl(
  kind?: FileKind,
  opts?: FilePickerOptions
): Promise<PickedItem[]> {
  try {
    validateFileKind(kind);
    validateBaseOptions(opts);

    const nativeOpts = {
      kind: kind ?? 'any',
      multiple: opts?.multiple ?? false,
      copyToCache: opts?.copyToCache ?? true,
      includeFileSize: opts?.includeFileSize ?? true,
      includeDimensions: opts?.includeDimensions ?? true,
      preferredMimeTypes: opts?.preferredMimeTypes,
      preferredExtensions: opts?.preferredExtensions,
      allowDirectories: opts?.allowDirectories ?? false,
    };

    const items = await RNZeroPermissionPicker.pickFiles(nativeOpts);

    if (!Array.isArray(items)) {
      throw createPickError(
        'Native module returned invalid response',
        'IO_ERROR'
      );
    }

    if (items.length === 0) {
      // User canceled or didn't select anything
      return [];
    }

    return ensurePickedItemIds(items);
  } catch (error) {
    if (error instanceof Error && 'code' in error) {
      throw error as PickError;
    }

    const message = error instanceof Error ? error.message : 'Unknown error';
    throw createPickError(
      `Failed to pick files: ${message}`,
      'IO_ERROR',
      error
    );
  }
}

/**
 * Implementation of isSystemPhotoPickerAvailable
 */
export async function isSystemPhotoPickerAvailableImpl(): Promise<boolean> {
  try {
    return await RNZeroPermissionPicker.isSystemPhotoPickerAvailable();
  } catch (error) {
    // Fallback to false if check fails
    return false;
  }
}

/**
 * Implementation of clearCachedFiles
 */
export async function clearCachedFilesImpl(): Promise<void> {
  try {
    await RNZeroPermissionPicker.clearCachedFiles();
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    throw createPickError(
      `Failed to clear cached files: ${message}`,
      'IO_ERROR',
      error
    );
  }
}
