dart_library.library('language/rewrite_for_update_order_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__rewrite_for_update_order_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const rewrite_for_update_order_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  rewrite_for_update_order_test.counter = 0;
  rewrite_for_update_order_test.global = 0;
  rewrite_for_update_order_test.test = function() {
    rewrite_for_update_order_test.counter = dart.notNull(rewrite_for_update_order_test.counter) + 1;
    return dart.notNull(rewrite_for_update_order_test.counter) <= 2;
  };
  dart.fn(rewrite_for_update_order_test.test, VoidTodynamic());
  rewrite_for_update_order_test.first = function() {
    rewrite_for_update_order_test.global = dart.notNull(rewrite_for_update_order_test.global) + 1;
  };
  dart.fn(rewrite_for_update_order_test.first, VoidTodynamic());
  rewrite_for_update_order_test.second = function() {
    rewrite_for_update_order_test.global = dart.notNull(rewrite_for_update_order_test.global) * 2;
  };
  dart.fn(rewrite_for_update_order_test.second, VoidTodynamic());
  rewrite_for_update_order_test.foo = function() {
    while (dart.test(rewrite_for_update_order_test.test())) {
      rewrite_for_update_order_test.first();
      rewrite_for_update_order_test.second();
    }
  };
  dart.fn(rewrite_for_update_order_test.foo, VoidTodynamic());
  rewrite_for_update_order_test.main = function() {
    rewrite_for_update_order_test.foo();
    expect$.Expect.equals(6, rewrite_for_update_order_test.global);
  };
  dart.fn(rewrite_for_update_order_test.main, VoidTodynamic());
  // Exports:
  exports.rewrite_for_update_order_test = rewrite_for_update_order_test;
});
