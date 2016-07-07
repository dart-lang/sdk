dart_library.library('language/multiple_field_assignment_constructor_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__multiple_field_assignment_constructor_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const multiple_field_assignment_constructor_test = Object.create(null);
  const compiler_annotations = Object.create(null);
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  dart.defineLazy(multiple_field_assignment_constructor_test, {
    get a() {
      return [null];
    },
    set a(_) {}
  });
  multiple_field_assignment_constructor_test.A = class A extends core.Object {
    new() {
      this.foo = null;
      this.bar = null;
      this.bar = dart.fn(() => 42, VoidToint());
      this.foo = 42;
      this.foo = multiple_field_assignment_constructor_test.a[dartx.get](0);
    }
  };
  dart.setSignature(multiple_field_assignment_constructor_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(multiple_field_assignment_constructor_test.A, [])})
  });
  multiple_field_assignment_constructor_test.B = class B extends core.Object {
    new() {
      this.foo = null;
      this.bar = null;
      this.bar = dart.fn(() => 42, VoidToint());
      this.foo = 42;
      this.foo = multiple_field_assignment_constructor_test.a[dartx.get](0);
      if (false) this.foo = 42;
    }
  };
  dart.setSignature(multiple_field_assignment_constructor_test.B, {
    constructors: () => ({new: dart.definiteFunctionType(multiple_field_assignment_constructor_test.B, [])})
  });
  multiple_field_assignment_constructor_test.main = function() {
    new multiple_field_assignment_constructor_test.A();
    new multiple_field_assignment_constructor_test.B();
    multiple_field_assignment_constructor_test.bar();
    new multiple_field_assignment_constructor_test.A();
    new multiple_field_assignment_constructor_test.B();
  };
  dart.fn(multiple_field_assignment_constructor_test.main, VoidTodynamic());
  multiple_field_assignment_constructor_test.bar = function() {
    expect$.Expect.throws(dart.fn(() => dart.dsend(new multiple_field_assignment_constructor_test.A().foo, '+', 42), VoidTovoid()), dart.fn(e => core.NoSuchMethodError.is(e), dynamicTobool()));
    expect$.Expect.throws(dart.fn(() => dart.dsend(new multiple_field_assignment_constructor_test.B().foo, '+', 42), VoidTovoid()), dart.fn(e => core.NoSuchMethodError.is(e), dynamicTobool()));
  };
  dart.fn(multiple_field_assignment_constructor_test.bar, VoidTodynamic());
  compiler_annotations.DontInline = class DontInline extends core.Object {
    new() {
    }
  };
  dart.setSignature(compiler_annotations.DontInline, {
    constructors: () => ({new: dart.definiteFunctionType(compiler_annotations.DontInline, [])})
  });
  // Exports:
  exports.multiple_field_assignment_constructor_test = multiple_field_assignment_constructor_test;
  exports.compiler_annotations = compiler_annotations;
});
