dart_library.library('lib/html/window_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__window_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const window_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  window_test.main = function() {
    html_config.useHtmlConfiguration();
    unittest$.test('scrollXY', dart.fn(() => {
      src__matcher__expect.expect(html.window[dartx.scrollX], 0);
      src__matcher__expect.expect(html.window[dartx.scrollY], 0);
    }, VoidTodynamic()));
  };
  dart.fn(window_test.main, VoidTodynamic());
  // Exports:
  exports.window_test = window_test;
});
