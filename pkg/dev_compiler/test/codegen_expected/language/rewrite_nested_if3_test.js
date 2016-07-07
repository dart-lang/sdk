dart_library.library('language/rewrite_nested_if3_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__rewrite_nested_if3_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const rewrite_nested_if3_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  rewrite_nested_if3_test.baz = function() {
  };
  dart.fn(rewrite_nested_if3_test.baz, VoidTodynamic());
  rewrite_nested_if3_test.check_true_true = function(x, y) {
    if (dart.test(x)) {
      if (dart.test(y)) {
        return true;
      }
    }
    rewrite_nested_if3_test.baz();
    return false;
  };
  dart.fn(rewrite_nested_if3_test.check_true_true, dynamicAnddynamicTodynamic());
  rewrite_nested_if3_test.check_false_true = function(x, y) {
    if (dart.test(x)) {
    } else {
      if (dart.test(y)) {
        return true;
      }
    }
    rewrite_nested_if3_test.baz();
    return false;
  };
  dart.fn(rewrite_nested_if3_test.check_false_true, dynamicAnddynamicTodynamic());
  rewrite_nested_if3_test.check_true_false = function(x, y) {
    if (dart.test(x)) {
      if (dart.test(y)) {
      } else {
        return true;
      }
    }
    rewrite_nested_if3_test.baz();
    return false;
  };
  dart.fn(rewrite_nested_if3_test.check_true_false, dynamicAnddynamicTodynamic());
  rewrite_nested_if3_test.check_false_false = function(x, y) {
    if (dart.test(x)) {
    } else {
      if (dart.test(y)) {
      } else {
        return true;
      }
    }
    rewrite_nested_if3_test.baz();
    return false;
  };
  dart.fn(rewrite_nested_if3_test.check_false_false, dynamicAnddynamicTodynamic());
  rewrite_nested_if3_test.main = function() {
    expect$.Expect.equals(true, rewrite_nested_if3_test.check_true_true(true, true));
    expect$.Expect.equals(false, rewrite_nested_if3_test.check_true_true(true, false));
    expect$.Expect.equals(false, rewrite_nested_if3_test.check_true_true(false, true));
    expect$.Expect.equals(false, rewrite_nested_if3_test.check_true_true(false, false));
    expect$.Expect.equals(false, rewrite_nested_if3_test.check_true_false(true, true));
    expect$.Expect.equals(true, rewrite_nested_if3_test.check_true_false(true, false));
    expect$.Expect.equals(false, rewrite_nested_if3_test.check_true_false(false, true));
    expect$.Expect.equals(false, rewrite_nested_if3_test.check_true_false(false, false));
    expect$.Expect.equals(false, rewrite_nested_if3_test.check_false_true(true, true));
    expect$.Expect.equals(false, rewrite_nested_if3_test.check_false_true(true, false));
    expect$.Expect.equals(true, rewrite_nested_if3_test.check_false_true(false, true));
    expect$.Expect.equals(false, rewrite_nested_if3_test.check_false_true(false, false));
    expect$.Expect.equals(false, rewrite_nested_if3_test.check_false_false(true, true));
    expect$.Expect.equals(false, rewrite_nested_if3_test.check_false_false(true, false));
    expect$.Expect.equals(false, rewrite_nested_if3_test.check_false_false(false, true));
    expect$.Expect.equals(true, rewrite_nested_if3_test.check_false_false(false, false));
  };
  dart.fn(rewrite_nested_if3_test.main, VoidTodynamic());
  // Exports:
  exports.rewrite_nested_if3_test = rewrite_nested_if3_test;
});
