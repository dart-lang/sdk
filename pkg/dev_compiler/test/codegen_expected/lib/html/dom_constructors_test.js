dart_library.library('lib/html/dom_constructors_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__dom_constructors_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const dom_constructors_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  dom_constructors_test.main = function() {
    html_config.useHtmlConfiguration();
    unittest$.test('FileReader', dart.fn(() => {
      let fileReader = html.FileReader.new();
      src__matcher__expect.expect(fileReader[dartx.readyState], src__matcher__core_matchers.equals(html.FileReader.EMPTY));
    }, VoidTodynamic()));
  };
  dart.fn(dom_constructors_test.main, VoidTodynamic());
  // Exports:
  exports.dom_constructors_test = dom_constructors_test;
});
