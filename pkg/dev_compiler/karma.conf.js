// Karma configuration
// Generated on Mon Apr 20 2015 06:33:20 GMT-0700 (PDT)

module.exports = function(config) {
  config.set({

    // base path that will be used to resolve all patterns (eg. files, exclude)
    basePath: '',

    // frameworks to use
    // available frameworks: https://npmjs.org/browse/keyword/karma-adapter
    frameworks: ['mocha', 'requirejs', 'chai'],

    // list of files / patterns to load in the browser
    files: [
      'test-main.js',
      'lib/runtime/dart_runtime.js',
      'lib/runtime/dart/core.js',
      'lib/runtime/dart/collection.js',
      'lib/runtime/dart/math.js',
      // {pattern: 'test/browser/*.js', included: false}
      'test/browser/*.js',
    ],

    // list of files to exclude
    exclude: [
    ],

    // preprocess matching files before serving them to the browser
    // available preprocessors: https://npmjs.org/browse/keyword/karma-preprocessor
    preprocessors: {
    },

    client: {
      mocha: {
        ui: 'tdd'
      }
    },

    // test results reporter to use
    // possible values: 'dots', 'progress'
    // available reporters: https://npmjs.org/browse/keyword/karma-reporter
    reporters: ['progress'],

    // web server port
    port: 9876,

    // enable / disable colors in the output (reporters and logs)
    colors: true,

    // level of logging
    // possible values: config.LOG_DISABLE || config.LOG_ERROR || config.LOG_WARN || config.LOG_INFO || config.LOG_DEBUG
    logLevel: config.LOG_INFO,

    // enable / disable watching file and executing tests whenever any file changes
    autoWatch: false,

    // start these browsers
    // available browser launchers: https://npmjs.org/browse/keyword/karma-launcher

    // FIXME(vsm): Once harmony is on by default, we can simply add the following:
    //   browsers: ['Chrome'],
    // and remove the custom launchers.
    customLaunchers: {
      chrome_harmony: {
	base: 'Chrome',
        flags: ['--js-flags="--harmony-arrow-functions --harmony-classes --harmony-computed-property-names"']
      },

      chrome_canary_harmony: {
	base: 'ChromeCanary',
        flags: ['--js-flags="--harmony-arrow-functions --harmony-classes --harmony-computed-property-names"']
      },

      chrome_travis: {
	base: 'Chrome',
        flags: ['--no-sandbox --js-flags="--harmony-arrow-functions --harmony-classes --harmony-computed-property-names"']
      },
    },
    browsers: ['chrome_harmony'],

    // Continuous Integration mode
    // if true, Karma captures browsers, runs the tests and exits
    singleRun: false,
  });
};
