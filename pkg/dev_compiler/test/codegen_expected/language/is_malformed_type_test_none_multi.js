dart_library.library('language/is_malformed_type_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__is_malformed_type_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const is_malformed_type_test_none_multi = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  is_malformed_type_test_none_multi.evalCount = 0;
  is_malformed_type_test_none_multi.testEval = function(x) {
    is_malformed_type_test_none_multi.evalCount = dart.notNull(is_malformed_type_test_none_multi.evalCount) + 1;
    return x;
  };
  dart.fn(is_malformed_type_test_none_multi.testEval, dynamicTodynamic());
  is_malformed_type_test_none_multi.test99 = function(e) {
    try {
      expect$.Expect.fail("unreachable");
    } catch (exc) {
      expect$.Expect.isTrue(core.TypeError.is(exc));
    }

  };
  dart.fn(is_malformed_type_test_none_multi.test99, dynamicTodynamic());
  is_malformed_type_test_none_multi.test98 = function(e) {
    try {
      expect$.Expect.fail("unreachable");
    } catch (exc) {
      expect$.Expect.isTrue(core.TypeError.is(exc));
    }

  };
  dart.fn(is_malformed_type_test_none_multi.test98, dynamicTodynamic());
  is_malformed_type_test_none_multi.test97 = function(e) {
    try {
      is_malformed_type_test_none_multi.evalCount = 0;
      expect$.Expect.fail("unreachable");
    } catch (exc) {
      expect$.Expect.isTrue(core.TypeError.is(exc));
      expect$.Expect.equals(0, is_malformed_type_test_none_multi.evalCount);
    }

  };
  dart.fn(is_malformed_type_test_none_multi.test97, dynamicTodynamic());
  is_malformed_type_test_none_multi.test96 = function(e) {
    try {
      is_malformed_type_test_none_multi.evalCount = 0;
      expect$.Expect.fail("unreachable");
    } catch (exc) {
      expect$.Expect.isTrue(core.TypeError.is(exc));
      expect$.Expect.equals(0, is_malformed_type_test_none_multi.evalCount);
    }

  };
  dart.fn(is_malformed_type_test_none_multi.test96, dynamicTodynamic());
  is_malformed_type_test_none_multi.test95 = function(e) {
    try {
      is_malformed_type_test_none_multi.evalCount = 0;
      expect$.Expect.fail("unreachable");
    } catch (exc) {
      expect$.Expect.isTrue(core.TypeError.is(exc));
      expect$.Expect.equals(1, is_malformed_type_test_none_multi.evalCount);
    }

  };
  dart.fn(is_malformed_type_test_none_multi.test95, dynamicTodynamic());
  is_malformed_type_test_none_multi.test94 = function(e) {
    try {
      is_malformed_type_test_none_multi.evalCount = 0;
      expect$.Expect.fail("unreachable");
    } catch (exc) {
      expect$.Expect.isTrue(core.TypeError.is(exc));
      expect$.Expect.equals(1, is_malformed_type_test_none_multi.evalCount);
    }

  };
  dart.fn(is_malformed_type_test_none_multi.test94, dynamicTodynamic());
  is_malformed_type_test_none_multi.main = function() {
  };
  dart.fn(is_malformed_type_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.is_malformed_type_test_none_multi = is_malformed_type_test_none_multi;
});
