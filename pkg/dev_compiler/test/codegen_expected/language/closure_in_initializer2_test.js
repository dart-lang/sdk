dart_library.library('language/closure_in_initializer2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__closure_in_initializer2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const closure_in_initializer2_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  closure_in_initializer2_test.S = class S extends core.Object {
    new() {
      expect$.Expect.equals(2, dart.dsend(this, 'f'));
    }
  };
  dart.setSignature(closure_in_initializer2_test.S, {
    constructors: () => ({new: dart.definiteFunctionType(closure_in_initializer2_test.S, [])})
  });
  closure_in_initializer2_test.A = class A extends closure_in_initializer2_test.S {
    new(a) {
      this.f = dart.fn(() => (a = dart.dsend(a, '+', 1)), VoidTodynamic());
      super.new();
      expect$.Expect.equals(a, 2);
    }
  };
  dart.setSignature(closure_in_initializer2_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(closure_in_initializer2_test.A, [dart.dynamic])})
  });
  closure_in_initializer2_test.main = function() {
    let a = new closure_in_initializer2_test.A(1);
    expect$.Expect.equals(dart.dsend(a, 'f'), 3);
  };
  dart.fn(closure_in_initializer2_test.main, VoidTodynamic());
  // Exports:
  exports.closure_in_initializer2_test = closure_in_initializer2_test;
});
