dart_library.library('lib/html/js_typed_interop_anonymous2_exp_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__js_typed_interop_anonymous2_exp_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const js_typed_interop_anonymous2_exp_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  js_typed_interop_anonymous2_exp_test.main = function() {
    html_config.useHtmlConfiguration();
    unittest$.test('simple', dart.fn(() => {
      let b = {};
      let a = {b: b};
      src__matcher__expect.expect(a.b, src__matcher__core_matchers.equals(b));
      src__matcher__expect.expect(b.c, src__matcher__core_matchers.isNull);
    }, VoidTodynamic()));
  };
  dart.fn(js_typed_interop_anonymous2_exp_test.main, VoidTodynamic());
  // Exports:
  exports.js_typed_interop_anonymous2_exp_test = js_typed_interop_anonymous2_exp_test;
});
