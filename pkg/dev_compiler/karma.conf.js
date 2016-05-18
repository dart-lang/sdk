// Karma configuration
// Generated on Mon Apr 20 2015 06:33:20 GMT-0700 (PDT)

module.exports = function(config) {
  var configuration = {

    // base path that will be used to resolve all patterns (eg. files, exclude)
    basePath: '',

    // frameworks to use
    // available frameworks: https://npmjs.org/browse/keyword/karma-adapter
    frameworks: ['mocha', 'requirejs', 'chai'],

    // list of files / patterns to load in the browser
    files: [
      'lib/runtime/dart_*.js',
      'lib/runtime/dart/*.js',
      // {pattern: 'test/browser/*.js', included: false}
      'gen/codegen_output/async_helper/async_helper.js',
      'gen/codegen_output/dom/dom.js',
      'gen/codegen_output/expect/expect.js',
      'gen/codegen_output/path/path.js',
      'gen/codegen_output/stack_trace/stack_trace.js',
      'gen/codegen_output/js/js.js',
      'gen/codegen_output/matcher/matcher.js',
      'gen/codegen_output/unittest/unittest.js',
      'gen/codegen_output/syncstar_syntax.js',
      'gen/codegen_output/language/**.js',
      'gen/codegen_output/language/sub/sub.js',
      'gen/codegen_output/language/*.lib',
      'gen/codegen_output/corelib/**.js',
      'gen/codegen_output/lib/convert/**.js',
      'gen/codegen_output/lib/html/**.js',
      'gen/codegen_output/lib/math/**.js',
      'gen/codegen_output/lib/typed_data/**.js',
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
      captureConsole: false,
      mocha: {
        ui: 'tdd',
        timeout : 6000
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
    logLevel: config.LOG_INFO,

    // enable / disable watching file and executing tests whenever any file changes
    autoWatch: true,

    browserNoActivityTimeout: 60000,
    browserDisconnectTolerance: 5,

    // start these browsers
    // available browser launchers: https://npmjs.org/browse/keyword/karma-launcher
    customLaunchers: {
      chrome_travis: {
        base: 'Chrome',
        flags: [ '--no-sandbox' ]
      },

      chrome_canary_travis: {
        base: 'ChromeCanary',
        flags: [ '--no-sandbox' ]
      },
    },

    browsers: ['Chrome'],

    // Continuous Integration mode
    // if true, Karma captures browsers, runs the tests and exits
    singleRun: false,
  };

  if (process.env.TRAVIS) {
    configuration.browsers = ['chrome_canary_travis'];
    configuration.autoWatch = false;
    // Enable this for more logging on Travis.  It is too much for Travis to
    // automatically display, but still results in a downloadable raw log.
    // configuration.logLevel = config.LOG_DEBUG;
    configuration.client.captureConsole = true;
  }

  config.set(configuration);
};
