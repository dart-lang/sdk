dart_library.library('language/rewrite_if_return_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__rewrite_if_return_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const rewrite_if_return_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  rewrite_if_return_test.global = 0;
  rewrite_if_return_test.bar = function() {
    rewrite_if_return_test.global = 1;
  };
  dart.fn(rewrite_if_return_test.bar, VoidTodynamic());
  rewrite_if_return_test.baz = function() {
    rewrite_if_return_test.global = 2;
  };
  dart.fn(rewrite_if_return_test.baz, VoidTodynamic());
  rewrite_if_return_test.return_const = function(b) {
    if (dart.test(b)) {
      rewrite_if_return_test.bar();
      return 1;
    } else {
      rewrite_if_return_test.baz();
      return 1;
    }
  };
  dart.fn(rewrite_if_return_test.return_const, dynamicTodynamic());
  rewrite_if_return_test.return_var = function(b, x) {
    if (dart.test(b)) {
      rewrite_if_return_test.bar();
      return x;
    } else {
      rewrite_if_return_test.baz();
      return x;
    }
  };
  dart.fn(rewrite_if_return_test.return_var, dynamicAnddynamicTodynamic());
  rewrite_if_return_test.main = function() {
    rewrite_if_return_test.return_const(true);
    expect$.Expect.equals(1, rewrite_if_return_test.global);
    rewrite_if_return_test.return_const(false);
    expect$.Expect.equals(2, rewrite_if_return_test.global);
    expect$.Expect.equals(4, rewrite_if_return_test.return_var(true, 4));
    expect$.Expect.equals(1, rewrite_if_return_test.global);
    expect$.Expect.equals(5, rewrite_if_return_test.return_var(false, 5));
    expect$.Expect.equals(2, rewrite_if_return_test.global);
  };
  dart.fn(rewrite_if_return_test.main, VoidTodynamic());
  // Exports:
  exports.rewrite_if_return_test = rewrite_if_return_test;
});
