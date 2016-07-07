dart_library.library('language/inference_super_constructor_call_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__inference_super_constructor_call_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const inference_super_constructor_call_test = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  inference_super_constructor_call_test.A = class A extends core.Object {
    full(field) {
      this.field = field;
    }
  };
  dart.defineNamedConstructor(inference_super_constructor_call_test.A, 'full');
  dart.setSignature(inference_super_constructor_call_test.A, {
    constructors: () => ({full: dart.definiteFunctionType(inference_super_constructor_call_test.A, [dart.dynamic])})
  });
  inference_super_constructor_call_test.B = class B extends inference_super_constructor_call_test.A {
    full(field) {
      super.full(field);
    }
  };
  dart.defineNamedConstructor(inference_super_constructor_call_test.B, 'full');
  dart.setSignature(inference_super_constructor_call_test.B, {
    constructors: () => ({full: dart.definiteFunctionType(inference_super_constructor_call_test.B, [dart.dynamic])})
  });
  inference_super_constructor_call_test.main = function() {
    expect$.Expect.equals(84, dart.dsend(new inference_super_constructor_call_test.A.full(42).field, '+', 42));
    expect$.Expect.throws(dart.fn(() => dart.dsend(new inference_super_constructor_call_test.B.full(null).field, '+', 42), VoidTovoid()), dart.fn(e => core.NoSuchMethodError.is(e), dynamicTobool()));
  };
  dart.fn(inference_super_constructor_call_test.main, VoidTodynamic());
  // Exports:
  exports.inference_super_constructor_call_test = inference_super_constructor_call_test;
});
