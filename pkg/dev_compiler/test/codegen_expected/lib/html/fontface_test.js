dart_library.library('lib/html/fontface_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__fontface_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const fontface_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  fontface_test.main = function() {
    html_config.useHtmlConfiguration();
    unittest$.test("Creation with parameters", dart.fn(() => {
      let font = html.FontFace.new('Ahem', 'url(Ahem.ttf)', dart.map({variant: 'small-caps'}));
      src__matcher__expect.expect(html.FontFace.is(font), src__matcher__core_matchers.isTrue);
      src__matcher__expect.expect(font[dartx.family], 'Ahem');
      src__matcher__expect.expect(font[dartx.variant], 'small-caps');
    }, VoidTodynamic()));
  };
  dart.fn(fontface_test.main, VoidTodynamic());
  // Exports:
  exports.fontface_test = fontface_test;
});
