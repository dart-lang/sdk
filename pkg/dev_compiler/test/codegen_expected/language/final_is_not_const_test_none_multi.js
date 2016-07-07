dart_library.library('language/final_is_not_const_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__final_is_not_const_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const final_is_not_const_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  final_is_not_const_test_none_multi.F0 = 42;
  final_is_not_const_test_none_multi.main = function() {
    expect$.Expect.equals(42, final_is_not_const_test_none_multi.F0);
  };
  dart.fn(final_is_not_const_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.final_is_not_const_test_none_multi = final_is_not_const_test_none_multi;
});
