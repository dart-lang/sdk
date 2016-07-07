dart_library.library('language/library_private_in_constructor_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__library_private_in_constructor_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const library_private_in_constructor_test = Object.create(null);
  const library_private_in_constructor_a = Object.create(null);
  const library_private_in_constructor_b = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  library_private_in_constructor_test.main = function() {
    let b = new library_private_in_constructor_b.B();
    expect$.Expect.equals(499, b.x);
    expect$.Expect.equals(42, b.y);
  };
  dart.fn(library_private_in_constructor_test.main, VoidTodynamic());
  const _val = Symbol('_val');
  library_private_in_constructor_a.PrivateA = class PrivateA extends core.Object {
    new() {
      this[_val] = 499;
    }
  };
  dart.setSignature(library_private_in_constructor_a.PrivateA, {
    constructors: () => ({new: dart.definiteFunctionType(library_private_in_constructor_a.PrivateA, [])})
  });
  library_private_in_constructor_a.fooA = dart.const(new library_private_in_constructor_a.PrivateA());
  library_private_in_constructor_a.A = class A extends core.Object {
    new() {
      this.x = library_private_in_constructor_a.fooA[_val];
    }
  };
  dart.setSignature(library_private_in_constructor_a.A, {
    constructors: () => ({new: dart.definiteFunctionType(library_private_in_constructor_a.A, [])})
  });
  const _val$ = Symbol('_val');
  library_private_in_constructor_b.PrivateB = class PrivateB extends core.Object {
    new() {
      this[_val$] = 42;
    }
  };
  dart.setSignature(library_private_in_constructor_b.PrivateB, {
    constructors: () => ({new: dart.definiteFunctionType(library_private_in_constructor_b.PrivateB, [])})
  });
  library_private_in_constructor_b.fooB = dart.const(new library_private_in_constructor_b.PrivateB());
  library_private_in_constructor_b.B = class B extends library_private_in_constructor_a.A {
    new() {
      this.y = library_private_in_constructor_b.fooB[_val$];
      super.new();
    }
  };
  dart.setSignature(library_private_in_constructor_b.B, {
    constructors: () => ({new: dart.definiteFunctionType(library_private_in_constructor_b.B, [])})
  });
  // Exports:
  exports.library_private_in_constructor_test = library_private_in_constructor_test;
  exports.library_private_in_constructor_a = library_private_in_constructor_a;
  exports.library_private_in_constructor_b = library_private_in_constructor_b;
});
