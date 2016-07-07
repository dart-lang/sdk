dart_library.library('language/rewrite_if_swap_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__rewrite_if_swap_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const rewrite_if_swap_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  rewrite_if_swap_test.global = 0;
  rewrite_if_swap_test.bar = function() {
    rewrite_if_swap_test.global = dart.notNull(rewrite_if_swap_test.global) + 1;
  };
  dart.fn(rewrite_if_swap_test.bar, VoidTodynamic());
  rewrite_if_swap_test.baz = function() {
    rewrite_if_swap_test.global = dart.notNull(rewrite_if_swap_test.global) + 100;
  };
  dart.fn(rewrite_if_swap_test.baz, VoidTodynamic());
  rewrite_if_swap_test.foo = function(b) {
    let old_backend_was_used = null;
    if (dart.test(b) ? false : true) {
      rewrite_if_swap_test.bar();
      rewrite_if_swap_test.bar();
    } else {
      rewrite_if_swap_test.baz();
      rewrite_if_swap_test.baz();
    }
  };
  dart.fn(rewrite_if_swap_test.foo, dynamicTodynamic());
  rewrite_if_swap_test.main = function() {
    rewrite_if_swap_test.foo(true);
    expect$.Expect.equals(200, rewrite_if_swap_test.global);
    rewrite_if_swap_test.foo(false);
    expect$.Expect.equals(202, rewrite_if_swap_test.global);
  };
  dart.fn(rewrite_if_swap_test.main, VoidTodynamic());
  // Exports:
  exports.rewrite_if_swap_test = rewrite_if_swap_test;
});
