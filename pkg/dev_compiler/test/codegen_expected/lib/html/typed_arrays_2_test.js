dart_library.library('lib/html/typed_arrays_2_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__typed_arrays_2_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const typed_arrays_2_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  typed_arrays_2_test.main = function() {
    html_config.useHtmlConfiguration();
    if (!dart.test(html.Platform.supportsTypedData)) {
      return;
    }
    unittest$.test('viewTest_dynamic', dart.fn(() => {
      let a1 = typed_data.Uint8List.new(1024);
      for (let i = 0; i < dart.notNull(a1[dartx.length]); i++) {
        a1[dartx.set](i, i);
      }
      let a2 = typed_data.Uint32List.view(a1[dartx.buffer]);
      src__matcher__expect.expect((1024 / 4)[dartx.truncate](), a2[dartx.length]);
      src__matcher__expect.expect(a2[dartx.get](0), 50462976);
      src__matcher__expect.expect(a2[dartx.get](1), 117835012);
      src__matcher__expect.expect(a2[dartx.get](2), 185207048);
      src__matcher__expect.expect(a2[dartx.get](50), 3419064776);
      src__matcher__expect.expect(a2[dartx.get](51), 3486436812);
      src__matcher__expect.expect(a2[dartx.get](64), 50462976);
      a2 = typed_data.Uint32List.view(a1[dartx.buffer], 200);
      src__matcher__expect.expect(a2[dartx.length], ((1024 - 200) / 4)[dartx.truncate]());
      src__matcher__expect.expect(a2[dartx.get](0), 3419064776);
      src__matcher__expect.expect(a2[dartx.get](1), 3486436812);
      src__matcher__expect.expect(a2[dartx.get](14), 50462976);
      a2 = typed_data.Uint32List.view(a1[dartx.buffer], 456, 20);
      src__matcher__expect.expect(a2[dartx.length], 20);
      src__matcher__expect.expect(a2[dartx.get](0), 3419064776);
      src__matcher__expect.expect(a2[dartx.get](1), 3486436812);
      src__matcher__expect.expect(a2[dartx.get](14), 50462976);
      a2 = typed_data.Uint32List.view(a1[dartx.buffer], 456, 30);
      src__matcher__expect.expect(a2[dartx.length], 30);
      src__matcher__expect.expect(a2[dartx.get](0), 3419064776);
      src__matcher__expect.expect(a2[dartx.get](1), 3486436812);
      src__matcher__expect.expect(a2[dartx.get](14), 50462976);
    }, VoidTodynamic()));
    unittest$.test('viewTest_typed', dart.fn(() => {
      let a1 = typed_data.Uint8List.new(1024);
      for (let i = 0; i < dart.notNull(a1[dartx.length]); i++) {
        a1[dartx.set](i, i);
      }
      let a2 = typed_data.Uint32List.view(a1[dartx.buffer]);
      src__matcher__expect.expect(a2[dartx.length], (1024 / 4)[dartx.truncate]());
      src__matcher__expect.expect(a2[dartx.get](0), 50462976);
      src__matcher__expect.expect(a2[dartx.get](50), 3419064776);
      src__matcher__expect.expect(a2[dartx.get](51), 3486436812);
      src__matcher__expect.expect(a2[dartx.get](64), 50462976);
      a2 = typed_data.Uint32List.view(a1[dartx.buffer], 200);
      src__matcher__expect.expect(a2[dartx.length], ((1024 - 200) / 4)[dartx.truncate]());
      src__matcher__expect.expect(a2[dartx.get](0), 3419064776);
      src__matcher__expect.expect(a2[dartx.get](1), 3486436812);
      src__matcher__expect.expect(a2[dartx.get](14), 50462976);
      a2 = typed_data.Uint32List.view(a1[dartx.buffer], 456, 20);
      src__matcher__expect.expect(20, a2[dartx.length]);
      src__matcher__expect.expect(a2[dartx.get](0), 3419064776);
      src__matcher__expect.expect(a2[dartx.get](1), 3486436812);
      src__matcher__expect.expect(a2[dartx.get](14), 50462976);
      a2 = typed_data.Uint32List.view(a1[dartx.buffer], 456, 30);
      src__matcher__expect.expect(a2[dartx.length], 30);
      src__matcher__expect.expect(a2[dartx.get](0), 3419064776);
      src__matcher__expect.expect(a2[dartx.get](1), 3486436812);
      src__matcher__expect.expect(a2[dartx.get](14), 50462976);
    }, VoidTodynamic()));
  };
  dart.fn(typed_arrays_2_test.main, VoidTodynamic());
  // Exports:
  exports.typed_arrays_2_test = typed_arrays_2_test;
});
