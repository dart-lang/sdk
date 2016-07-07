dart_library.library('language/rewrite_while_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__rewrite_while_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const rewrite_while_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  rewrite_while_test.baz = function() {
  };
  dart.fn(rewrite_while_test.baz, VoidTodynamic());
  rewrite_while_test.loop1 = function(x) {
    let n = 0;
    while (n < dart.notNull(core.num._check(x))) {
      n = n + 1;
    }
    return n;
  };
  dart.fn(rewrite_while_test.loop1, dynamicTodynamic());
  rewrite_while_test.loop2 = function(x) {
    let n = 0;
    if (dart.test(dart.dsend(x, '<', 100))) {
      while (n < dart.notNull(core.num._check(x))) {
        n = n + 1;
      }
    }
    rewrite_while_test.baz();
    return n;
  };
  dart.fn(rewrite_while_test.loop2, dynamicTodynamic());
  rewrite_while_test.loop3 = function(x) {
    let n = 0;
    if (dart.test(dart.dsend(x, '<', 100))) {
      while (n < dart.notNull(core.num._check(x))) {
        n = n + 1;
        rewrite_while_test.baz();
      }
    }
    rewrite_while_test.baz();
    return n;
  };
  dart.fn(rewrite_while_test.loop3, dynamicTodynamic());
  rewrite_while_test.loop4 = function(x) {
    let n = 0;
    if (dart.test(dart.dsend(x, '<', 100))) {
      while (n < dart.notNull(core.num._check(x))) {
        rewrite_while_test.baz();
        n = n + 1;
      }
    }
    rewrite_while_test.baz();
    return n;
  };
  dart.fn(rewrite_while_test.loop4, dynamicTodynamic());
  rewrite_while_test.f1 = function(b) {
    while (dart.test(b))
      return 1;
    return 2;
  };
  dart.fn(rewrite_while_test.f1, dynamicTodynamic());
  rewrite_while_test.f2 = function(b) {
    while (dart.test(b)) {
      return 1;
    }
    return 2;
  };
  dart.fn(rewrite_while_test.f2, dynamicTodynamic());
  rewrite_while_test.main = function() {
    expect$.Expect.equals(0, rewrite_while_test.loop1(-10));
    expect$.Expect.equals(10, rewrite_while_test.loop1(10));
    expect$.Expect.equals(0, rewrite_while_test.loop2(-10));
    expect$.Expect.equals(10, rewrite_while_test.loop2(10));
    expect$.Expect.equals(0, rewrite_while_test.loop2(200));
    expect$.Expect.equals(0, rewrite_while_test.loop3(-10));
    expect$.Expect.equals(10, rewrite_while_test.loop3(10));
    expect$.Expect.equals(0, rewrite_while_test.loop3(200));
    expect$.Expect.equals(0, rewrite_while_test.loop4(-10));
    expect$.Expect.equals(10, rewrite_while_test.loop4(10));
    expect$.Expect.equals(0, rewrite_while_test.loop4(200));
    expect$.Expect.equals(1, rewrite_while_test.f1(true));
    expect$.Expect.equals(2, rewrite_while_test.f1(false));
    expect$.Expect.equals(1, rewrite_while_test.f2(true));
    expect$.Expect.equals(2, rewrite_while_test.f2(false));
  };
  dart.fn(rewrite_while_test.main, VoidTodynamic());
  // Exports:
  exports.rewrite_while_test = rewrite_while_test;
});
