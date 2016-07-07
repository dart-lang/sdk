dart_library.library('language/for_without_condition_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__for_without_condition_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const for_without_condition_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  for_without_condition_test.main = function() {
    let i = 0;
    for (;; i++) {
      if (i == 0) break;
      expect$.Expect.fail("Should not enter here");
    }
    expect$.Expect.equals(0, i);
  };
  dart.fn(for_without_condition_test.main, VoidTodynamic());
  // Exports:
  exports.for_without_condition_test = for_without_condition_test;
});
