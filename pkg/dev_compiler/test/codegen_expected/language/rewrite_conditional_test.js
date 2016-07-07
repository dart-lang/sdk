dart_library.library('language/rewrite_conditional_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__rewrite_conditional_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const rewrite_conditional_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicAnddynamicAnddynamicTodynamic = () => (dynamicAnddynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic])))();
  rewrite_conditional_test.global = 0;
  rewrite_conditional_test.bar = function() {
    rewrite_conditional_test.global = dart.notNull(rewrite_conditional_test.global) + 1;
  };
  dart.fn(rewrite_conditional_test.bar, VoidTodynamic());
  rewrite_conditional_test.baz = function() {
    rewrite_conditional_test.global = dart.notNull(rewrite_conditional_test.global) + 100;
  };
  dart.fn(rewrite_conditional_test.baz, VoidTodynamic());
  rewrite_conditional_test.foo = function(x, y, z) {
    if (dart.test((dart.test(x) ? false : true) ? y : z)) {
      rewrite_conditional_test.bar();
      rewrite_conditional_test.bar();
    } else {
      rewrite_conditional_test.baz();
      rewrite_conditional_test.baz();
    }
  };
  dart.fn(rewrite_conditional_test.foo, dynamicAnddynamicAnddynamicTodynamic());
  rewrite_conditional_test.foo2 = function(x, y, z) {
    return (dart.test(x) ? false : true) ? y : z;
  };
  dart.fn(rewrite_conditional_test.foo2, dynamicAnddynamicAnddynamicTodynamic());
  rewrite_conditional_test.foo3 = function(x, y, z) {
    if (dart.test(x) ? dart.test(z) ? false : true : dart.test(y) ? false : true) {
      rewrite_conditional_test.baz();
      rewrite_conditional_test.baz();
    } else {
      rewrite_conditional_test.bar();
      rewrite_conditional_test.bar();
    }
  };
  dart.fn(rewrite_conditional_test.foo3, dynamicAnddynamicAnddynamicTodynamic());
  rewrite_conditional_test.main = function() {
    rewrite_conditional_test.foo(true, true, true);
    expect$.Expect.equals(2, rewrite_conditional_test.global);
    rewrite_conditional_test.foo(true, true, false);
    expect$.Expect.equals(202, rewrite_conditional_test.global);
    rewrite_conditional_test.foo(true, false, true);
    expect$.Expect.equals(204, rewrite_conditional_test.global);
    rewrite_conditional_test.foo(true, false, false);
    expect$.Expect.equals(404, rewrite_conditional_test.global);
    rewrite_conditional_test.foo(false, true, true);
    expect$.Expect.equals(406, rewrite_conditional_test.global);
    rewrite_conditional_test.foo(false, true, false);
    expect$.Expect.equals(408, rewrite_conditional_test.global);
    rewrite_conditional_test.foo(false, false, true);
    expect$.Expect.equals(608, rewrite_conditional_test.global);
    rewrite_conditional_test.foo(false, false, false);
    expect$.Expect.equals(808, rewrite_conditional_test.global);
    expect$.Expect.equals(true, rewrite_conditional_test.foo2(true, true, true));
    expect$.Expect.equals(false, rewrite_conditional_test.foo2(true, true, false));
    expect$.Expect.equals(true, rewrite_conditional_test.foo2(true, false, true));
    expect$.Expect.equals(false, rewrite_conditional_test.foo2(true, false, false));
    expect$.Expect.equals(true, rewrite_conditional_test.foo2(false, true, true));
    expect$.Expect.equals(true, rewrite_conditional_test.foo2(false, true, false));
    expect$.Expect.equals(false, rewrite_conditional_test.foo2(false, false, true));
    expect$.Expect.equals(false, rewrite_conditional_test.foo2(false, false, false));
    rewrite_conditional_test.global = 0;
    rewrite_conditional_test.foo3(true, true, true);
    expect$.Expect.equals(2, rewrite_conditional_test.global);
    rewrite_conditional_test.foo3(true, true, false);
    expect$.Expect.equals(202, rewrite_conditional_test.global);
    rewrite_conditional_test.foo3(true, false, true);
    expect$.Expect.equals(204, rewrite_conditional_test.global);
    rewrite_conditional_test.foo3(true, false, false);
    expect$.Expect.equals(404, rewrite_conditional_test.global);
    rewrite_conditional_test.foo3(false, true, true);
    expect$.Expect.equals(406, rewrite_conditional_test.global);
    rewrite_conditional_test.foo3(false, true, false);
    expect$.Expect.equals(408, rewrite_conditional_test.global);
    rewrite_conditional_test.foo3(false, false, true);
    expect$.Expect.equals(608, rewrite_conditional_test.global);
    rewrite_conditional_test.foo3(false, false, false);
    expect$.Expect.equals(808, rewrite_conditional_test.global);
  };
  dart.fn(rewrite_conditional_test.main, VoidTodynamic());
  // Exports:
  exports.rewrite_conditional_test = rewrite_conditional_test;
});
