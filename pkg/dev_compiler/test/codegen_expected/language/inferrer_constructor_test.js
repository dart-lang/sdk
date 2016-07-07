dart_library.library('language/inferrer_constructor_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__inferrer_constructor_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const inferrer_constructor_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  inferrer_constructor_test.A = class A extends core.Object {
    new(test) {
      this.field = null;
      if (dart.test(test)) {
        return;
        this.field = 42;
      } else {
        this.field = 54;
      }
    }
  };
  dart.setSignature(inferrer_constructor_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(inferrer_constructor_test.A, [dart.dynamic])})
  });
  inferrer_constructor_test.main = function() {
    let a = new inferrer_constructor_test.A(true);
    expect$.Expect.throws(dart.fn(() => dart.dsend(a.field, '+', 42), VoidTovoid()), dart.fn(e => core.NoSuchMethodError.is(e), dynamicTobool()));
  };
  dart.fn(inferrer_constructor_test.main, VoidTodynamic());
  // Exports:
  exports.inferrer_constructor_test = inferrer_constructor_test;
});
