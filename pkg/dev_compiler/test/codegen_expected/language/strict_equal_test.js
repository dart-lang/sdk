dart_library.library('language/strict_equal_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__strict_equal_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const strict_equal_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  strict_equal_test.main = function() {
    for (let i = 0; i < 20; i++) {
      expect$.Expect.isFalse(strict_equal_test.test1(5));
      expect$.Expect.isTrue(strict_equal_test.test1(3));
      expect$.Expect.isTrue(strict_equal_test.test2(5));
      expect$.Expect.isFalse(strict_equal_test.test2(3));
      expect$.Expect.isTrue(strict_equal_test.test2r(5));
      expect$.Expect.isFalse(strict_equal_test.test2r(3));
      expect$.Expect.isTrue(strict_equal_test.test3());
      expect$.Expect.equals(2, strict_equal_test.test4(5));
      expect$.Expect.equals(1, strict_equal_test.test4(3));
      expect$.Expect.equals(1, strict_equal_test.test5(5));
      expect$.Expect.equals(2, strict_equal_test.test5(3));
      expect$.Expect.equals(1, strict_equal_test.test6());
      expect$.Expect.isFalse(strict_equal_test.test7());
      expect$.Expect.equals(2, strict_equal_test.test8());
      expect$.Expect.isFalse(strict_equal_test.test9(2));
      expect$.Expect.isFalse(strict_equal_test.test9r(2));
      expect$.Expect.isTrue(strict_equal_test.test9(0));
      expect$.Expect.isTrue(strict_equal_test.test9r(0));
      expect$.Expect.isFalse(strict_equal_test.test10(0));
      expect$.Expect.isFalse(strict_equal_test.test10r(0));
      expect$.Expect.isTrue(strict_equal_test.test10(2));
      expect$.Expect.isTrue(strict_equal_test.test10r(2));
      strict_equal_test.test11(i);
    }
  };
  dart.fn(strict_equal_test.main, VoidTodynamic());
  strict_equal_test.test1 = function(a) {
    return core.identical(a, 3);
  };
  dart.fn(strict_equal_test.test1, dynamicTodynamic());
  strict_equal_test.test2 = function(a) {
    return !core.identical(a, 3);
  };
  dart.fn(strict_equal_test.test2, dynamicTodynamic());
  strict_equal_test.test2r = function(a) {
    return !core.identical(3, a);
  };
  dart.fn(strict_equal_test.test2r, dynamicTodynamic());
  strict_equal_test.test3 = function() {
    return core.identical(strict_equal_test.get5(), 5);
  };
  dart.fn(strict_equal_test.test3, VoidTodynamic());
  strict_equal_test.test4 = function(a) {
    if (core.identical(a, 3)) {
      return 1;
    } else {
      return 2;
    }
  };
  dart.fn(strict_equal_test.test4, dynamicTodynamic());
  strict_equal_test.test5 = function(a) {
    if (!core.identical(a, 3)) {
      return 1;
    } else {
      return 2;
    }
  };
  dart.fn(strict_equal_test.test5, dynamicTodynamic());
  strict_equal_test.test6 = function() {
    if (core.identical(strict_equal_test.get5(), 5)) {
      return 1;
    } else {
      return 2;
    }
  };
  dart.fn(strict_equal_test.test6, VoidTodynamic());
  strict_equal_test.get5 = function() {
    return 5;
  };
  dart.fn(strict_equal_test.get5, VoidTodynamic());
  strict_equal_test.test7 = function() {
    return null != null;
  };
  dart.fn(strict_equal_test.test7, VoidTodynamic());
  strict_equal_test.test8 = function() {
    if (null != null) {
      return 1;
    } else {
      return 2;
    }
  };
  dart.fn(strict_equal_test.test8, VoidTodynamic());
  strict_equal_test.test9 = function(a) {
    return core.identical(a, 0);
  };
  dart.fn(strict_equal_test.test9, dynamicTodynamic());
  strict_equal_test.test9r = function(a) {
    return core.identical(0, a);
  };
  dart.fn(strict_equal_test.test9r, dynamicTodynamic());
  strict_equal_test.test10 = function(a) {
    return !core.identical(a, 0);
  };
  dart.fn(strict_equal_test.test10, dynamicTodynamic());
  strict_equal_test.test10r = function(a) {
    return !core.identical(0, a);
  };
  dart.fn(strict_equal_test.test10r, dynamicTodynamic());
  strict_equal_test.test11 = function(a) {
    if (core.identical(a, 0)) {
      expect$.Expect.isTrue(core.identical(0, a));
      expect$.Expect.isFalse(!core.identical(a, 0));
      expect$.Expect.isFalse(!core.identical(0, a));
    } else {
      expect$.Expect.isFalse(core.identical(0, a));
      expect$.Expect.isTrue(!core.identical(a, 0));
      expect$.Expect.isTrue(!core.identical(0, a));
    }
  };
  dart.fn(strict_equal_test.test11, dynamicTodynamic());
  // Exports:
  exports.strict_equal_test = strict_equal_test;
});
