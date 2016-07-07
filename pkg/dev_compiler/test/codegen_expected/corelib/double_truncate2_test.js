dart_library.library('corelib/double_truncate2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__double_truncate2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const double_truncate2_test = Object.create(null);
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  double_truncate2_test.main = function() {
    expect$.Expect.throws(dart.fn(() => core.double.INFINITY[dartx.truncate](), VoidToint()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => core.double.NEGATIVE_INFINITY[dartx.truncate](), VoidToint()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => core.double.NAN[dartx.truncate](), VoidToint()), dart.fn(e => core.UnsupportedError.is(e), dynamicTobool()));
  };
  dart.fn(double_truncate2_test.main, VoidTodynamic());
  // Exports:
  exports.double_truncate2_test = double_truncate2_test;
});
