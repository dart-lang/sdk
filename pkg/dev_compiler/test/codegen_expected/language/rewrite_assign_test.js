dart_library.library('language/rewrite_assign_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__rewrite_assign_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const rewrite_assign_test = Object.create(null);
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  rewrite_assign_test.bar = function(x, y) {
  };
  dart.fn(rewrite_assign_test.bar, dynamicAnddynamicTodynamic());
  rewrite_assign_test.foo = function(b) {
    let x = null, y = null;
    if (dart.test(b)) {
      x = 1;
      y = 2;
    } else {
      x = 2;
      y = 1;
    }
    rewrite_assign_test.bar(x, y);
    rewrite_assign_test.bar(x, y);
    return x;
  };
  dart.fn(rewrite_assign_test.foo, dynamicTodynamic());
  rewrite_assign_test.main = function() {
    expect$.Expect.equals(1, rewrite_assign_test.foo(true));
    expect$.Expect.equals(2, rewrite_assign_test.foo(false));
  };
  dart.fn(rewrite_assign_test.main, VoidTodynamic());
  // Exports:
  exports.rewrite_assign_test = rewrite_assign_test;
});
