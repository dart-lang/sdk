dart_library.library('language/liveness_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__liveness_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const liveness_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  liveness_test.foo = function(x) {
    let y = x;
    for (let i = 0; i < 10; i++) {
      x = dart.dsend(x, '+', 1);
    }
    return y;
  };
  dart.fn(liveness_test.foo, dynamicTodynamic());
  liveness_test.main = function() {
    expect$.Expect.equals(499, liveness_test.foo(499));
  };
  dart.fn(liveness_test.main, VoidTodynamic());
  // Exports:
  exports.liveness_test = liveness_test;
});
