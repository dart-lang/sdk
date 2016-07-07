dart_library.library('lib/typed_data/int32x4_bigint_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__int32x4_bigint_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const typed_data = dart_sdk.typed_data;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const int32x4_bigint_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  int32x4_bigint_test.main = function() {
    let n = 18446744073709551617;
    let x = typed_data.Int32x4.new(n, 0, 0, 0);
    expect$.Expect.equals(x.x, 1);
  };
  dart.fn(int32x4_bigint_test.main, VoidTodynamic());
  // Exports:
  exports.int32x4_bigint_test = int32x4_bigint_test;
});
