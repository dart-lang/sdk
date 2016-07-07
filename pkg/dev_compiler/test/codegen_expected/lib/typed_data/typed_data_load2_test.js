dart_library.library('lib/typed_data/typed_data_load2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__typed_data_load2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const typed_data_load2_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  typed_data_load2_test.aliasWithByteData1 = function() {
    let aa = typed_data.Int8List.new(10);
    let b = typed_data.ByteData.view(aa[dartx.buffer]);
    for (let i = 0; i < dart.notNull(aa[dartx.length]); i++)
      aa[dartx.set](i, 9);
    let x1 = aa[dartx.get](3);
    b[dartx.setInt8](3, 1);
    let x2 = aa[dartx.get](3);
    expect$.Expect.equals(9, x1);
    expect$.Expect.equals(1, x2);
  };
  dart.fn(typed_data_load2_test.aliasWithByteData1, VoidTodynamic());
  typed_data_load2_test.aliasWithByteData2 = function() {
    let b = typed_data.ByteData.new(10);
    let aa = typed_data.Int8List.view(b[dartx.buffer]);
    for (let i = 0; i < dart.notNull(aa[dartx.length]); i++)
      aa[dartx.set](i, 9);
    let x1 = aa[dartx.get](3);
    b[dartx.setInt8](3, 1);
    let x2 = aa[dartx.get](3);
    expect$.Expect.equals(9, x1);
    expect$.Expect.equals(1, x2);
  };
  dart.fn(typed_data_load2_test.aliasWithByteData2, VoidTodynamic());
  typed_data_load2_test.alias8x8 = function() {
    let buffer = typed_data.Int8List.new(10)[dartx.buffer];
    let a1 = typed_data.Int8List.view(buffer);
    let a2 = typed_data.Int8List.view(buffer, 1);
    for (let i = 0; i < dart.notNull(a1[dartx.length]); i++)
      a1[dartx.set](i, 9);
    let x1 = a1[dartx.get](1);
    a2[dartx.set](0, 0);
    let x2 = a1[dartx.get](1);
    expect$.Expect.equals(9, x1);
    expect$.Expect.equals(0, x2);
    for (let i = 0; i < dart.notNull(a1[dartx.length]); i++)
      a1[dartx.set](i, 9);
    x1 = a1[dartx.get](1);
    a2[dartx.set](1, 5);
    x2 = a1[dartx.get](1);
    expect$.Expect.equals(9, x1);
    expect$.Expect.equals(9, x2);
  };
  dart.fn(typed_data_load2_test.alias8x8, VoidTodynamic());
  typed_data_load2_test.alias8x16 = function() {
    let a1 = typed_data.Int8List.new(10);
    let a2 = typed_data.Int16List.view(a1[dartx.buffer]);
    for (let i = 0; i < dart.notNull(a1[dartx.length]); i++)
      a1[dartx.set](i, 9);
    let x1 = a1[dartx.get](0);
    a2[dartx.set](0, 257);
    let x2 = a1[dartx.get](0);
    expect$.Expect.equals(9, x1);
    expect$.Expect.equals(1, x2);
    for (let i = 0; i < dart.notNull(a1[dartx.length]); i++)
      a1[dartx.set](i, 9);
    x1 = a1[dartx.get](4);
    a2[dartx.set](2, 1285);
    x2 = a1[dartx.get](4);
    expect$.Expect.equals(9, x1);
    expect$.Expect.equals(5, x2);
    for (let i = 0; i < dart.notNull(a1[dartx.length]); i++)
      a1[dartx.set](i, 9);
    x1 = a1[dartx.get](3);
    a2[dartx.set](3, 1285);
    x2 = a1[dartx.get](3);
    expect$.Expect.equals(9, x1);
    expect$.Expect.equals(9, x2);
    for (let i = 0; i < dart.notNull(a1[dartx.length]); i++)
      a1[dartx.set](i, 9);
    x1 = a1[dartx.get](2);
    a2[dartx.set](0, 1285);
    x2 = a1[dartx.get](2);
    expect$.Expect.equals(9, x1);
    expect$.Expect.equals(9, x2);
  };
  dart.fn(typed_data_load2_test.alias8x16, VoidTodynamic());
  typed_data_load2_test.main = function() {
    typed_data_load2_test.aliasWithByteData1();
    typed_data_load2_test.aliasWithByteData2();
    typed_data_load2_test.alias8x8();
    typed_data_load2_test.alias8x16();
  };
  dart.fn(typed_data_load2_test.main, VoidTodynamic());
  // Exports:
  exports.typed_data_load2_test = typed_data_load2_test;
});
