dart_library.library('language/instanceof_optimized_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__instanceof_optimized_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const instanceof_optimized_test = Object.create(null);
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let dynamicToint = () => (dynamicToint = dart.constFn(dart.definiteFunctionType(core.int, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  instanceof_optimized_test.isInt = function(x) {
    return typeof x == 'number';
  };
  dart.fn(instanceof_optimized_test.isInt, dynamicTobool());
  instanceof_optimized_test.isIntRes = function(x) {
    if (typeof x == 'number') {
      return 1;
    } else {
      return 0;
    }
  };
  dart.fn(instanceof_optimized_test.isIntRes, dynamicToint());
  instanceof_optimized_test.isNotIntRes = function(x) {
    if (!(typeof x == 'number')) {
      return 1;
    } else {
      return 0;
    }
  };
  dart.fn(instanceof_optimized_test.isNotIntRes, dynamicToint());
  instanceof_optimized_test.isIfThenElseIntRes = function(x) {
    return typeof x == 'number' ? 1 : 0;
  };
  dart.fn(instanceof_optimized_test.isIfThenElseIntRes, dynamicToint());
  instanceof_optimized_test.isString = function(x) {
    return typeof x == 'string';
  };
  dart.fn(instanceof_optimized_test.isString, dynamicTobool());
  instanceof_optimized_test.isStringRes = function(x) {
    if (typeof x == 'string') {
      return 1;
    } else {
      return 0;
    }
  };
  dart.fn(instanceof_optimized_test.isStringRes, dynamicToint());
  instanceof_optimized_test.isNotStringRes = function(x) {
    if (!(typeof x == 'string')) {
      return 1;
    } else {
      return 0;
    }
  };
  dart.fn(instanceof_optimized_test.isNotStringRes, dynamicToint());
  instanceof_optimized_test.main = function() {
    for (let i = 0; i < 20; i++) {
      expect$.Expect.isFalse(instanceof_optimized_test.isInt(3.2));
      expect$.Expect.isTrue(instanceof_optimized_test.isInt(3));
      expect$.Expect.isTrue(instanceof_optimized_test.isInt(17179869184));
      expect$.Expect.isFalse(instanceof_optimized_test.isString(2.0));
      expect$.Expect.isTrue(instanceof_optimized_test.isString("Morgan"));
    }
    expect$.Expect.isFalse(instanceof_optimized_test.isString(true));
    for (let i = 0; i < 20; i++) {
      expect$.Expect.isFalse(instanceof_optimized_test.isInt(3.2));
      expect$.Expect.isTrue(instanceof_optimized_test.isInt(3));
      expect$.Expect.isTrue(instanceof_optimized_test.isInt(17179869184));
      expect$.Expect.isFalse(instanceof_optimized_test.isInt("hu"));
      expect$.Expect.isFalse(instanceof_optimized_test.isString(2.0));
      expect$.Expect.isTrue(instanceof_optimized_test.isString("Morgan"));
      expect$.Expect.isFalse(instanceof_optimized_test.isString(true));
    }
    for (let i = 0; i < 20; i++) {
      expect$.Expect.equals(0, instanceof_optimized_test.isIntRes(3.2));
      expect$.Expect.equals(1, instanceof_optimized_test.isIntRes(3));
      expect$.Expect.equals(0, instanceof_optimized_test.isIntRes("hi"));
      expect$.Expect.equals(1, instanceof_optimized_test.isNotIntRes(3.2));
      expect$.Expect.equals(0, instanceof_optimized_test.isNotIntRes(3));
      expect$.Expect.equals(1, instanceof_optimized_test.isNotIntRes("hi"));
      expect$.Expect.equals(0, instanceof_optimized_test.isIfThenElseIntRes(3.2));
      expect$.Expect.equals(1, instanceof_optimized_test.isIfThenElseIntRes(3));
      expect$.Expect.equals(0, instanceof_optimized_test.isIfThenElseIntRes("hi"));
    }
    for (let i = 0; i < 20; i++) {
      expect$.Expect.equals(0, instanceof_optimized_test.isStringRes(3.2));
      expect$.Expect.equals(1, instanceof_optimized_test.isStringRes("Lotus"));
      expect$.Expect.equals(1, instanceof_optimized_test.isNotStringRes(3.2));
      expect$.Expect.equals(0, instanceof_optimized_test.isNotStringRes("Lotus"));
    }
    expect$.Expect.equals(0, instanceof_optimized_test.isStringRes(null));
    expect$.Expect.equals(1, instanceof_optimized_test.isNotIntRes(null));
    for (let i = 0; i < 20; i++) {
      expect$.Expect.equals(0, instanceof_optimized_test.isStringRes(3.2));
      expect$.Expect.equals(1, instanceof_optimized_test.isStringRes("Lotus"));
      expect$.Expect.equals(0, instanceof_optimized_test.isStringRes(null));
      expect$.Expect.equals(1, instanceof_optimized_test.isNotStringRes(3.2));
      expect$.Expect.equals(0, instanceof_optimized_test.isNotStringRes("Lotus"));
      expect$.Expect.equals(1, instanceof_optimized_test.isNotStringRes(null));
    }
  };
  dart.fn(instanceof_optimized_test.main, VoidTodynamic());
  // Exports:
  exports.instanceof_optimized_test = instanceof_optimized_test;
});
