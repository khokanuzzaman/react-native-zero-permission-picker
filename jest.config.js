/** @type {import('jest').Config} */
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/__tests__'],
  moduleFileExtensions: ['ts', 'tsx', 'js', 'jsx', 'json', 'node'],
  transform: {
    '^.+\\.(ts|tsx)$': ['ts-jest', { isolatedModules: true }],
  },
  testRegex: '(/__tests__/.*|(\\.|/)(test|spec))\\.(ts|tsx|js)$',
  transformIgnorePatterns: ['/node_modules/'],
  moduleNameMapper: {
    '^react-native$': '<rootDir>/__mocks__/react-native.ts',
  },
};


