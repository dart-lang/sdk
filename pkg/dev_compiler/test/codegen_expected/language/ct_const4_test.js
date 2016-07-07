dart_library.library('language/ct_const4_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__ct_const4_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const ct_const4_test = Object.create(null);
  const ct_const4_lib = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  ct_const4_lib.B = 1;
  ct_const4_test.A = ct_const4_lib.B;
  ct_const4_test.main = function() {
    expect$.Expect.equals(1, ct_const4_test.A);
  };
  dart.fn(ct_const4_test.main, VoidTodynamic());
  // Exports:
  exports.ct_const4_test = ct_const4_test;
  exports.ct_const4_lib = ct_const4_lib;
});
