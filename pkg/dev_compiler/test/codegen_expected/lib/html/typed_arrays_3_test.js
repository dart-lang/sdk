dart_library.library('lib/html/typed_arrays_3_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__typed_arrays_3_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const typed_data = dart_sdk.typed_data;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const typed_arrays_3_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  typed_arrays_3_test.main = function() {
    html_config.useHtmlConfiguration();
    if (!dart.test(html.Platform.supportsTypedData)) {
      return;
    }
    unittest$.test('setElementsTest_dynamic', dart.fn(() => {
      let a1 = typed_data.Int8List.new(1024);
      a1[dartx.setRange](4, 7, JSArrayOfint().of([80, 96, 112]));
      let a2 = typed_data.Uint32List.view(a1[dartx.buffer]);
      src__matcher__expect.expect(a2[dartx.get](0), 0);
      src__matcher__expect.expect(a2[dartx.get](1), 7364688);
      a2[dartx.setRange](2, 3, JSArrayOfint().of([16909060]));
      src__matcher__expect.expect(a1[dartx.get](8), 4);
      src__matcher__expect.expect(a1[dartx.get](11), 1);
    }, VoidTodynamic()));
    unittest$.test('setElementsTest_typed', dart.fn(() => {
      let a1 = typed_data.Int8List.new(1024);
      a1[dartx.setRange](4, 7, JSArrayOfint().of([80, 96, 112]));
      let a2 = typed_data.Uint32List.view(a1[dartx.buffer]);
      src__matcher__expect.expect(a2[dartx.get](0), 0);
      src__matcher__expect.expect(a2[dartx.get](1), 7364688);
      a2[dartx.setRange](2, 3, JSArrayOfint().of([16909060]));
      src__matcher__expect.expect(a1[dartx.get](8), 4);
      src__matcher__expect.expect(a1[dartx.get](11), 1);
    }, VoidTodynamic()));
  };
  dart.fn(typed_arrays_3_test.main, VoidTodynamic());
  // Exports:
  exports.typed_arrays_3_test = typed_arrays_3_test;
});
