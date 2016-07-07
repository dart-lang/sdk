dart_library.library('language/rewrite_swap_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__rewrite_swap_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const rewrite_swap_test = Object.create(null);
  let dynamicAnddynamicAnddynamicTodynamic = () => (dynamicAnddynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic])))();
  let dynamicAnddynamicAnddynamic__Todynamic = () => (dynamicAnddynamicAnddynamic__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic])))();
  let dynamicAnddynamicAnddynamic__Todynamic$ = () => (dynamicAnddynamicAnddynamic__Todynamic$ = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic])))();
  let dynamicAnddynamicAnddynamic__Todynamic$0 = () => (dynamicAnddynamicAnddynamic__Todynamic$0 = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  rewrite_swap_test.swap1 = function(x, y, b) {
    if (dart.test(b)) {
      let t = x;
      x = y;
      y = t;
    }
    expect$.Expect.equals(2, x);
    expect$.Expect.equals(1, y);
  };
  dart.fn(rewrite_swap_test.swap1, dynamicAnddynamicAnddynamicTodynamic());
  rewrite_swap_test.swap2 = function(x, y, z, w, b) {
    if (dart.test(b)) {
      let t = x;
      x = y;
      y = t;
      let q = z;
      z = w;
      w = q;
    }
    expect$.Expect.equals(2, x);
    expect$.Expect.equals(1, y);
    expect$.Expect.equals(4, z);
    expect$.Expect.equals(3, w);
  };
  dart.fn(rewrite_swap_test.swap2, dynamicAnddynamicAnddynamic__Todynamic());
  rewrite_swap_test.swap3 = function(x, y, z, b) {
    if (dart.test(b)) {
      let t = x;
      x = y;
      y = z;
      z = t;
    }
    expect$.Expect.equals(2, x);
    expect$.Expect.equals(3, y);
    expect$.Expect.equals(1, z);
  };
  dart.fn(rewrite_swap_test.swap3, dynamicAnddynamicAnddynamic__Todynamic$());
  rewrite_swap_test.swap4 = function(x, y, z, b) {
    if (dart.test(b)) {
      let t = x;
      x = y;
      y = z;
      z = t;
    }
    expect$.Expect.equals(2, x);
    expect$.Expect.equals(1, z);
  };
  dart.fn(rewrite_swap_test.swap4, dynamicAnddynamicAnddynamic__Todynamic$());
  rewrite_swap_test.swap5 = function(x, y, z, w, b, b2) {
    if (dart.test(b)) {
      let t = x;
      x = y;
      y = t;
    }
    if (dart.test(b2)) {
      let q = z;
      z = w;
      w = q;
    }
    expect$.Expect.equals(2, x);
    expect$.Expect.equals(1, y);
    expect$.Expect.equals(4, z);
    expect$.Expect.equals(3, w);
  };
  dart.fn(rewrite_swap_test.swap5, dynamicAnddynamicAnddynamic__Todynamic$0());
  rewrite_swap_test.main = function() {
    rewrite_swap_test.swap1(1, 2, true);
    rewrite_swap_test.swap1(2, 1, false);
    rewrite_swap_test.swap2(1, 2, 3, 4, true);
    rewrite_swap_test.swap2(2, 1, 4, 3, false);
    rewrite_swap_test.swap3(1, 2, 3, true);
    rewrite_swap_test.swap3(2, 3, 1, false);
    rewrite_swap_test.swap4(1, 2, 3, true);
    rewrite_swap_test.swap4(2, 3, 1, false);
    rewrite_swap_test.swap5(1, 2, 3, 4, true, true);
    rewrite_swap_test.swap5(1, 2, 4, 3, true, false);
    rewrite_swap_test.swap5(2, 1, 3, 4, false, true);
    rewrite_swap_test.swap5(2, 1, 4, 3, false, false);
  };
  dart.fn(rewrite_swap_test.main, VoidTodynamic());
  // Exports:
  exports.rewrite_swap_test = rewrite_swap_test;
});
