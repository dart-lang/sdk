dart_library.library('language/redirecting_factory_reflection_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__redirecting_factory_reflection_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const mirrors = dart_sdk.mirrors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const redirecting_factory_reflection_test = Object.create(null);
  let A = () => (A = dart.constFn(redirecting_factory_reflection_test.A$()))();
  let B = () => (B = dart.constFn(redirecting_factory_reflection_test.B$()))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  redirecting_factory_reflection_test.A$ = dart.generic(T => {
    let AOfT = () => (AOfT = dart.constFn(redirecting_factory_reflection_test.A$(T)))();
    let BOfT$AOfT = () => (BOfT$AOfT = dart.constFn(redirecting_factory_reflection_test.B$(T, AOfT())))();
    class A extends core.Object {
      static new() {
        return new (BOfT$AOfT())();
      }
    }
    dart.addTypeTests(A);
    dart.setSignature(A, {
      constructors: () => ({new: dart.definiteFunctionType(redirecting_factory_reflection_test.A$(T), [])})
    });
    return A;
  });
  redirecting_factory_reflection_test.A = A();
  redirecting_factory_reflection_test.B$ = dart.generic((X, Y) => {
    let AOfX = () => (AOfX = dart.constFn(redirecting_factory_reflection_test.A$(X)))();
    class B extends core.Object {
      new() {
        this.t = dart.wrapType(Y);
      }
    }
    dart.addTypeTests(B);
    B[dart.implements] = () => [AOfX()];
    dart.setSignature(B, {
      constructors: () => ({new: dart.definiteFunctionType(redirecting_factory_reflection_test.B$(X, Y), [])})
    });
    return B;
  });
  redirecting_factory_reflection_test.B = B();
  let const$;
  redirecting_factory_reflection_test.main = function() {
    let m = mirrors.reflectClass(dart.wrapType(redirecting_factory_reflection_test.A));
    let i = m.newInstance(const$ || (const$ = dart.const(core.Symbol.new(''))), []).reflectee;
    expect$.Expect.equals(dart.toString(dart.dload(i, 't')), 'A');
  };
  dart.fn(redirecting_factory_reflection_test.main, VoidTodynamic());
  // Exports:
  exports.redirecting_factory_reflection_test = redirecting_factory_reflection_test;
});
