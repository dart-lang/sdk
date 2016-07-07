dart_library.library('language/constructor_body_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__constructor_body_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const constructor_body_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  constructor_body_test.First = class First extends core.Object {
    new(value) {
      this.value = value;
    }
    named(value) {
      this.value = value;
    }
  };
  dart.defineNamedConstructor(constructor_body_test.First, 'named');
  dart.setSignature(constructor_body_test.First, {
    constructors: () => ({
      new: dart.definiteFunctionType(constructor_body_test.First, [core.int]),
      named: dart.definiteFunctionType(constructor_body_test.First, [core.int])
    })
  });
  constructor_body_test.Second = class Second extends core.Object {
    new(value) {
      this.value = value;
    }
    named(value) {
      this.value = value;
    }
  };
  dart.defineNamedConstructor(constructor_body_test.Second, 'named');
  dart.setSignature(constructor_body_test.Second, {
    constructors: () => ({
      new: dart.definiteFunctionType(constructor_body_test.Second, [core.int]),
      named: dart.definiteFunctionType(constructor_body_test.Second, [core.int])
    })
  });
  constructor_body_test.ConstructorBodyTest = class ConstructorBodyTest extends core.Object {
    static testMain() {
      expect$.Expect.equals(4, new constructor_body_test.First(4).value);
      expect$.Expect.equals(5, new constructor_body_test.First.named(5).value);
      expect$.Expect.equals(6, new constructor_body_test.Second(6).value);
      expect$.Expect.equals(7, new constructor_body_test.Second.named(7).value);
    }
  };
  dart.setSignature(constructor_body_test.ConstructorBodyTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  constructor_body_test.main = function() {
    constructor_body_test.ConstructorBodyTest.testMain();
  };
  dart.fn(constructor_body_test.main, VoidTodynamic());
  // Exports:
  exports.constructor_body_test = constructor_body_test;
});
