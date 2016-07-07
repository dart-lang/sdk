dart_library.library('language/constructor11_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__constructor11_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const constructor11_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  constructor11_test.A = class A extends core.Object {
    new(x) {
      if (x === void 0) x = 499;
      this.x = x;
    }
  };
  dart.setSignature(constructor11_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(constructor11_test.A, [], [dart.dynamic])})
  });
  constructor11_test.B = class B extends constructor11_test.A {
    new() {
      super.new();
    }
  };
  constructor11_test.X = class X extends core.Object {
    new(x) {
      if (x === void 0) x = 42;
      this.x = x;
    }
  };
  dart.setSignature(constructor11_test.X, {
    constructors: () => ({new: dart.definiteFunctionType(constructor11_test.X, [], [dart.dynamic])})
  });
  constructor11_test.Y = class Y extends constructor11_test.X {
    new() {
      super.new();
    }
  };
  constructor11_test.Z = class Z extends constructor11_test.Y {
    new() {
    }
  };
  dart.setSignature(constructor11_test.Z, {
    constructors: () => ({new: dart.definiteFunctionType(constructor11_test.Z, [])})
  });
  constructor11_test.F = class F extends core.Object {
    new(x) {
      if (x === void 0) x = 99;
      this.x = x;
    }
  };
  dart.setSignature(constructor11_test.F, {
    constructors: () => ({new: dart.definiteFunctionType(constructor11_test.F, [], [dart.dynamic])})
  });
  constructor11_test.G = class G extends constructor11_test.F {
    new() {
      super.new();
    }
  };
  constructor11_test.H = class H extends constructor11_test.G {};
  constructor11_test.main = function() {
    expect$.Expect.equals(499, new constructor11_test.B().x);
    expect$.Expect.equals(42, new constructor11_test.Z().x);
    expect$.Expect.equals(99, new constructor11_test.H().x);
  };
  dart.fn(constructor11_test.main, VoidTodynamic());
  // Exports:
  exports.constructor11_test = constructor11_test;
});
