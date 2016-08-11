dart_library.library('language/private2_test', null, /* Imports */[
  'dart_sdk'
], function load__private2_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const private2_test = Object.create(null);
  const private2_lib = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  const _f = Symbol('_f');
  private2_test.A = class A extends core.Object {
    new() {
      this[_f] = 42;
      this.g = 43;
    }
  };
  dart.setSignature(private2_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(private2_test.A, [])})
  });
  private2_lib.B = class B extends private2_test.A {
    new() {
      super.new();
    }
  };
  dart.setSignature(private2_lib.B, {
    constructors: () => ({new: dart.definiteFunctionType(private2_lib.B, [])})
  });
  private2_test.C = class C extends private2_lib.B {
    new() {
      super.new();
    }
  };
  dart.setSignature(private2_test.C, {
    constructors: () => ({new: dart.definiteFunctionType(private2_test.C, [])})
  });
  private2_test.main = function() {
    let a = new private2_test.A();
    core.print(a.g);
    core.print(a[_f]);
    let o = new private2_test.C();
    core.print(o.g);
    core.print(o[_f]);
  };
  dart.fn(private2_test.main, VoidTodynamic());
  // Exports:
  exports.private2_test = private2_test;
  exports.private2_lib = private2_lib;
});
