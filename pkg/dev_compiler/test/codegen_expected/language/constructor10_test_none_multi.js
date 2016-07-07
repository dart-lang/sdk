dart_library.library('language/constructor10_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__constructor10_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const constructor10_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  constructor10_test_none_multi.A = class A extends core.Object {
    new(x) {
      this.x = x;
    }
  };
  dart.setSignature(constructor10_test_none_multi.A, {
    constructors: () => ({new: dart.definiteFunctionType(constructor10_test_none_multi.A, [dart.dynamic])})
  });
  constructor10_test_none_multi.B = class B extends constructor10_test_none_multi.A {
    new() {
      super.new(null);
    }
  };
  dart.setSignature(constructor10_test_none_multi.B, {
    constructors: () => ({new: dart.definiteFunctionType(constructor10_test_none_multi.B, [])})
  });
  constructor10_test_none_multi.Y = class Y extends constructor10_test_none_multi.A {
    new() {
      super.new(null);
    }
  };
  dart.setSignature(constructor10_test_none_multi.Y, {
    constructors: () => ({new: dart.definiteFunctionType(constructor10_test_none_multi.Y, [])})
  });
  constructor10_test_none_multi.Z = class Z extends constructor10_test_none_multi.Y {
    new() {
      super.new();
    }
  };
  dart.setSignature(constructor10_test_none_multi.Z, {
    constructors: () => ({new: dart.definiteFunctionType(constructor10_test_none_multi.Z, [])})
  });
  constructor10_test_none_multi.G = class G extends constructor10_test_none_multi.A {
    new() {
      super.new(null);
    }
  };
  dart.setSignature(constructor10_test_none_multi.G, {
    constructors: () => ({new: dart.definiteFunctionType(constructor10_test_none_multi.G, [])})
  });
  constructor10_test_none_multi.H = class H extends constructor10_test_none_multi.G {
    new() {
      super.new();
    }
  };
  constructor10_test_none_multi.main = function() {
    new constructor10_test_none_multi.B().x;
    new constructor10_test_none_multi.Z().x;
    new constructor10_test_none_multi.H().x;
  };
  dart.fn(constructor10_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.constructor10_test_none_multi = constructor10_test_none_multi;
});
