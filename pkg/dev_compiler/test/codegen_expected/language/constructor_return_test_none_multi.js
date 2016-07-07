dart_library.library('language/constructor_return_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__constructor_return_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const constructor_return_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  constructor_return_test_none_multi.A = class A extends core.Object {
    new(x) {
      this.x = x;
      return;
    }
    test1(x) {
      this.x = x;
    }
    test2(x) {
      this.x = x;
    }
    foo(y) {
      return dart.notNull(this.x) + dart.notNull(y);
    }
  };
  dart.defineNamedConstructor(constructor_return_test_none_multi.A, 'test1');
  dart.defineNamedConstructor(constructor_return_test_none_multi.A, 'test2');
  dart.setSignature(constructor_return_test_none_multi.A, {
    constructors: () => ({
      new: dart.definiteFunctionType(constructor_return_test_none_multi.A, [core.int]),
      test1: dart.definiteFunctionType(constructor_return_test_none_multi.A, [core.int]),
      test2: dart.definiteFunctionType(constructor_return_test_none_multi.A, [core.int])
    }),
    methods: () => ({foo: dart.definiteFunctionType(core.int, [core.int])})
  });
  constructor_return_test_none_multi.B = class B extends core.Object {};
  constructor_return_test_none_multi.C = class C extends core.Object {
    new() {
      this.value = null;
    }
  };
  constructor_return_test_none_multi.D = class D extends core.Object {
    new() {
      this.value = null;
    }
  };
  constructor_return_test_none_multi.main = function() {
    expect$.Expect.equals(new constructor_return_test_none_multi.A(1).foo(10), 11);
    expect$.Expect.equals(new constructor_return_test_none_multi.A.test1(1).foo(10), 11);
    expect$.Expect.equals(new constructor_return_test_none_multi.A.test2(1).foo(10), 11);
    new constructor_return_test_none_multi.B();
    new constructor_return_test_none_multi.C();
    new constructor_return_test_none_multi.D();
  };
  dart.fn(constructor_return_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.constructor_return_test_none_multi = constructor_return_test_none_multi;
});
