dart_library.library('lib/html/window_eq_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__window_eq_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const src__matcher__operator_matchers = unittest.src__matcher__operator_matchers;
  const window_eq_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  window_eq_test.main = function() {
    html_config.useHtmlConfiguration();
    let obfuscated = null;
    unittest$.test('notNull', dart.fn(() => {
      src__matcher__expect.expect(html.window, src__matcher__core_matchers.isNotNull);
      src__matcher__expect.expect(html.window, src__matcher__operator_matchers.isNot(src__matcher__core_matchers.equals(obfuscated)));
    }, VoidTodynamic()));
  };
  dart.fn(window_eq_test.main, VoidTodynamic());
  // Exports:
  exports.window_eq_test = window_eq_test;
});
