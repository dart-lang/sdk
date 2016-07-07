dart_library.library('language/rewrite_if_empty_then_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__rewrite_if_empty_then_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const rewrite_if_empty_then_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  rewrite_if_empty_then_test.global = 0;
  rewrite_if_empty_then_test.effect = function() {
    rewrite_if_empty_then_test.global = 1;
  };
  dart.fn(rewrite_if_empty_then_test.effect, VoidTodynamic());
  rewrite_if_empty_then_test.baz = function(b) {
    return b;
  };
  dart.fn(rewrite_if_empty_then_test.baz, dynamicTodynamic());
  rewrite_if_empty_then_test.foo = function(b) {
    if (dart.test(b)) {
    } else {
      rewrite_if_empty_then_test.effect();
    }
    return rewrite_if_empty_then_test.baz(b);
  };
  dart.fn(rewrite_if_empty_then_test.foo, dynamicTodynamic());
  rewrite_if_empty_then_test.foo2 = function(b) {
    if (dart.test(b)) {
    } else {
      rewrite_if_empty_then_test.effect();
    }
  };
  dart.fn(rewrite_if_empty_then_test.foo2, dynamicTodynamic());
  rewrite_if_empty_then_test.main = function() {
    rewrite_if_empty_then_test.global = 0;
    expect$.Expect.equals(true, rewrite_if_empty_then_test.foo(true));
    expect$.Expect.equals(0, rewrite_if_empty_then_test.global);
    rewrite_if_empty_then_test.global = 0;
    expect$.Expect.equals(false, rewrite_if_empty_then_test.foo(false));
    expect$.Expect.equals(1, rewrite_if_empty_then_test.global);
    rewrite_if_empty_then_test.global = 0;
    rewrite_if_empty_then_test.foo2(true);
    expect$.Expect.equals(0, rewrite_if_empty_then_test.global);
    rewrite_if_empty_then_test.global = 0;
    rewrite_if_empty_then_test.foo2(false);
    expect$.Expect.equals(1, rewrite_if_empty_then_test.global);
  };
  dart.fn(rewrite_if_empty_then_test.main, VoidTodynamic());
  // Exports:
  exports.rewrite_if_empty_then_test = rewrite_if_empty_then_test;
});
