dart_library.library('lib/html/b_element_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__b_element_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const b_element_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  b_element_test.main = function() {
    html_config.useHtmlConfiguration();
    unittest$.test('create b', dart.fn(() => {
      html.Element.tag('b');
    }, VoidTodynamic()));
  };
  dart.fn(b_element_test.main, VoidTodynamic());
  // Exports:
  exports.b_element_test = b_element_test;
});
