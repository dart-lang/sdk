dart_library.library('language/super_inferrer_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__super_inferrer_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const super_inferrer_test = Object.create(null);
  let JSArrayOfA = () => (JSArrayOfA = dart.constFn(_interceptors.JSArray$(super_inferrer_test.A)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  super_inferrer_test.A = class A extends core.Object {
    foo(a) {
      return dart.dsend(a, '+', 42);
    }
  };
  dart.setSignature(super_inferrer_test.A, {
    methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
  });
  super_inferrer_test.B = class B extends super_inferrer_test.A {
    bar() {
      super.foo(null);
    }
  };
  dart.setSignature(super_inferrer_test.B, {
    methods: () => ({bar: dart.definiteFunctionType(dart.dynamic, [])})
  });
  dart.defineLazy(super_inferrer_test, {
    get a() {
      return JSArrayOfA().of([new super_inferrer_test.A()]);
    },
    set a(_) {}
  });
  super_inferrer_test.main = function() {
    super_inferrer_test.analyzeFirst();
    super_inferrer_test.analyzeSecond();
  };
  dart.fn(super_inferrer_test.main, VoidTodynamic());
  super_inferrer_test.analyzeFirst = function() {
    expect$.Expect.equals(84, super_inferrer_test.a[dartx.get](0).foo(42));
  };
  dart.fn(super_inferrer_test.analyzeFirst, VoidTodynamic());
  super_inferrer_test.analyzeSecond = function() {
    expect$.Expect.throws(dart.fn(() => new super_inferrer_test.B().bar(), VoidTovoid()), dart.fn(e => core.NoSuchMethodError.is(e), dynamicTobool()));
  };
  dart.fn(super_inferrer_test.analyzeSecond, VoidTodynamic());
  // Exports:
  exports.super_inferrer_test = super_inferrer_test;
});
