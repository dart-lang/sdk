var allTestFiles = [];
var TEST_REGEXP = /(_test|_multi)\.js$/i;

var pathToModule = function(path) {
  return path.replace(/^\/base\//, '').replace(/\.js$/, '');
};

var testsToSkip = [
  // syntax error in DDC's generated code (related to break/continue labels):
  '/base/gen/codegen_output/language/execute_finally6_test.js',
  '/base/gen/codegen_output/language/switch_label2_test.js',
  '/base/gen/codegen_output/language/infinite_switch_label_test.js',
  '/base/gen/codegen_output/language/switch_label_test.js',
  '/base/gen/codegen_output/language/nested_switch_label_test.js',
  '/base/gen/codegen_output/language/switch_try_catch_test.js',

  // module code execution error in DDC's generated code
  // (types are initialized incorrectly):
  '/base/gen/codegen_output/language/f_bounded_quantification3_test.js',
  '/base/gen/codegen_output/language/regress_16640_test.js',
  '/base/gen/codegen_output/language/cyclic_type_test_02_multi.js',
  '/base/gen/codegen_output/language/cyclic_type_test_03_multi.js',
  '/base/gen/codegen_output/language/cyclic_type_test_04_multi.js',
  '/base/gen/codegen_output/language/cyclic_type2_test.js',
  '/base/gen/codegen_output/language/least_upper_bound_expansive_test_none_multi.js'
];

Object.keys(window.__karma__.files).forEach(function(file) {
  if (TEST_REGEXP.test(file) && testsToSkip.indexOf(file) == -1) {
    // Normalize paths to RequireJS module names.
    allTestFiles.push(pathToModule(file));
  }
});

allTestFiles.push('test/browser/language_tests');
allTestFiles.push('test/browser/runtime_tests');

require.config({
  // Karma serves files under /base.
  baseUrl: '/base',

  // Travis bots take a bit longer to load all ~2k test files.
  waitSeconds: 30,

  paths: {
    dart_sdk: 'lib/js/amd/dart_sdk',
    async_helper: 'gen/codegen_output/pkg/async_helper',
    expect: 'gen/codegen_output/pkg/expect',
    js: 'gen/codegen_output/pkg/js',
    matcher: 'gen/codegen_output/pkg/matcher',
    meta: 'gen/codegen_output/pkg/meta',
    minitest: 'gen/codegen_output/pkg/minitest',
    path: 'gen/codegen_output/pkg/path',
    stack_trace: 'gen/codegen_output/pkg/stack_trace',
    unittest: 'gen/codegen_output/pkg/unittest',
    is: 'node_modules/is_js/is',
    test_status: 'gen/codegen_output/test_status'
  },

  // Require all test files before starting tests.
  deps: allTestFiles,

  // We have to kickoff jasmine, as it is asynchronous
  callback: window.__karma__.start
});
