/**
 * @license
 * Copyright (c) 2014 The Polymer Project Authors. All rights reserved.
 * This code may only be used under the BSD style license found at http://polymer.github.io/LICENSE.txt
 * The complete set of authors may be found at http://polymer.github.io/AUTHORS.txt
 * The complete set of contributors may be found at http://polymer.github.io/CONTRIBUTORS.txt
 * Code distributed by Google as part of the polymer project is also
 * subject to an additional IP rights grant found at http://polymer.github.io/PATENTS.txt
 */

module.exports = function(config) {
  config.set({
      frameworks: [ 'mocha' ]
    , files: [
          'build/build.js'
        , 'test/bootstrap/karma.js'
        , 'test/*.js'
      ]
    , reporters: [ 'progress' ]
    , colors: true
    , logLevel: config.LOG_INFO
    , autoWatch: false
    , browsers: [ 'PhantomJS' ]
    , browserDisconnectTimeout: 10000
    , browserDisconnectTolerance: 2
    , browserNoActivityTimeout: 20000
    , singleRun: true
  });

  switch (process.env.CHAI_TEST_ENV) {
    case 'sauce':
      require('./karma.sauce')(config);
      break;
    default:
      // ...
      break;
  };
};
