dart_library.library('language/propagate_past_constant_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__propagate_past_constant_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const propagate_past_constant_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  propagate_past_constant_test.foo = function(x) {
    return x;
  };
  dart.fn(propagate_past_constant_test.foo, dynamicTodynamic());
  propagate_past_constant_test.check = function(y) {
    expect$.Expect.equals('foo', y);
  };
  dart.fn(propagate_past_constant_test.check, dynamicTodynamic());
  propagate_past_constant_test.main = function() {
    let x = propagate_past_constant_test.foo('foo');
    let y = propagate_past_constant_test.foo(x);
    x = 'constant';
    propagate_past_constant_test.check(y);
    propagate_past_constant_test.foo(x);
    propagate_past_constant_test.foo(x);
  };
  dart.fn(propagate_past_constant_test.main, VoidTodynamic());
  // Exports:
  exports.propagate_past_constant_test = propagate_past_constant_test;
});
