dart_library.library('language/super_abstract_method_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__super_abstract_method_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const super_abstract_method_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  super_abstract_method_test.Base = class Base extends core.Object {
    foo() {
      return 42;
    }
  };
  dart.setSignature(super_abstract_method_test.Base, {
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])})
  });
  super_abstract_method_test.A = class A extends super_abstract_method_test.Base {};
  super_abstract_method_test.B = class B extends super_abstract_method_test.A {
    testSuperCall() {
      return super.foo();
    }
    foo() {
      return 42;
    }
  };
  dart.setSignature(super_abstract_method_test.B, {
    methods: () => ({testSuperCall: dart.definiteFunctionType(dart.dynamic, [])})
  });
  super_abstract_method_test.main = function() {
    expect$.Expect.equals(42, new super_abstract_method_test.B().foo());
    expect$.Expect.equals(42, new super_abstract_method_test.B().testSuperCall());
  };
  dart.fn(super_abstract_method_test.main, VoidTodynamic());
  // Exports:
  exports.super_abstract_method_test = super_abstract_method_test;
});
