dart_library.library('lib/typed_data/int32x4_arithmetic_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__int32x4_arithmetic_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const int32x4_arithmetic_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  int32x4_arithmetic_test.testAdd = function() {
    let m = typed_data.Int32x4.new(0, 0, 0, 0);
    let n = typed_data.Int32x4.new(-1, -1, -1, -1);
    let o = m['+'](n);
    expect$.Expect.equals(-1, o.x);
    expect$.Expect.equals(-1, o.y);
    expect$.Expect.equals(-1, o.z);
    expect$.Expect.equals(-1, o.w);
    m = typed_data.Int32x4.new(0, 0, 0, 0);
    n = typed_data.Int32x4.new(4294967295, 4294967295, 4294967295, 4294967295);
    o = m['+'](n);
    expect$.Expect.equals(-1, o.x);
    expect$.Expect.equals(-1, o.y);
    expect$.Expect.equals(-1, o.z);
    expect$.Expect.equals(-1, o.w);
    n = typed_data.Int32x4.new(1, 1, 1, 1);
    m = typed_data.Int32x4.new(4294967295, 4294967295, 4294967295, 4294967295);
    o = m['+'](n);
    expect$.Expect.equals(0, o.x);
    expect$.Expect.equals(0, o.y);
    expect$.Expect.equals(0, o.z);
    expect$.Expect.equals(0, o.w);
    n = typed_data.Int32x4.new(4294967295, 4294967295, 4294967295, 4294967295);
    m = typed_data.Int32x4.new(4294967295, 4294967295, 4294967295, 4294967295);
    o = m['+'](n);
    expect$.Expect.equals(-2, o.x);
    expect$.Expect.equals(-2, o.y);
    expect$.Expect.equals(-2, o.z);
    expect$.Expect.equals(-2, o.w);
    n = typed_data.Int32x4.new(1, 0, 0, 0);
    m = typed_data.Int32x4.new(2, 0, 0, 0);
    o = n['+'](m);
    expect$.Expect.equals(3, o.x);
    expect$.Expect.equals(0, o.y);
    expect$.Expect.equals(0, o.z);
    expect$.Expect.equals(0, o.w);
    n = typed_data.Int32x4.new(1, 3, 0, 0);
    m = typed_data.Int32x4.new(2, 4, 0, 0);
    o = n['+'](m);
    expect$.Expect.equals(3, o.x);
    expect$.Expect.equals(7, o.y);
    expect$.Expect.equals(0, o.z);
    expect$.Expect.equals(0, o.w);
    n = typed_data.Int32x4.new(1, 3, 5, 0);
    m = typed_data.Int32x4.new(2, 4, 6, 0);
    o = n['+'](m);
    expect$.Expect.equals(3, o.x);
    expect$.Expect.equals(7, o.y);
    expect$.Expect.equals(11, o.z);
    expect$.Expect.equals(0, o.w);
    n = typed_data.Int32x4.new(1, 3, 5, 7);
    m = typed_data.Int32x4.new(-2, -4, -6, -8);
    o = n['+'](m);
    expect$.Expect.equals(-1, o.x);
    expect$.Expect.equals(-1, o.y);
    expect$.Expect.equals(-1, o.z);
    expect$.Expect.equals(-1, o.w);
  };
  dart.fn(int32x4_arithmetic_test.testAdd, VoidTodynamic());
  int32x4_arithmetic_test.testSub = function() {
    let m = typed_data.Int32x4.new(0, 0, 0, 0);
    let n = typed_data.Int32x4.new(1, 1, 1, 1);
    let o = m['-'](n);
    expect$.Expect.equals(-1, o.x);
    expect$.Expect.equals(-1, o.y);
    expect$.Expect.equals(-1, o.z);
    expect$.Expect.equals(-1, o.w);
    o = n['-'](m);
    expect$.Expect.equals(1, o.x);
    expect$.Expect.equals(1, o.y);
    expect$.Expect.equals(1, o.z);
    expect$.Expect.equals(1, o.w);
  };
  dart.fn(int32x4_arithmetic_test.testSub, VoidTodynamic());
  int32x4_arithmetic_test.main = function() {
    for (let i = 0; i < 20; i++) {
      int32x4_arithmetic_test.testAdd();
      int32x4_arithmetic_test.testSub();
    }
  };
  dart.fn(int32x4_arithmetic_test.main, VoidTodynamic());
  // Exports:
  exports.int32x4_arithmetic_test = int32x4_arithmetic_test;
});
