const {getDefaultConfig} = require('@react-native/metro-config');
const path = require('path');

const projectRoot = __dirname;
const workspaceRoot = path.resolve(projectRoot, '..');
const appNodeModules = path.resolve(projectRoot, 'node_modules');

const config = getDefaultConfig(projectRoot);

config.resolver = config.resolver || {};

// Always resolve react and react-native from the example app itself so that
// Metro doesn't accidentally pick up the copies inside the library package.
config.resolver.extraNodeModules = {
  ...(config.resolver.extraNodeModules || {}),
  react: path.resolve(appNodeModules, 'react'),
  'react-native': path.resolve(appNodeModules, 'react-native'),
};

// Force Metro to only look inside the example app's node_modules when resolving
// packages. This prevents it from walking up into the library's own node_modules
// (which might contain mismatched React/React Native versions).
config.resolver.disableHierarchicalLookup = true;
config.resolver.nodeModulesPaths = [appNodeModules];

// Watch the parent directory (root package) for changes so edits in the library
// (src/, android/, ios/, etc.) trigger fast refresh in the example app.
config.watchFolders = [workspaceRoot];

module.exports = config;
