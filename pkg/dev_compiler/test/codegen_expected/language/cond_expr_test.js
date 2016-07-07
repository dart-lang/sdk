dart_library.library('language/cond_expr_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__cond_expr_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const cond_expr_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  cond_expr_test.e1 = null;
  cond_expr_test.e2 = null;
  cond_expr_test.f = function(a) {
    return dart.test(dart.dsend(a, '<', 0)) ? cond_expr_test.e1 = -1 : cond_expr_test.e2 = 1;
  };
  dart.fn(cond_expr_test.f, dynamicTodynamic());
  cond_expr_test.main = function() {
    cond_expr_test.e1 = 0;
    cond_expr_test.e2 = 0;
    let r = cond_expr_test.f(-100);
    expect$.Expect.equals(-1, r);
    expect$.Expect.equals(-1, cond_expr_test.e1);
    expect$.Expect.equals(0, cond_expr_test.e2);
    cond_expr_test.e1 = 0;
    cond_expr_test.e2 = 0;
    r = cond_expr_test.f(100);
    expect$.Expect.equals(1, r);
    expect$.Expect.equals(0, cond_expr_test.e1);
    expect$.Expect.equals(1, cond_expr_test.e2);
  };
  dart.fn(cond_expr_test.main, VoidTodynamic());
  // Exports:
  exports.cond_expr_test = cond_expr_test;
});
