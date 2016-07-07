dart_library.library('lib/typed_data/endianness_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__endianness_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const endianness_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  endianness_test.main = function() {
    endianness_test.swapTest();
    endianness_test.swapTestVar(typed_data.Endianness.LITTLE_ENDIAN, typed_data.Endianness.BIG_ENDIAN);
    endianness_test.swapTestVar(typed_data.Endianness.BIG_ENDIAN, typed_data.Endianness.LITTLE_ENDIAN);
  };
  dart.fn(endianness_test.main, VoidTodynamic());
  endianness_test.swapTest = function() {
    let data = typed_data.ByteData.new(16);
    expect$.Expect.equals(16, data[dartx.lengthInBytes]);
    for (let i = 0; i < 4; i++) {
      data[dartx.setInt32](i * 4, i);
    }
    for (let i = 0; i < dart.notNull(data[dartx.lengthInBytes]); i = i + 4) {
      let e = data[dartx.getInt32](i, typed_data.Endianness.BIG_ENDIAN);
      data[dartx.setInt32](i, e, typed_data.Endianness.LITTLE_ENDIAN);
    }
    expect$.Expect.equals(33554432, data[dartx.getInt32](8));
    for (let i = 0; i < dart.notNull(data[dartx.lengthInBytes]); i = i + 2) {
      let e = data[dartx.getInt16](i, typed_data.Endianness.BIG_ENDIAN);
      data[dartx.setInt16](i, e, typed_data.Endianness.LITTLE_ENDIAN);
    }
    expect$.Expect.equals(131072, data[dartx.getInt32](8));
    for (let i = 0; i < dart.notNull(data[dartx.lengthInBytes]); i = i + 4) {
      let e = data[dartx.getUint32](i, typed_data.Endianness.LITTLE_ENDIAN);
      data[dartx.setUint32](i, e, typed_data.Endianness.BIG_ENDIAN);
    }
    expect$.Expect.equals(512, data[dartx.getInt32](8));
    for (let i = 0; i < dart.notNull(data[dartx.lengthInBytes]); i = i + 2) {
      let e = data[dartx.getUint16](i, typed_data.Endianness.LITTLE_ENDIAN);
      data[dartx.setUint16](i, e, typed_data.Endianness.BIG_ENDIAN);
    }
    expect$.Expect.equals(2, data[dartx.getInt32](8));
  };
  dart.fn(endianness_test.swapTest, VoidTodynamic());
  endianness_test.swapTestVar = function(read, write) {
    let data = typed_data.ByteData.new(16);
    expect$.Expect.equals(16, data[dartx.lengthInBytes]);
    for (let i = 0; i < 4; i++) {
      data[dartx.setInt32](i * 4, i);
    }
    for (let i = 0; i < dart.notNull(data[dartx.lengthInBytes]); i = i + 4) {
      let e = data[dartx.getInt32](i, typed_data.Endianness._check(read));
      data[dartx.setInt32](i, e, typed_data.Endianness._check(write));
    }
    expect$.Expect.equals(33554432, data[dartx.getInt32](8));
    for (let i = 0; i < dart.notNull(data[dartx.lengthInBytes]); i = i + 2) {
      let e = data[dartx.getInt16](i, typed_data.Endianness._check(read));
      data[dartx.setInt16](i, e, typed_data.Endianness._check(write));
    }
    expect$.Expect.equals(131072, data[dartx.getInt32](8));
    for (let i = 0; i < dart.notNull(data[dartx.lengthInBytes]); i = i + 4) {
      let e = data[dartx.getUint32](i, typed_data.Endianness._check(read));
      data[dartx.setUint32](i, e, typed_data.Endianness._check(write));
    }
    expect$.Expect.equals(512, data[dartx.getInt32](8));
    for (let i = 0; i < dart.notNull(data[dartx.lengthInBytes]); i = i + 2) {
      let e = data[dartx.getUint16](i, typed_data.Endianness._check(read));
      data[dartx.setUint16](i, e, typed_data.Endianness._check(write));
    }
    expect$.Expect.equals(2, data[dartx.getInt32](8));
  };
  dart.fn(endianness_test.swapTestVar, dynamicAnddynamicTodynamic());
  // Exports:
  exports.endianness_test = endianness_test;
});
