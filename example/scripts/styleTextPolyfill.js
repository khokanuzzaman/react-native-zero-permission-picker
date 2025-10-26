const util = require('util');

if (typeof util.styleText !== 'function') {
  /**
   * Minimal polyfill so newer React Native CLI can run on older Node versions.
   * It ignores styling hints and just returns the plain string payload.
   */
  util.styleText = (...args) => {
    if (args.length === 0) {
      return '';
    }
    return String(args[args.length - 1]);
  };
}

