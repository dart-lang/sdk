dart_library.library('language/logical_expression_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__logical_expression_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const logical_expression_test = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTobool = () => (VoidTobool = dart.constFn(dart.definiteFunctionType(core.bool, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let ListTovoid = () => (ListTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.List])))();
  logical_expression_test.globalCounter = 0;
  logical_expression_test.falseWithSideEffect = function() {
    function confuse() {
      return new core.DateTime.now().millisecondsSinceEpoch == 42;
    }
    dart.fn(confuse, VoidTobool());
    let result = confuse();
    if (dart.test(result)) {
      try {
        try {
          if (dart.test(confuse())) logical_expression_test.falseWithSideEffect();
          if (dart.test(confuse())) return 499;
        } catch (e) {
          throw e;
        }

      } catch (e) {
        throw e;
      }

    }
    logical_expression_test.globalCounter = dart.notNull(logical_expression_test.globalCounter) + 1;
    return result;
  };
  dart.fn(logical_expression_test.falseWithSideEffect, VoidTodynamic());
  logical_expression_test.falseWithoutSideEffect = function() {
    function confuse() {
      return new core.DateTime.now().millisecondsSinceEpoch == 42;
    }
    dart.fn(confuse, VoidTobool());
    let result = confuse();
    if (dart.test(result)) {
      try {
        try {
          if (dart.test(confuse())) logical_expression_test.falseWithSideEffect();
          if (dart.test(confuse())) return 499;
        } catch (e) {
          throw e;
        }

      } catch (e) {
        throw e;
      }

    }
    return result;
  };
  dart.fn(logical_expression_test.falseWithoutSideEffect, VoidTodynamic());
  logical_expression_test.testLogicalOr = function() {
    logical_expression_test.globalCounter = 0;
    let cond1 = core.bool._check(logical_expression_test.falseWithSideEffect());
    if (dart.test(cond1) || dart.test(logical_expression_test.falseWithoutSideEffect())) expect$.Expect.fail("must be false");
    if (dart.test(cond1) || dart.test(logical_expression_test.falseWithoutSideEffect())) expect$.Expect.fail("must be false");
    if (dart.test(cond1) || dart.test(logical_expression_test.falseWithoutSideEffect())) expect$.Expect.fail("must be false");
    expect$.Expect.equals(1, logical_expression_test.globalCounter);
    cond1 = dart.equals(logical_expression_test.falseWithSideEffect(), 499);
    if (dart.test(cond1) || dart.test(logical_expression_test.falseWithoutSideEffect())) expect$.Expect.fail("must be false");
    if (dart.test(cond1) || dart.test(logical_expression_test.falseWithoutSideEffect())) expect$.Expect.fail("must be false");
    if (dart.test(cond1) || dart.test(logical_expression_test.falseWithoutSideEffect())) expect$.Expect.fail("must be false");
    expect$.Expect.equals(2, logical_expression_test.globalCounter);
  };
  dart.fn(logical_expression_test.testLogicalOr, VoidTodynamic());
  dart.defineLazy(logical_expression_test, {
    get globalList() {
      return [];
    },
    set globalList(_) {}
  });
  logical_expression_test.testLogicalOr2 = function() {
    logical_expression_test.globalList[dartx.clear]();
    logical_expression_test.testValueOr([]);
    logical_expression_test.testValueOr(null);
    expect$.Expect.listEquals(JSArrayOfint().of([1, 2, 3]), logical_expression_test.globalList);
  };
  dart.fn(logical_expression_test.testLogicalOr2, VoidTovoid());
  logical_expression_test.testValueOr = function(list) {
    if (list == null) logical_expression_test.globalList[dartx.add](1);
    if (list == null || dart.test(list[dartx.contains]("2"))) logical_expression_test.globalList[dartx.add](2);
    if (list == null || dart.test(list[dartx.contains]("3"))) logical_expression_test.globalList[dartx.add](3);
  };
  dart.fn(logical_expression_test.testValueOr, ListTovoid());
  logical_expression_test.testLogicalAnd = function() {
    logical_expression_test.globalCounter = 0;
    let cond1 = core.bool._check(logical_expression_test.falseWithSideEffect());
    if (dart.test(cond1) && dart.test(logical_expression_test.falseWithoutSideEffect())) expect$.Expect.fail("must be false");
    if (dart.test(cond1) && dart.test(logical_expression_test.falseWithoutSideEffect())) expect$.Expect.fail("must be false");
    if (dart.test(cond1) && dart.test(logical_expression_test.falseWithoutSideEffect())) expect$.Expect.fail("must be false");
    expect$.Expect.equals(1, logical_expression_test.globalCounter);
    cond1 = dart.equals(logical_expression_test.falseWithSideEffect(), 499);
    if (dart.test(cond1) && dart.test(logical_expression_test.falseWithoutSideEffect())) expect$.Expect.fail("must be false");
    if (dart.test(cond1) && dart.test(logical_expression_test.falseWithoutSideEffect())) expect$.Expect.fail("must be false");
    if (dart.test(cond1) && dart.test(logical_expression_test.falseWithoutSideEffect())) expect$.Expect.fail("must be false");
    expect$.Expect.equals(2, logical_expression_test.globalCounter);
  };
  dart.fn(logical_expression_test.testLogicalAnd, VoidTodynamic());
  logical_expression_test.testLogicalAnd2 = function() {
    logical_expression_test.globalList[dartx.clear]();
    logical_expression_test.testValueAnd([]);
    logical_expression_test.testValueAnd(null);
    expect$.Expect.listEquals(JSArrayOfint().of([1, 2, 3]), logical_expression_test.globalList);
  };
  dart.fn(logical_expression_test.testLogicalAnd2, VoidTovoid());
  logical_expression_test.testValueAnd = function(list) {
    if (list == null) logical_expression_test.globalList[dartx.add](1);
    if (list == null && dart.test(logical_expression_test.globalList[dartx.contains](1))) logical_expression_test.globalList[dartx.add](2);
    if (list == null && dart.test(logical_expression_test.globalList[dartx.contains](1))) logical_expression_test.globalList[dartx.add](3);
  };
  dart.fn(logical_expression_test.testValueAnd, ListTovoid());
  logical_expression_test.main = function() {
    logical_expression_test.testLogicalOr();
    logical_expression_test.testLogicalOr2();
    logical_expression_test.testLogicalAnd();
    logical_expression_test.testLogicalAnd2();
  };
  dart.fn(logical_expression_test.main, VoidTodynamic());
  // Exports:
  exports.logical_expression_test = logical_expression_test;
});
