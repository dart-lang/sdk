dart_library.library('language/range_analysis_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__range_analysis_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const range_analysis_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  range_analysis_test.bar = function() {
    let sum = 0;
    for (let i = 0; i < 10; i++) {
      for (let j = i - 1; j >= 0; j--) {
        for (let k = j; k < i; k++) {
          sum = sum + (i + j + k);
        }
      }
    }
    return sum;
  };
  dart.fn(range_analysis_test.bar, VoidTodynamic());
  range_analysis_test.test1 = function() {
    for (let i = 0; i < 20; i++)
      range_analysis_test.bar();
  };
  dart.fn(range_analysis_test.test1, VoidTodynamic());
  range_analysis_test.test2 = function() {
    let width = 1073741823;
    expect$.Expect.equals(width - 1, range_analysis_test.foo(width - 5000, width - 1));
    expect$.Expect.equals(width, range_analysis_test.foo(width - 5000, width));
  };
  dart.fn(range_analysis_test.test2, VoidTodynamic());
  range_analysis_test.foo = function(n, w) {
    let x = 0;
    for (let i = n; dart.test(dart.dsend(i, '<=', w)); i = dart.dsend(i, '+', 1)) {
      expect$.Expect.isTrue(dart.dsend(i, '>', 0));
      x = core.int._check(i);
    }
    return x;
  };
  dart.fn(range_analysis_test.foo, dynamicAnddynamicTodynamic());
  range_analysis_test.f = function(a, b) {
    if (dart.test(dart.dsend(a, '<', b))) {
      if (dart.test(dart.dsend(a, '>', b))) {
        dart.throw("unreachable");
      }
      return 2;
    }
    return 3;
  };
  dart.fn(range_analysis_test.f, dynamicAnddynamicTodynamic());
  range_analysis_test.f1 = function(a, b) {
    if (dart.test(dart.dsend(a, '<', b))) {
      if (dart.test(dart.dsend(a, '>', dart.dsend(b, '-', 1)))) {
        dart.throw("unreachable");
      }
      return 2;
    }
    return 3;
  };
  dart.fn(range_analysis_test.f1, dynamicAnddynamicTodynamic());
  range_analysis_test.f2 = function(a, b) {
    if (dart.test(dart.dsend(a, '<', b))) {
      if (dart.test(dart.dsend(a, '>', dart.dsend(b, '-', 2)))) {
        return 2;
      }
      dart.throw("unreachable");
    }
    return 3;
  };
  dart.fn(range_analysis_test.f2, dynamicAnddynamicTodynamic());
  range_analysis_test.g = function() {
    let i = null;
    for (i = 0; dart.test(dart.dsend(i, '<', 10)); i = dart.dsend(i, '+', 1)) {
      if (dart.test(dart.dsend(i, '<', 0))) dart.throw("unreachable");
    }
    return i;
  };
  dart.fn(range_analysis_test.g, VoidTodynamic());
  range_analysis_test.h = function(n) {
    let i = null;
    for (i = 0; dart.test(dart.dsend(i, '<', n)); i = dart.dsend(i, '+', 1)) {
      if (dart.test(dart.dsend(i, '<', 0))) dart.throw("unreachable");
      let j = dart.dsend(i, '-', 1);
      if (dart.test(dart.dsend(j, '>=', dart.dsend(n, '-', 1)))) dart.throw("unreachable");
    }
    return i;
  };
  dart.fn(range_analysis_test.h, dynamicTodynamic());
  range_analysis_test.test3 = function() {
    function test_fun(fun) {
      expect$.Expect.equals(2, dart.dcall(fun, 0, 1));
      expect$.Expect.equals(3, dart.dcall(fun, 0, 0));
      for (let i = 0; i < 20; i++)
        dart.dcall(fun, 0, 1);
      expect$.Expect.equals(2, dart.dcall(fun, 0, 1));
      expect$.Expect.equals(3, dart.dcall(fun, 0, 0));
    }
    dart.fn(test_fun, dynamicTodynamic());
    test_fun(range_analysis_test.f);
    test_fun(range_analysis_test.f1);
    test_fun(range_analysis_test.f2);
    expect$.Expect.equals(10, range_analysis_test.g());
    for (let i = 0; i < 20; i++)
      range_analysis_test.g();
    expect$.Expect.equals(10, range_analysis_test.g());
    expect$.Expect.equals(10, range_analysis_test.h(10));
    for (let i = 0; i < 20; i++)
      range_analysis_test.h(10);
    expect$.Expect.equals(10, range_analysis_test.h(10));
  };
  dart.fn(range_analysis_test.test3, VoidTodynamic());
  range_analysis_test.main = function() {
    range_analysis_test.test1();
    range_analysis_test.test2();
    range_analysis_test.test3();
  };
  dart.fn(range_analysis_test.main, VoidTodynamic());
  // Exports:
  exports.range_analysis_test = range_analysis_test;
});
