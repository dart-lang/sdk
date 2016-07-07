dart_library.library('language/generic_instanceof3_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__generic_instanceof3_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const generic_instanceof3_test = Object.create(null);
  let I = () => (I = dart.constFn(generic_instanceof3_test.I$()))();
  let IOfbool = () => (IOfbool = dart.constFn(generic_instanceof3_test.I$(core.bool)))();
  let B = () => (B = dart.constFn(generic_instanceof3_test.B$()))();
  let K = () => (K = dart.constFn(generic_instanceof3_test.K$()))();
  let L = () => (L = dart.constFn(generic_instanceof3_test.L$()))();
  let LOfString = () => (LOfString = dart.constFn(generic_instanceof3_test.L$(core.String)))();
  let BOfString = () => (BOfString = dart.constFn(generic_instanceof3_test.B$(core.String)))();
  let IOfString = () => (IOfString = dart.constFn(generic_instanceof3_test.I$(core.String)))();
  let KOfString = () => (KOfString = dart.constFn(generic_instanceof3_test.K$(core.String)))();
  let LOfbool = () => (LOfbool = dart.constFn(generic_instanceof3_test.L$(core.bool)))();
  let KOfbool = () => (KOfbool = dart.constFn(generic_instanceof3_test.K$(core.bool)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  generic_instanceof3_test.I$ = dart.generic(T => {
    class I extends core.Object {}
    dart.addTypeTests(I);
    return I;
  });
  generic_instanceof3_test.I = I();
  generic_instanceof3_test.A = class A extends core.Object {};
  generic_instanceof3_test.A[dart.implements] = () => [IOfbool()];
  generic_instanceof3_test.B$ = dart.generic(T => {
    class B extends core.Object {}
    dart.addTypeTests(B);
    B[dart.implements] = () => [IOfbool()];
    return B;
  });
  generic_instanceof3_test.B = B();
  generic_instanceof3_test.K$ = dart.generic(T => {
    class K extends core.Object {}
    dart.addTypeTests(K);
    return K;
  });
  generic_instanceof3_test.K = K();
  generic_instanceof3_test.L$ = dart.generic(T => {
    class L extends generic_instanceof3_test.K$(core.bool) {}
    return L;
  });
  generic_instanceof3_test.L = L();
  generic_instanceof3_test.C = class C extends core.Object {};
  generic_instanceof3_test.C[dart.implements] = () => [LOfString()];
  generic_instanceof3_test.D = class D extends core.Object {};
  generic_instanceof3_test.D[dart.implements] = () => [BOfString()];
  generic_instanceof3_test.main = function() {
    let a = new generic_instanceof3_test.A();
    let b = new (BOfString())();
    let c = new generic_instanceof3_test.C();
    let d = new generic_instanceof3_test.D();
    for (let i = 0; i < 5; i++) {
      expect$.Expect.isFalse(IOfString().is(a));
      expect$.Expect.isTrue(IOfbool().is(a));
      expect$.Expect.isFalse(IOfString().is(b));
      expect$.Expect.isFalse(KOfString().is(c));
      expect$.Expect.isFalse(KOfString().is(c));
      expect$.Expect.isTrue(LOfString().is(c));
      expect$.Expect.isFalse(LOfbool().is(c));
      expect$.Expect.isTrue(KOfbool().is(c));
      expect$.Expect.isFalse(KOfString().is(c));
      expect$.Expect.isFalse(IOfString().is(d));
      expect$.Expect.isTrue(IOfbool().is(d));
    }
  };
  dart.fn(generic_instanceof3_test.main, VoidTodynamic());
  // Exports:
  exports.generic_instanceof3_test = generic_instanceof3_test;
});
