export const NativeModules: Record<string, any> = {
  RNZeroPermissionPicker: {
    pickMedia: jest.fn(async () => []),
    pickFiles: jest.fn(async () => []),
    isSystemPhotoPickerAvailable: jest.fn(async () => true),
    clearCachedFiles: jest.fn(async () => {}),
  },
};

export const Platform = { OS: 'ios' } as const;

export default { NativeModules, Platform };


