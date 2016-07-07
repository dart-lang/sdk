dart_library.library('lib/html/typed_arrays_4_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__typed_arrays_4_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const typed_arrays_4_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  typed_arrays_4_test.main = function() {
    html_config.useHtmlConfiguration();
    if (!dart.test(html.Platform.supportsTypedData)) {
      return;
    }
    unittest$.test('indexOf_dynamic', dart.fn(() => {
      let a1 = typed_data.Uint8List.new(1024);
      for (let i = 0; i < dart.notNull(a1[dartx.length]); i++) {
        a1[dartx.set](i, i);
      }
      src__matcher__expect.expect(a1[dartx.indexOf](50), 50);
      src__matcher__expect.expect(a1[dartx.indexOf](50, 50), 50);
      src__matcher__expect.expect(a1[dartx.indexOf](50, 51), 256 + 50);
      src__matcher__expect.expect(a1[dartx.lastIndexOf](50), 768 + 50);
      src__matcher__expect.expect(a1[dartx.lastIndexOf](50, 768 + 50), 768 + 50);
      src__matcher__expect.expect(a1[dartx.lastIndexOf](50, 768 + 50 - 1), 512 + 50);
    }, VoidTodynamic()));
    unittest$.test('indexOf_typed', dart.fn(() => {
      let a1 = typed_data.Uint8List.new(1024);
      for (let i = 0; i < dart.notNull(a1[dartx.length]); i++) {
        a1[dartx.set](i, i);
      }
      src__matcher__expect.expect(a1[dartx.indexOf](50), 50);
      src__matcher__expect.expect(a1[dartx.indexOf](50, 50), 50);
      src__matcher__expect.expect(a1[dartx.indexOf](50, 51), 256 + 50);
      src__matcher__expect.expect(a1[dartx.lastIndexOf](50), 768 + 50);
      src__matcher__expect.expect(a1[dartx.lastIndexOf](50, 768 + 50), 768 + 50);
      src__matcher__expect.expect(a1[dartx.lastIndexOf](50, 768 + 50 - 1), 512 + 50);
    }, VoidTodynamic()));
  };
  dart.fn(typed_arrays_4_test.main, VoidTodynamic());
  // Exports:
  exports.typed_arrays_4_test = typed_arrays_4_test;
});
