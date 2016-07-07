dart_library.library('language/if_null_evaluation_order_test_01_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__if_null_evaluation_order_test_01_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const if_null_evaluation_order_test_01_multi = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  if_null_evaluation_order_test_01_multi.bad = function() {
    dart.throw(core.Exception.new());
  };
  dart.fn(if_null_evaluation_order_test_01_multi.bad, VoidTovoid());
  if_null_evaluation_order_test_01_multi.firstExecuted = false;
  if_null_evaluation_order_test_01_multi.first = function() {
    if_null_evaluation_order_test_01_multi.firstExecuted = true;
    return null;
  };
  dart.fn(if_null_evaluation_order_test_01_multi.first, VoidTodynamic());
  if_null_evaluation_order_test_01_multi.second = function() {
    expect$.Expect.isTrue(if_null_evaluation_order_test_01_multi.firstExecuted);
    return 2;
  };
  dart.fn(if_null_evaluation_order_test_01_multi.second, VoidTodynamic());
  if_null_evaluation_order_test_01_multi.main = function() {
    let _ = (() => {
      let l = null;
      return l != null ? l : null;
    })();
    expect$.Expect.equals(1, 1);
  };
  dart.fn(if_null_evaluation_order_test_01_multi.main, VoidTodynamic());
  // Exports:
  exports.if_null_evaluation_order_test_01_multi = if_null_evaluation_order_test_01_multi;
});
