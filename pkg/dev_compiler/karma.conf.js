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
      {pattern: 'lib/js/amd/dart_sdk.js', included: false},
      {pattern: 'gen/codegen_output/*.js', included: false},
      {pattern: 'gen/codegen_output/pkg/*.js', included: false},
      {pattern: 'gen/codegen_output/language/**/*.js', included: false},
      {pattern: 'gen/codegen_output/corelib/**/*.js', included: false},
      {pattern: 'gen/codegen_output/lib/**/*.js', included: false},
      {pattern: 'gen/codegen_tests/lib/**/*.txt', included: false},
      {pattern: 'test/browser/*.js', included: false},
      {pattern: 'node_modules/is_js/*.js', included: false},
      'test-main.js',
    ],

    // list of files to exclude
    exclude: [],

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

    // Proxy required to serve resources needed by tests.
    proxies: {
      '/root_dart/tests/lib/': '/base/gen/codegen_tests/lib/'
    },

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
      ChromeTravis: {
        base: 'Chrome',
        flags: [ '--no-sandbox' ]
      },

      ChromeCanaryTravis: {
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
    configuration.browsers = ['ChromeTravis'];
    configuration.autoWatch = false;
    // Enable this for more logging on Travis.  It is too much for Travis to
    // automatically display, but still results in a downloadable raw log.
    // configuration.logLevel = config.LOG_DEBUG;
    configuration.client.captureConsole = true;
  }

  if (process.env.DDC_BROWSERS) {
    configuration.browsers = process.env.DDC_BROWSERS.split(':');
  }

  config.set(configuration);
};
