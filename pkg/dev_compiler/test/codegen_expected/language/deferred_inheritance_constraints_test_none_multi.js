dart_library.library('language/deferred_inheritance_constraints_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__deferred_inheritance_constraints_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const deferred_inheritance_constraints_test_none_multi = Object.create(null);
  const deferred_inheritance_constraints_lib = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  deferred_inheritance_constraints_test_none_multi.Foo = class Foo extends core.Object {};
  deferred_inheritance_constraints_test_none_multi.D = class D extends core.Object {
    new() {
    }
    static factory() {
      return new deferred_inheritance_constraints_test_none_multi.Foo2();
    }
  };
  dart.setSignature(deferred_inheritance_constraints_test_none_multi.D, {
    constructors: () => ({
      new: dart.definiteFunctionType(deferred_inheritance_constraints_test_none_multi.D, []),
      factory: dart.definiteFunctionType(deferred_inheritance_constraints_test_none_multi.D, [])
    })
  });
  deferred_inheritance_constraints_test_none_multi.Foo2 = class Foo2 extends deferred_inheritance_constraints_test_none_multi.D {
    new() {
      super.new();
    }
  };
  deferred_inheritance_constraints_test_none_multi.A = class A extends deferred_inheritance_constraints_test_none_multi.Foo {};
  deferred_inheritance_constraints_test_none_multi.B = class B extends core.Object {};
  deferred_inheritance_constraints_test_none_multi.B[dart.implements] = () => [deferred_inheritance_constraints_test_none_multi.Foo];
  deferred_inheritance_constraints_test_none_multi.C1 = class C1 extends core.Object {};
  deferred_inheritance_constraints_test_none_multi.C = class C extends dart.mixin(deferred_inheritance_constraints_test_none_multi.C1, deferred_inheritance_constraints_test_none_multi.Foo) {
    new() {
      super.new();
    }
  };
  deferred_inheritance_constraints_test_none_multi.main = function() {
    new deferred_inheritance_constraints_test_none_multi.A();
    new deferred_inheritance_constraints_test_none_multi.B();
    new deferred_inheritance_constraints_test_none_multi.C();
    deferred_inheritance_constraints_test_none_multi.D.factory();
  };
  dart.fn(deferred_inheritance_constraints_test_none_multi.main, VoidTovoid());
  deferred_inheritance_constraints_lib.Foo = class Foo extends core.Object {};
  deferred_inheritance_constraints_lib.Foo2 = class Foo2 extends core.Object {};
  // Exports:
  exports.deferred_inheritance_constraints_test_none_multi = deferred_inheritance_constraints_test_none_multi;
  exports.deferred_inheritance_constraints_lib = deferred_inheritance_constraints_lib;
});
