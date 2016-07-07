dart_library.library('language/recursive_loop_phis_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__recursive_loop_phis_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const recursive_loop_phis_test = Object.create(null);
  let boolTodynamic = () => (boolTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.bool])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  recursive_loop_phis_test.foo = function(b) {
    let x = 499;
    for (let i = 0; i < 3; i++) {
      if (i == 0 && dart.test(b)) x = 42;
      if (!dart.test(b)) recursive_loop_phis_test.foo(true);
    }
    return x;
  };
  dart.fn(recursive_loop_phis_test.foo, boolTodynamic());
  recursive_loop_phis_test.main = function() {
    expect$.Expect.equals(499, recursive_loop_phis_test.foo(false));
  };
  dart.fn(recursive_loop_phis_test.main, VoidTodynamic());
  // Exports:
  exports.recursive_loop_phis_test = recursive_loop_phis_test;
});
