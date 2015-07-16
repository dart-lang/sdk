// Karma configuration
// Generated on Mon Apr 20 2015 06:33:20 GMT-0700 (PDT)

module.exports = function(config) {
  var harmony_flags = '--js-flags="' + [
    '--harmony',
  ].join(' ') + '"';

  var configuration = {

    // base path that will be used to resolve all patterns (eg. files, exclude)
    basePath: '',

    // frameworks to use
    // available frameworks: https://npmjs.org/browse/keyword/karma-adapter
    frameworks: ['mocha', 'requirejs', 'chai'],

    // list of files / patterns to load in the browser
    files: [
      'lib/runtime/dart_*.js',
      'lib/runtime/_*.js',
      'lib/runtime/dart/*.js',
      // {pattern: 'test/browser/*.js', included: false}
      'test/browser/*.js',
      'test-main.js',
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
      },
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
    logLevel: config.LOG_DEBUG,

    // enable / disable watching file and executing tests whenever any file changes
    autoWatch: true,

    // start these browsers
    // available browser launchers: https://npmjs.org/browse/keyword/karma-launcher

    // FIXME(vsm): Once harmony is on by default, we can simply add the following:
    //   browsers: ['Chrome'],
    // and remove the custom launchers.
    customLaunchers: {
      chrome_harmony: {
	base: 'Chrome',
        flags: [ harmony_flags ],
      },

      chrome_canary_harmony: {
	base: 'ChromeCanary',
        flags: [ harmony_flags ],
      },

      chrome_canary_travis: {
	base: 'ChromeCanary',
        flags: [ '--no-sandbox', harmony_flags ]
      },
    },
    browsers: ['chrome_canary_harmony'],

    // Continuous Integration mode
    // if true, Karma captures browsers, runs the tests and exits
    singleRun: false,
  };

  if (process.env.TRAVIS) {
    configuration.browsers = ['chrome_canary_travis'];
    configuration.autoWatch = false;
  }

  config.set(configuration);
};
