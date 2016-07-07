dart_library.library('lib/typed_data/byte_data_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__byte_data_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const byte_data_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  byte_data_test.main = function() {
    byte_data_test.testRegress10898();
  };
  dart.fn(byte_data_test.main, VoidTodynamic());
  byte_data_test.testRegress10898 = function() {
    let data = typed_data.ByteData.new(16);
    expect$.Expect.equals(16, data[dartx.lengthInBytes]);
    for (let i = 0; i < dart.notNull(data[dartx.lengthInBytes]); i++) {
      expect$.Expect.equals(0, data[dartx.getInt8](i));
      data[dartx.setInt8](i, 42 + i);
      expect$.Expect.equals(42 + i, data[dartx.getInt8](i));
    }
    let backing = typed_data.ByteData.new(16);
    let view = typed_data.ByteData.view(backing[dartx.buffer]);
    for (let i = 0; i < dart.notNull(view[dartx.lengthInBytes]); i++) {
      expect$.Expect.equals(0, view[dartx.getInt8](i));
      view[dartx.setInt8](i, 87 + i);
      expect$.Expect.equals(87 + i, view[dartx.getInt8](i));
    }
    view = typed_data.ByteData.view(backing[dartx.buffer], 4);
    expect$.Expect.equals(12, view[dartx.lengthInBytes]);
    for (let i = 0; i < dart.notNull(view[dartx.lengthInBytes]); i++) {
      expect$.Expect.equals(87 + i + 4, view[dartx.getInt8](i));
    }
    view = typed_data.ByteData.view(backing[dartx.buffer], 8, 4);
    expect$.Expect.equals(4, view[dartx.lengthInBytes]);
    for (let i = 0; i < dart.notNull(view[dartx.lengthInBytes]); i++) {
      expect$.Expect.equals(87 + i + 8, view[dartx.getInt8](i));
    }
  };
  dart.fn(byte_data_test.testRegress10898, VoidTodynamic());
  // Exports:
  exports.byte_data_test = byte_data_test;
});
