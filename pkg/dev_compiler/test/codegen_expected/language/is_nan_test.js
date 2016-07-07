dart_library.library('language/is_nan_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__is_nan_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const is_nan_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  is_nan_test.A = class A extends core.Object {
    get isNaN() {
      return false;
    }
  };
  is_nan_test.main = function() {
    expect$.Expect.isTrue(is_nan_test.foo(core.double.NAN));
    expect$.Expect.isFalse(is_nan_test.foo(new is_nan_test.A()));
    expect$.Expect.throws(dart.fn(() => is_nan_test.foo('bar'), VoidTovoid()), dart.fn(e => core.NoSuchMethodError.is(e), dynamicTobool()));
  };
  dart.fn(is_nan_test.main, VoidTodynamic());
  is_nan_test.foo = function(a) {
    return dart.dload(a, 'isNaN');
  };
  dart.fn(is_nan_test.foo, dynamicTodynamic());
  // Exports:
  exports.is_nan_test = is_nan_test;
});
