dart_library.library('lib/typed_data/float32x4_two_arg_shuffle_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__float32x4_two_arg_shuffle_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const float32x4_two_arg_shuffle_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  float32x4_two_arg_shuffle_test.testWithZWInXY = function() {
    let a = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let b = typed_data.Float32x4.new(5.0, 6.0, 7.0, 8.0);
    let c = b.shuffleMix(a, typed_data.Float32x4.ZWZW);
    expect$.Expect.equals(7.0, c.x);
    expect$.Expect.equals(8.0, c.y);
    expect$.Expect.equals(3.0, c.z);
    expect$.Expect.equals(4.0, c.w);
  };
  dart.fn(float32x4_two_arg_shuffle_test.testWithZWInXY, VoidTodynamic());
  float32x4_two_arg_shuffle_test.testInterleaveXY = function() {
    let a = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let b = typed_data.Float32x4.new(5.0, 6.0, 7.0, 8.0);
    let c = a.shuffleMix(b, typed_data.Float32x4.XYXY).shuffle(typed_data.Float32x4.XZYW);
    expect$.Expect.equals(1.0, c.x);
    expect$.Expect.equals(5.0, c.y);
    expect$.Expect.equals(2.0, c.z);
    expect$.Expect.equals(6.0, c.w);
  };
  dart.fn(float32x4_two_arg_shuffle_test.testInterleaveXY, VoidTodynamic());
  float32x4_two_arg_shuffle_test.testInterleaveZW = function() {
    let a = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let b = typed_data.Float32x4.new(5.0, 6.0, 7.0, 8.0);
    let c = a.shuffleMix(b, typed_data.Float32x4.ZWZW).shuffle(typed_data.Float32x4.XZYW);
    expect$.Expect.equals(3.0, c.x);
    expect$.Expect.equals(7.0, c.y);
    expect$.Expect.equals(4.0, c.z);
    expect$.Expect.equals(8.0, c.w);
  };
  dart.fn(float32x4_two_arg_shuffle_test.testInterleaveZW, VoidTodynamic());
  float32x4_two_arg_shuffle_test.testInterleaveXYPairs = function() {
    let a = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let b = typed_data.Float32x4.new(5.0, 6.0, 7.0, 8.0);
    let c = a.shuffleMix(b, typed_data.Float32x4.XYXY);
    expect$.Expect.equals(1.0, c.x);
    expect$.Expect.equals(2.0, c.y);
    expect$.Expect.equals(5.0, c.z);
    expect$.Expect.equals(6.0, c.w);
  };
  dart.fn(float32x4_two_arg_shuffle_test.testInterleaveXYPairs, VoidTodynamic());
  float32x4_two_arg_shuffle_test.testInterleaveZWPairs = function() {
    let a = typed_data.Float32x4.new(1.0, 2.0, 3.0, 4.0);
    let b = typed_data.Float32x4.new(5.0, 6.0, 7.0, 8.0);
    let c = a.shuffleMix(b, typed_data.Float32x4.ZWZW);
    expect$.Expect.equals(3.0, c.x);
    expect$.Expect.equals(4.0, c.y);
    expect$.Expect.equals(7.0, c.z);
    expect$.Expect.equals(8.0, c.w);
  };
  dart.fn(float32x4_two_arg_shuffle_test.testInterleaveZWPairs, VoidTodynamic());
  float32x4_two_arg_shuffle_test.main = function() {
    for (let i = 0; i < 20; i++) {
      float32x4_two_arg_shuffle_test.testWithZWInXY();
      float32x4_two_arg_shuffle_test.testInterleaveXY();
      float32x4_two_arg_shuffle_test.testInterleaveZW();
      float32x4_two_arg_shuffle_test.testInterleaveXYPairs();
      float32x4_two_arg_shuffle_test.testInterleaveZWPairs();
    }
  };
  dart.fn(float32x4_two_arg_shuffle_test.main, VoidTodynamic());
  // Exports:
  exports.float32x4_two_arg_shuffle_test = float32x4_two_arg_shuffle_test;
});
