dart_library.library('language/regress_22777_test', null, /* Imports */[
  'dart_sdk',
  'expect',
  'async_helper'
], function load__regress_22777_test(exports, dart_sdk, expect, async_helper) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const async_helper$ = async_helper.async_helper;
  const regress_22777_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  regress_22777_test.a = 0;
  regress_22777_test.testSync = function() {
    do {
      continue;
    } while (dart.test(dart.throw("Error")));
    regress_22777_test.a = 100;
  };
  dart.fn(regress_22777_test.testSync, VoidTodynamic());
  regress_22777_test.testAsync = function() {
    return dart.async(function*() {
      do {
        continue;
      } while (dart.test(yield dart.throw("Error")));
      regress_22777_test.a = 100;
    }, dart.dynamic);
  };
  dart.fn(regress_22777_test.testAsync, VoidTodynamic());
  regress_22777_test.test = function() {
    return dart.async(function*() {
      try {
        regress_22777_test.testSync();
      } catch (e) {
        expect$.Expect.equals(e, "Error");
      }

      expect$.Expect.equals(regress_22777_test.a, 0);
      try {
        yield regress_22777_test.testAsync();
      } catch (e) {
        expect$.Expect.equals(e, "Error");
      }

      expect$.Expect.equals(regress_22777_test.a, 0);
    }, dart.dynamic);
  };
  dart.fn(regress_22777_test.test, VoidTodynamic());
  regress_22777_test.main = function() {
    async_helper$.asyncStart();
    dart.dsend(regress_22777_test.test(), 'then', dart.fn(_ => async_helper$.asyncEnd(), dynamicTovoid()));
  };
  dart.fn(regress_22777_test.main, VoidTodynamic());
  // Exports:
  exports.regress_22777_test = regress_22777_test;
});
