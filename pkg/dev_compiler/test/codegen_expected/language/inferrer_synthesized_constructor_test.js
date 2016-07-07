dart_library.library('language/inferrer_synthesized_constructor_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__inferrer_synthesized_constructor_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const inferrer_synthesized_constructor_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  inferrer_synthesized_constructor_test.A = class A extends core.Object {
    new(x) {
      if (x === void 0) x = 'foo';
      this.x = x;
    }
  };
  dart.setSignature(inferrer_synthesized_constructor_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(inferrer_synthesized_constructor_test.A, [], [dart.dynamic])})
  });
  inferrer_synthesized_constructor_test.B = class B extends inferrer_synthesized_constructor_test.A {
    new() {
      super.new();
    }
  };
  inferrer_synthesized_constructor_test.main = function() {
    expect$.Expect.equals(84, dart.dsend(new inferrer_synthesized_constructor_test.A(42).x, '+', 42));
    expect$.Expect.throws(dart.fn(() => dart.dsend(new inferrer_synthesized_constructor_test.B().x, '+', 42), VoidTovoid()), dart.fn(e => core.ArgumentError.is(e) || core.TypeError.is(e) || core.NoSuchMethodError.is(e), dynamicTobool()));
  };
  dart.fn(inferrer_synthesized_constructor_test.main, VoidTodynamic());
  // Exports:
  exports.inferrer_synthesized_constructor_test = inferrer_synthesized_constructor_test;
});
