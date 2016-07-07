dart_library.library('language/class_codegen_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__class_codegen_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const class_codegen_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  class_codegen_test.A = class A extends core.Object {
    new() {
      this.x = 3;
    }
    foo() {
      return this.x;
    }
  };
  dart.setSignature(class_codegen_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(class_codegen_test.A, [])}),
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])})
  });
  class_codegen_test.B = class B extends class_codegen_test.A {
    new() {
      super.new();
    }
    bar() {
      return 499;
    }
  };
  dart.setSignature(class_codegen_test.B, {
    methods: () => ({bar: dart.definiteFunctionType(dart.dynamic, [])})
  });
  class_codegen_test.C = class C extends class_codegen_test.A {
    new() {
      super.new();
    }
    bar() {
      return 42;
    }
  };
  dart.setSignature(class_codegen_test.C, {
    methods: () => ({bar: dart.definiteFunctionType(dart.dynamic, [])})
  });
  class_codegen_test.main = function() {
    let b = new class_codegen_test.B();
    let c = new class_codegen_test.C();
    expect$.Expect.equals(3, b.foo());
    expect$.Expect.equals(3, c.foo());
    expect$.Expect.equals(499, b.bar());
    expect$.Expect.equals(42, c.bar());
  };
  dart.fn(class_codegen_test.main, VoidTodynamic());
  // Exports:
  exports.class_codegen_test = class_codegen_test;
});
