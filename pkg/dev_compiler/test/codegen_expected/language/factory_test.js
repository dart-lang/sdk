dart_library.library('language/factory_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__factory_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const factory_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  factory_test.A = class A extends core.Object {
    static new(n) {
      return new factory_test.A.internal(n);
    }
    internal(n) {
      this.n_ = n;
    }
  };
  dart.defineNamedConstructor(factory_test.A, 'internal');
  dart.setSignature(factory_test.A, {
    constructors: () => ({
      new: dart.definiteFunctionType(factory_test.A, [dart.dynamic]),
      internal: dart.definiteFunctionType(factory_test.A, [dart.dynamic])
    })
  });
  factory_test.B = class B extends core.Object {
    static my() {
      return new factory_test.B(3);
    }
    new(n) {
      this.n_ = n;
    }
  };
  dart.setSignature(factory_test.B, {
    constructors: () => ({
      my: dart.definiteFunctionType(factory_test.B, []),
      new: dart.definiteFunctionType(factory_test.B, [dart.dynamic])
    })
  });
  factory_test.FactoryTest = class FactoryTest extends core.Object {
    static testMain() {
      factory_test.B.my();
      let b = factory_test.B.my();
      expect$.Expect.equals(3, b.n_);
      let a = factory_test.A.new(5);
      expect$.Expect.equals(5, a.n_);
    }
  };
  dart.setSignature(factory_test.FactoryTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  factory_test.main = function() {
    factory_test.FactoryTest.testMain();
  };
  dart.fn(factory_test.main, VoidTodynamic());
  // Exports:
  exports.factory_test = factory_test;
});
