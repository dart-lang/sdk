dart_library.library('language/nan_identical_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__nan_identical_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const nan_identical_test = Object.create(null);
  let intTodouble = () => (intTodouble = dart.constFn(dart.definiteFunctionType(core.double, [core.int])))();
  let VoidTodouble = () => (VoidTodouble = dart.constFn(dart.definiteFunctionType(core.double, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  nan_identical_test.uint64toDouble = function(i) {
    let buffer = typed_data.Uint8List.new(8)[dartx.buffer];
    let bdata = typed_data.ByteData.view(buffer);
    bdata[dartx.setUint64](0, i);
    return bdata[dartx.getFloat64](0);
  };
  dart.fn(nan_identical_test.uint64toDouble, intTodouble());
  nan_identical_test.createOtherNAN = function() {
    return nan_identical_test.uint64toDouble((1)[dartx['<<']](64) - 2);
  };
  dart.fn(nan_identical_test.createOtherNAN, VoidTodouble());
  nan_identical_test.main = function() {
    let otherNAN = nan_identical_test.createOtherNAN();
    for (let i = 0; i < 100; i++) {
      expect$.Expect.isFalse(nan_identical_test.checkIdentical(core.double.NAN, -dart.notNull(core.double.NAN)));
      expect$.Expect.isTrue(nan_identical_test.checkIdentical(core.double.NAN, core.double.NAN));
      expect$.Expect.isTrue(nan_identical_test.checkIdentical(-dart.notNull(core.double.NAN), -dart.notNull(core.double.NAN)));
      expect$.Expect.isFalse(nan_identical_test.checkIdentical(otherNAN, -dart.notNull(otherNAN)));
      expect$.Expect.isTrue(nan_identical_test.checkIdentical(otherNAN, otherNAN));
      expect$.Expect.isTrue(nan_identical_test.checkIdentical(-dart.notNull(otherNAN), -dart.notNull(otherNAN)));
      let a = otherNAN;
      let b = core.double.NAN;
      expect$.Expect.isFalse(nan_identical_test.checkIdentical(a, b));
      expect$.Expect.isFalse(nan_identical_test.checkIdentical(-dart.notNull(a), -dart.notNull(b)));
      expect$.Expect.isFalse(nan_identical_test.checkIdentical(-dart.notNull(a), b));
      expect$.Expect.isFalse(nan_identical_test.checkIdentical(a, -dart.notNull(b)));
      a = -dart.notNull(a);
      expect$.Expect.isFalse(nan_identical_test.checkIdentical(a, b));
      expect$.Expect.isFalse(nan_identical_test.checkIdentical(-dart.notNull(a), -dart.notNull(b)));
      expect$.Expect.isFalse(nan_identical_test.checkIdentical(-dart.notNull(a), b));
      expect$.Expect.isFalse(nan_identical_test.checkIdentical(a, -dart.notNull(b)));
      expect$.Expect.isTrue(nan_identical_test.checkIdentical(- -dart.notNull(a), a));
      expect$.Expect.isTrue(nan_identical_test.checkIdentical(- -dart.notNull(b), b));
    }
  };
  dart.fn(nan_identical_test.main, VoidTodynamic());
  nan_identical_test.checkIdentical = function(a, b) {
    return core.identical(a, b);
  };
  dart.fn(nan_identical_test.checkIdentical, dynamicAnddynamicTodynamic());
  // Exports:
  exports.nan_identical_test = nan_identical_test;
});
