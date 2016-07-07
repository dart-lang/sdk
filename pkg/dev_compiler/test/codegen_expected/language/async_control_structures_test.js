dart_library.library('language/async_control_structures_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__async_control_structures_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const async_control_structures_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  async_control_structures_test.expectThenValue = function(future, value) {
    expect$.Expect.isTrue(async.Future.is(future));
    dart.dsend(future, 'then', dart.fn(result => {
      expect$.Expect.equals(value, result);
    }, dynamicTodynamic()));
  };
  dart.fn(async_control_structures_test.expectThenValue, dynamicAnddynamicTodynamic());
  async_control_structures_test.asyncIf = function(condition) {
    return dart.async(function*(condition) {
      if (dart.test(condition)) {
        return 1;
      } else {
        return 2;
      }
      return 3;
    }, dart.dynamic, condition);
  };
  dart.fn(async_control_structures_test.asyncIf, dynamicTodynamic());
  async_control_structures_test.asyncFor = function(condition) {
    return dart.async(function*(condition) {
      for (let i = 0; i < 10; i++) {
        if (i == 5 && dart.test(condition)) {
          return 1;
        }
      }
      return 2;
    }, dart.dynamic, condition);
  };
  dart.fn(async_control_structures_test.asyncFor, dynamicTodynamic());
  async_control_structures_test.asyncTryCatchFinally = function(overrideInFinally, doThrow) {
    return dart.async(function*(overrideInFinally, doThrow) {
      try {
        if (dart.test(doThrow)) dart.throw(444);
        return 1;
      } catch (e) {
        return e;
      }
 finally {
        if (dart.test(overrideInFinally)) return 3;
      }
    }, dart.dynamic, overrideInFinally, doThrow);
  };
  dart.fn(async_control_structures_test.asyncTryCatchFinally, dynamicAnddynamicTodynamic());
  async_control_structures_test.asyncTryCatchLoop = function() {
    return dart.async(function*() {
      let i = 0;
      let throws = 13;
      while (true) {
        try {
          dart.throw(throws);
        } catch (e) {
          if (i == throws) {
            return e;
          }
        }
 finally {
          i++;
        }
      }
    }, dart.dynamic);
  };
  dart.fn(async_control_structures_test.asyncTryCatchLoop, VoidTodynamic());
  async_control_structures_test.asyncImplicitReturn = function() {
    return dart.async(function*() {
      try {
      } catch (e) {
      }
 finally {
      }
    }, dart.dynamic);
  };
  dart.fn(async_control_structures_test.asyncImplicitReturn, VoidTodynamic());
  async_control_structures_test.main = function() {
    let asyncReturn = null;
    for (let i = 0; i < 10; i++) {
      asyncReturn = async_control_structures_test.asyncIf(true);
      async_control_structures_test.expectThenValue(asyncReturn, 1);
      asyncReturn = async_control_structures_test.asyncIf(false);
      async_control_structures_test.expectThenValue(asyncReturn, 2);
      asyncReturn = async_control_structures_test.asyncFor(true);
      async_control_structures_test.expectThenValue(asyncReturn, 1);
      asyncReturn = async_control_structures_test.asyncFor(false);
      async_control_structures_test.expectThenValue(asyncReturn, 2);
      asyncReturn = async_control_structures_test.asyncTryCatchFinally(true, false);
      async_control_structures_test.expectThenValue(asyncReturn, 3);
      asyncReturn = async_control_structures_test.asyncTryCatchFinally(false, false);
      async_control_structures_test.expectThenValue(asyncReturn, 1);
      asyncReturn = async_control_structures_test.asyncTryCatchFinally(true, true);
      async_control_structures_test.expectThenValue(asyncReturn, 3);
      asyncReturn = async_control_structures_test.asyncTryCatchFinally(false, true);
      async_control_structures_test.expectThenValue(asyncReturn, 444);
      asyncReturn = async_control_structures_test.asyncTryCatchLoop();
      async_control_structures_test.expectThenValue(asyncReturn, 13);
      asyncReturn = async_control_structures_test.asyncImplicitReturn();
      async_control_structures_test.expectThenValue(asyncReturn, null);
    }
  };
  dart.fn(async_control_structures_test.main, VoidTodynamic());
  // Exports:
  exports.async_control_structures_test = async_control_structures_test;
});
