dart_library.library('language/left_shift_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__left_shift_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const left_shift_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  left_shift_test.main = function() {
    for (let i = 0; i < 80; i++) {
      let a = (-1)[dartx['<<']](i);
      let b = -1;
      expect$.Expect.equals((1)[dartx['<<']](i), (a / b)[dartx.truncate]());
    }
  };
  dart.fn(left_shift_test.main, VoidTodynamic());
  // Exports:
  exports.left_shift_test = left_shift_test;
});
