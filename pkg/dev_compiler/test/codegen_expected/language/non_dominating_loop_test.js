dart_library.library('language/non_dominating_loop_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__non_dominating_loop_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const non_dominating_loop_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  non_dominating_loop_test.calls = 0;
  non_dominating_loop_test.callMeOnce = function() {
    expect$.Expect.equals(0, non_dominating_loop_test.calls);
    non_dominating_loop_test.calls = dart.notNull(non_dominating_loop_test.calls) + 1;
  };
  dart.fn(non_dominating_loop_test.callMeOnce, VoidTovoid());
  non_dominating_loop_test.main = function() {
    let i = 0;
    do {
      i++;
      if (i > 3) break;
    } while (i < 10);
    non_dominating_loop_test.callMeOnce();
    expect$.Expect.equals(4, i);
  };
  dart.fn(non_dominating_loop_test.main, VoidTodynamic());
  // Exports:
  exports.non_dominating_loop_test = non_dominating_loop_test;
});
