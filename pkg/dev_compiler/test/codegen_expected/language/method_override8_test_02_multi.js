dart_library.library('language/method_override8_test_02_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__method_override8_test_02_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const method_override8_test_02_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  method_override8_test_02_multi.A = class A extends core.Object {
    foo() {
      return 42;
    }
  };
  dart.setSignature(method_override8_test_02_multi.A, {
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])})
  });
  method_override8_test_02_multi.B = class B extends method_override8_test_02_multi.A {
    foo() {
      return 42;
    }
  };
  method_override8_test_02_multi.main = function() {
    expect$.Expect.equals(42, new method_override8_test_02_multi.B().foo());
  };
  dart.fn(method_override8_test_02_multi.main, VoidTodynamic());
  // Exports:
  exports.method_override8_test_02_multi = method_override8_test_02_multi;
});
