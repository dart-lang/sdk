dart_library.library('language/rewrite_nested_if1_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__rewrite_nested_if1_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const rewrite_nested_if1_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let dynamicAnddynamicAnddynamicTodynamic = () => (dynamicAnddynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  rewrite_nested_if1_test.global = null;
  rewrite_nested_if1_test.setGlobal = function(v) {
    rewrite_nested_if1_test.global = v;
  };
  dart.fn(rewrite_nested_if1_test.setGlobal, dynamicTodynamic());
  rewrite_nested_if1_test.check_true_true = function(x, y, v) {
    if (dart.test(x)) {
      if (dart.test(y)) {
        rewrite_nested_if1_test.setGlobal(v);
      }
    }
  };
  dart.fn(rewrite_nested_if1_test.check_true_true, dynamicAnddynamicAnddynamicTodynamic());
  rewrite_nested_if1_test.check_false_true = function(x, y, v) {
    if (dart.test(x)) {
    } else {
      if (dart.test(y)) {
        rewrite_nested_if1_test.setGlobal(v);
      }
    }
  };
  dart.fn(rewrite_nested_if1_test.check_false_true, dynamicAnddynamicAnddynamicTodynamic());
  rewrite_nested_if1_test.check_true_false = function(x, y, v) {
    if (dart.test(x)) {
      if (dart.test(y)) {
      } else {
        rewrite_nested_if1_test.setGlobal(v);
      }
    }
  };
  dart.fn(rewrite_nested_if1_test.check_true_false, dynamicAnddynamicAnddynamicTodynamic());
  rewrite_nested_if1_test.check_false_false = function(x, y, v) {
    if (dart.test(x)) {
    } else {
      if (dart.test(y)) {
      } else {
        rewrite_nested_if1_test.setGlobal(v);
      }
    }
  };
  dart.fn(rewrite_nested_if1_test.check_false_false, dynamicAnddynamicAnddynamicTodynamic());
  rewrite_nested_if1_test.main = function() {
    rewrite_nested_if1_test.check_true_true(true, true, 4);
    rewrite_nested_if1_test.check_true_true(false, false, 1);
    rewrite_nested_if1_test.check_true_true(false, true, 2);
    rewrite_nested_if1_test.check_true_true(true, false, 3);
    expect$.Expect.equals(4, rewrite_nested_if1_test.global);
    rewrite_nested_if1_test.check_true_false(false, false, 1);
    rewrite_nested_if1_test.check_true_false(false, true, 2);
    rewrite_nested_if1_test.check_true_false(true, false, 3);
    rewrite_nested_if1_test.check_true_false(true, true, 4);
    expect$.Expect.equals(3, rewrite_nested_if1_test.global);
    rewrite_nested_if1_test.check_false_true(false, false, 1);
    rewrite_nested_if1_test.check_false_true(false, true, 2);
    rewrite_nested_if1_test.check_false_true(true, false, 3);
    rewrite_nested_if1_test.check_false_true(true, true, 4);
    expect$.Expect.equals(2, rewrite_nested_if1_test.global);
    rewrite_nested_if1_test.check_false_false(false, false, 1);
    rewrite_nested_if1_test.check_false_false(false, true, 2);
    rewrite_nested_if1_test.check_false_false(true, false, 3);
    rewrite_nested_if1_test.check_false_false(true, true, 4);
    expect$.Expect.equals(1, rewrite_nested_if1_test.global);
  };
  dart.fn(rewrite_nested_if1_test.main, VoidTodynamic());
  // Exports:
  exports.rewrite_nested_if1_test = rewrite_nested_if1_test;
});
