dart_library.library('language/ct_const3_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__ct_const3_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const ct_const3_test = Object.create(null);
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  ct_const3_test.O = 1 + 3;
  ct_const3_test.N = 1;
  ct_const3_test.P = 2 * (ct_const3_test.O - ct_const3_test.N);
  ct_const3_test.main = function() {
    expect$.Expect.equals(1, ct_const3_test.N);
    expect$.Expect.equals(4, ct_const3_test.O);
    expect$.Expect.equals(6, ct_const3_test.P);
  };
  dart.fn(ct_const3_test.main, VoidToint());
  // Exports:
  exports.ct_const3_test = ct_const3_test;
});
