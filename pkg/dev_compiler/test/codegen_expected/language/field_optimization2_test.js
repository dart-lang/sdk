dart_library.library('language/field_optimization2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__field_optimization2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const field_optimization2_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  field_optimization2_test.A = class A extends core.Object {
    new() {
      this.x = new field_optimization2_test.B();
    }
    foo() {
      this.x = dart.dsend(this.x, '+', 1);
    }
  };
  dart.setSignature(field_optimization2_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(field_optimization2_test.A, [])}),
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])})
  });
  field_optimization2_test.B = class B extends core.Object {
    ['+'](other) {
      return 498;
    }
  };
  dart.setSignature(field_optimization2_test.B, {
    methods: () => ({'+': dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
  });
  field_optimization2_test.main = function() {
    let a = new field_optimization2_test.A();
    a.foo();
    a.foo();
    expect$.Expect.equals(499, a.x);
  };
  dart.fn(field_optimization2_test.main, VoidTodynamic());
  // Exports:
  exports.field_optimization2_test = field_optimization2_test;
});
