dart_library.library('language/constructor_default_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__constructor_default_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const constructor_default_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  constructor_default_test.A = class A extends core.Object {
    new() {
      this.a = 499;
    }
  };
  dart.setSignature(constructor_default_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(constructor_default_test.A, [])})
  });
  constructor_default_test.B = class B extends constructor_default_test.A {
    new() {
      super.new();
      expect$.Expect.equals(499, this.a);
    }
  };
  dart.setSignature(constructor_default_test.B, {
    constructors: () => ({new: dart.definiteFunctionType(constructor_default_test.B, [])})
  });
  constructor_default_test.main = function() {
    new constructor_default_test.B();
  };
  dart.fn(constructor_default_test.main, VoidTodynamic());
  // Exports:
  exports.constructor_default_test = constructor_default_test;
});
