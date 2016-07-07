dart_library.library('language/for_inlining_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__for_inlining_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const for_inlining_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  for_inlining_test.global = null;
  for_inlining_test.inlineMe = function() {
    for_inlining_test.global = 42;
    return 54;
  };
  dart.fn(for_inlining_test.inlineMe, VoidTodynamic());
  for_inlining_test.main = function() {
    for (let t = for_inlining_test.inlineMe(); dart.test(dart.dsend(t, '<', 42)); t = dart.dsend(t, '+', 1)) {
    }
    expect$.Expect.equals(42, for_inlining_test.global);
  };
  dart.fn(for_inlining_test.main, VoidTodynamic());
  // Exports:
  exports.for_inlining_test = for_inlining_test;
});
