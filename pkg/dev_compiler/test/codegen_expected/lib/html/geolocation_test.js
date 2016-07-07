dart_library.library('lib/html/geolocation_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__geolocation_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const geolocation_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  geolocation_test.main = function() {
    html_config.useHtmlConfiguration();
    unittest$.test('is not null', dart.fn(() => {
      src__matcher__expect.expect(html.window[dartx.navigator][dartx.geolocation], src__matcher__core_matchers.isNotNull);
    }, VoidTodynamic()));
  };
  dart.fn(geolocation_test.main, VoidTodynamic());
  // Exports:
  exports.geolocation_test = geolocation_test;
});
