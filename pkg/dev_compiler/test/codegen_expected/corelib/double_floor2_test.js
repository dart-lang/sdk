dart_library.library('corelib/double_floor2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__double_floor2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const double_floor2_test = Object.create(null);
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  double_floor2_test.main = function() {
    expect$.Expect.throws(dart.fn(() => core.double.INFINITY[dartx.floor](), VoidToint()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => core.double.NEGATIVE_INFINITY[dartx.floor](), VoidToint()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => core.double.NAN[dartx.floor](), VoidToint()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
  };
  dart.fn(double_floor2_test.main, VoidTodynamic());
  // Exports:
  exports.double_floor2_test = double_floor2_test;
});
