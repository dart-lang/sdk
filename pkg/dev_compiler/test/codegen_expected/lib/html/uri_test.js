dart_library.library('lib/html/uri_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__uri_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const uri_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  uri_test.main = function() {
    html_config.useHtmlConfiguration();
    unittest$.test('Uri.base', dart.fn(() => {
      src__matcher__expect.expect(core.Uri.base.scheme, "http");
      src__matcher__expect.expect(dart.toString(core.Uri.base), html.window[dartx.location][dartx.href]);
    }, VoidTodynamic()));
  };
  dart.fn(uri_test.main, VoidTodynamic());
  // Exports:
  exports.uri_test = uri_test;
});
