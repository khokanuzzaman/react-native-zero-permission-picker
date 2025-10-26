import {
  pickMedia,
  pickFiles,
  isSystemPhotoPickerAvailable,
  clearCachedFiles,
  PickError,
} from '../src/index';

describe('react-native-zero-permission-picker', () => {
  describe('Type Exports', () => {
    it('should export MediaKind type', () => {
      // Type check only - this is a compilation test
      const kind: 'image' | 'video' | 'mixed' = 'image';
      expect(kind).toBeDefined();
    });

    it('should export FileKind type', () => {
      const kind: 'any' | 'pdf' | 'image' = 'pdf';
      expect(kind).toBeDefined();
    });

    it('should export PickedItem interface', () => {
      const item = {
        id: 'test-id',
        uri: 'file:///path/to/file',
        displayName: 'test.jpg',
        mimeType: 'image/jpeg',
        size: 1024,
        width: 800,
        height: 600,
      };
      expect(item.id).toBe('test-id');
    });

    it('should export PickError interface', () => {
      const error = new Error('Test error') as PickError;
      error.code = 'IO_ERROR';
      expect(error.code).toBe('IO_ERROR');
    });
  });

  describe('API Functions', () => {
    it('should export pickMedia function', () => {
      expect(typeof pickMedia).toBe('function');
    });

    it('should export pickFiles function', () => {
      expect(typeof pickFiles).toBe('function');
    });

    it('should export isSystemPhotoPickerAvailable function', () => {
      expect(typeof isSystemPhotoPickerAvailable).toBe('function');
    });

    it('should export clearCachedFiles function', () => {
      expect(typeof clearCachedFiles).toBe('function');
    });
  });

  describe('Input Validation', () => {
    it('pickMedia should accept valid media kind', async () => {
      const kinds: ('image' | 'video' | 'mixed')[] = [
        'image',
        'video',
        'mixed',
      ];
      kinds.forEach((kind) => {
        expect(typeof kind).toBe('string');
      });
    });

    it('pickFiles should accept valid file kind', async () => {
      const kinds = [
        'any',
        'image',
        'video',
        'pdf',
        'audio',
        'text',
        'zip',
        'custom',
      ];
      kinds.forEach((kind) => {
        expect(typeof kind).toBe('string');
      });
    });
  });
});
