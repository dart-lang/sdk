dart_library.library('language/generic_instanceof4_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__generic_instanceof4_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const generic_instanceof4_test = Object.create(null);
  let A = () => (A = dart.constFn(generic_instanceof4_test.A$()))();
  let B = () => (B = dart.constFn(generic_instanceof4_test.B$()))();
  let BOfBB = () => (BOfBB = dart.constFn(generic_instanceof4_test.B$(generic_instanceof4_test.BB)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  generic_instanceof4_test.A$ = dart.generic(T => {
    class A extends core.Object {
      foo(x) {
        if (new core.DateTime.now().millisecondsSinceEpoch == 42) return this.foo(x);
        return T.is(x);
      }
    }
    dart.addTypeTests(A);
    dart.setSignature(A, {
      methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [dart.dynamic])})
    });
    return A;
  });
  generic_instanceof4_test.A = A();
  generic_instanceof4_test.BB = class BB extends core.Object {};
  generic_instanceof4_test.B$ = dart.generic(T => {
    let AOfT = () => (AOfT = dart.constFn(generic_instanceof4_test.A$(T)))();
    class B extends core.Object {
      foo() {
        if (new core.DateTime.now().millisecondsSinceEpoch == 42) return this.foo();
        return new (AOfT())().foo(new generic_instanceof4_test.B());
      }
    }
    dart.addTypeTests(B);
    B[dart.implements] = () => [generic_instanceof4_test.BB];
    dart.setSignature(B, {
      methods: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])})
    });
    return B;
  });
  generic_instanceof4_test.B = B();
  generic_instanceof4_test.main = function() {
    expect$.Expect.isTrue(new (BOfBB())().foo());
  };
  dart.fn(generic_instanceof4_test.main, VoidTodynamic());
  // Exports:
  exports.generic_instanceof4_test = generic_instanceof4_test;
});
