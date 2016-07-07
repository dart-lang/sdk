dart_library.library('language/method_override7_test_03_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__method_override7_test_03_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const method_override7_test_03_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  method_override7_test_03_multi.A = class A extends core.Object {
    set foo(value) {}
  };
  method_override7_test_03_multi.B = class B extends method_override7_test_03_multi.A {
    static foo() {
      return 42;
    }
  };
  dart.setSignature(method_override7_test_03_multi.B, {
    statics: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['foo']
  });
  method_override7_test_03_multi.main = function() {
    expect$.Expect.equals(42, method_override7_test_03_multi.B.foo());
  };
  dart.fn(method_override7_test_03_multi.main, VoidTodynamic());
  // Exports:
  exports.method_override7_test_03_multi = method_override7_test_03_multi;
});
