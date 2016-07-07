dart_library.library('lib/html/typed_arrays_dataview_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__typed_arrays_dataview_test(exports, dart_sdk, unittest) {
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
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const typed_arrays_dataview_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  typed_arrays_dataview_test.main = function() {
    html_config.useHtmlConfiguration();
    if (!dart.test(html.Platform.supportsTypedData)) {
      return;
    }
    unittest$.test('create', dart.fn(() => {
      let bd = typed_data.ByteData.new(100);
      src__matcher__expect.expect(bd[dartx.lengthInBytes], 100);
      src__matcher__expect.expect(bd[dartx.offsetInBytes], 0);
      let a1 = typed_data.Uint8List.fromList(JSArrayOfint().of([1, 2, 3, 4, 5, 6, 7, 8]));
      let bd2 = typed_data.ByteData.view(a1[dartx.buffer]);
      src__matcher__expect.expect(bd2[dartx.lengthInBytes], 8);
      src__matcher__expect.expect(bd2[dartx.offsetInBytes], 0);
      let bd3 = typed_data.ByteData.view(a1[dartx.buffer], 2);
      src__matcher__expect.expect(bd3[dartx.lengthInBytes], 6);
      src__matcher__expect.expect(bd3[dartx.offsetInBytes], 2);
      let bd4 = typed_data.ByteData.view(a1[dartx.buffer], 3, 4);
      src__matcher__expect.expect(bd4[dartx.lengthInBytes], 4);
      src__matcher__expect.expect(bd4[dartx.offsetInBytes], 3);
    }, VoidTodynamic()));
    unittest$.test('access8', dart.fn(() => {
      let a1 = typed_data.Uint8List.fromList(JSArrayOfint().of([0, 0, 3, 255, 0, 0, 0, 0, 0, 0]));
      let bd = typed_data.ByteData.view(a1[dartx.buffer], 2, 6);
      src__matcher__expect.expect(bd[dartx.getInt8](0), src__matcher__core_matchers.equals(3));
      src__matcher__expect.expect(bd[dartx.getInt8](1), src__matcher__core_matchers.equals(-1));
      src__matcher__expect.expect(bd[dartx.getUint8](0), src__matcher__core_matchers.equals(3));
      src__matcher__expect.expect(bd[dartx.getUint8](1), src__matcher__core_matchers.equals(255));
      bd[dartx.setInt8](2, -56);
      src__matcher__expect.expect(bd[dartx.getInt8](2), src__matcher__core_matchers.equals(-56));
      src__matcher__expect.expect(bd[dartx.getUint8](2), src__matcher__core_matchers.equals(200));
      bd[dartx.setUint8](3, 200);
      src__matcher__expect.expect(bd[dartx.getInt8](3), src__matcher__core_matchers.equals(-56));
      src__matcher__expect.expect(bd[dartx.getUint8](3), src__matcher__core_matchers.equals(200));
    }, VoidTodynamic()));
    unittest$.test('access16', dart.fn(() => {
      let a1 = typed_data.Uint8List.fromList(JSArrayOfint().of([0, 0, 3, 255, 0, 0, 0, 0, 0, 0]));
      let bd = typed_data.ByteData.view(a1[dartx.buffer], 2);
      src__matcher__expect.expect(bd[dartx.lengthInBytes], src__matcher__core_matchers.equals(10 - 2));
      src__matcher__expect.expect(bd[dartx.getInt16](0), src__matcher__core_matchers.equals(1023));
      src__matcher__expect.expect(bd[dartx.getInt16](0, typed_data.Endianness.BIG_ENDIAN), src__matcher__core_matchers.equals(1023));
      src__matcher__expect.expect(bd[dartx.getInt16](0, typed_data.Endianness.LITTLE_ENDIAN), src__matcher__core_matchers.equals(-253));
      src__matcher__expect.expect(bd[dartx.getUint16](0), src__matcher__core_matchers.equals(1023));
      src__matcher__expect.expect(bd[dartx.getUint16](0, typed_data.Endianness.BIG_ENDIAN), src__matcher__core_matchers.equals(1023));
      src__matcher__expect.expect(bd[dartx.getUint16](0, typed_data.Endianness.LITTLE_ENDIAN), src__matcher__core_matchers.equals(65283));
      bd[dartx.setInt16](2, -1);
      src__matcher__expect.expect(bd[dartx.getInt16](2), src__matcher__core_matchers.equals(-1));
      src__matcher__expect.expect(bd[dartx.getUint16](2), src__matcher__core_matchers.equals(65535));
    }, VoidTodynamic()));
    unittest$.test('access32', dart.fn(() => {
      let a1 = typed_data.Uint8List.fromList(JSArrayOfint().of([0, 0, 3, 255, 0, 0, 0, 0, 0, 0]));
      let bd = typed_data.ByteData.view(a1[dartx.buffer]);
      src__matcher__expect.expect(bd[dartx.getInt32](0), src__matcher__core_matchers.equals(1023));
      src__matcher__expect.expect(bd[dartx.getInt32](0, typed_data.Endianness.BIG_ENDIAN), src__matcher__core_matchers.equals(1023));
      src__matcher__expect.expect(bd[dartx.getInt32](0, typed_data.Endianness.LITTLE_ENDIAN), src__matcher__core_matchers.equals(-16580608));
      src__matcher__expect.expect(bd[dartx.getUint32](0), src__matcher__core_matchers.equals(1023));
      src__matcher__expect.expect(bd[dartx.getUint32](0, typed_data.Endianness.BIG_ENDIAN), src__matcher__core_matchers.equals(1023));
      src__matcher__expect.expect(bd[dartx.getUint32](0, typed_data.Endianness.LITTLE_ENDIAN), src__matcher__core_matchers.equals(4278386688));
    }, VoidTodynamic()));
  };
  dart.fn(typed_arrays_dataview_test.main, VoidTodynamic());
  // Exports:
  exports.typed_arrays_dataview_test = typed_arrays_dataview_test;
});
