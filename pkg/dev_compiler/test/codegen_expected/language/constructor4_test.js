dart_library.library('language/constructor4_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__constructor4_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const constructor4_test = Object.create(null);
  let intToint = () => (intToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  constructor4_test.trace = "";
  constructor4_test.E = function(i) {
    constructor4_test.trace = dart.notNull(constructor4_test.trace) + dart.str`${i}-`;
    return i;
  };
  dart.fn(constructor4_test.E, intToint());
  constructor4_test.A = class A extends core.Object {
    new() {
      this.a1 = constructor4_test.E(2);
      constructor4_test.E(3);
    }
  };
  dart.setSignature(constructor4_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(constructor4_test.A, [])})
  });
  constructor4_test.B = class B extends constructor4_test.A {
    new(x) {
      this.b1 = constructor4_test.E(1);
      super.new();
      constructor4_test.E(4);
    }
  };
  dart.setSignature(constructor4_test.B, {
    constructors: () => ({new: dart.definiteFunctionType(constructor4_test.B, [dart.dynamic])})
  });
  constructor4_test.main = function() {
    let b = new constructor4_test.B(0);
    expect$.Expect.equals("1-2-3-4-", constructor4_test.trace);
  };
  dart.fn(constructor4_test.main, VoidTodynamic());
  // Exports:
  exports.constructor4_test = constructor4_test;
});
