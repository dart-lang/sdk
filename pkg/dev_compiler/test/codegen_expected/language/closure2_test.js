dart_library.library('language/closure2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__closure2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const closure2_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  closure2_test.bounce = function(fn) {
    return dart.dcall(fn);
  };
  dart.fn(closure2_test.bounce, dynamicTodynamic());
  closure2_test.demo = function(s) {
    let i = null, a = closure2_test.bounce(dart.fn(() => s, VoidTodynamic()));
    return a;
  };
  dart.fn(closure2_test.demo, dynamicTodynamic());
  closure2_test.main = function() {
    expect$.Expect.equals("Bounce!", closure2_test.demo("Bounce!"));
  };
  dart.fn(closure2_test.main, VoidTodynamic());
  // Exports:
  exports.closure2_test = closure2_test;
});
