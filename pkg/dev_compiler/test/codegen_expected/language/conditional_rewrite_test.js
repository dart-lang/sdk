dart_library.library('language/conditional_rewrite_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__conditional_rewrite_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const conditional_rewrite_test = Object.create(null);
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  conditional_rewrite_test.posFalse = function(x, y) {
    return x != null ? y : false;
  };
  dart.fn(conditional_rewrite_test.posFalse, dynamicAnddynamicTodynamic());
  conditional_rewrite_test.negFalse = function(x, y) {
    return x != null ? !dart.test(y) : false;
  };
  dart.fn(conditional_rewrite_test.negFalse, dynamicAnddynamicTodynamic());
  conditional_rewrite_test.posNull = function(x, y) {
    return x != null ? y : null;
  };
  dart.fn(conditional_rewrite_test.posNull, dynamicAnddynamicTodynamic());
  conditional_rewrite_test.negNull = function(x, y) {
    return x != null ? !dart.test(y) : null;
  };
  dart.fn(conditional_rewrite_test.negNull, dynamicAnddynamicTodynamic());
  conditional_rewrite_test.main = function() {
    let isCheckedMode = false;
    dart.assert(isCheckedMode = true);
    expect$.Expect.equals(false, conditional_rewrite_test.posFalse(null, false));
    expect$.Expect.equals(false, conditional_rewrite_test.negFalse(null, false));
    expect$.Expect.equals(null, conditional_rewrite_test.posNull(null, false));
    expect$.Expect.equals(null, conditional_rewrite_test.negNull(null, false));
    expect$.Expect.equals(false, conditional_rewrite_test.posFalse(null, true));
    expect$.Expect.equals(false, conditional_rewrite_test.negFalse(null, true));
    expect$.Expect.equals(null, conditional_rewrite_test.posNull(null, true));
    expect$.Expect.equals(null, conditional_rewrite_test.negNull(null, true));
    expect$.Expect.equals(false, conditional_rewrite_test.posFalse([], false));
    expect$.Expect.equals(true, conditional_rewrite_test.negFalse([], false));
    expect$.Expect.equals(false, conditional_rewrite_test.posNull([], false));
    expect$.Expect.equals(true, conditional_rewrite_test.negNull([], false));
    expect$.Expect.equals(true, conditional_rewrite_test.posFalse([], true));
    expect$.Expect.equals(false, conditional_rewrite_test.negFalse([], true));
    expect$.Expect.equals(true, conditional_rewrite_test.posNull([], true));
    expect$.Expect.equals(false, conditional_rewrite_test.negNull([], true));
    if (!isCheckedMode) {
      expect$.Expect.equals(null, conditional_rewrite_test.posFalse([], null));
      expect$.Expect.equals(true, conditional_rewrite_test.negFalse([], null));
      expect$.Expect.equals(null, conditional_rewrite_test.posNull([], null));
      expect$.Expect.equals(true, conditional_rewrite_test.negNull([], null));
      let y = dart.map();
      expect$.Expect.identical(y, conditional_rewrite_test.posFalse([], y));
      expect$.Expect.equals(true, conditional_rewrite_test.negFalse([], y));
      expect$.Expect.identical(y, conditional_rewrite_test.posNull([], y));
      expect$.Expect.equals(true, conditional_rewrite_test.negNull([], y));
    }
  };
  dart.fn(conditional_rewrite_test.main, VoidTodynamic());
  // Exports:
  exports.conditional_rewrite_test = conditional_rewrite_test;
});
