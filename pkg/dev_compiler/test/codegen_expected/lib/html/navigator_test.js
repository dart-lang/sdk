dart_library.library('lib/html/navigator_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__navigator_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const navigator_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  navigator_test.main = function() {
    html_config.useHtmlConfiguration();
    unittest$.test('language never returns null', dart.fn(() => {
      src__matcher__expect.expect(html.window[dartx.navigator][dartx.language], src__matcher__core_matchers.isNotNull);
    }, VoidTodynamic()));
  };
  dart.fn(navigator_test.main, VoidTodynamic());
  // Exports:
  exports.navigator_test = navigator_test;
});
