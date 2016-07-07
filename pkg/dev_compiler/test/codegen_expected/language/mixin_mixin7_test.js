dart_library.library('language/mixin_mixin7_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__mixin_mixin7_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const mixin_mixin7_test = Object.create(null);
  let I = () => (I = dart.constFn(mixin_mixin7_test.I$()))();
  let J = () => (J = dart.constFn(mixin_mixin7_test.J$()))();
  let K = () => (K = dart.constFn(mixin_mixin7_test.K$()))();
  let S = () => (S = dart.constFn(mixin_mixin7_test.S$()))();
  let M = () => (M = dart.constFn(mixin_mixin7_test.M$()))();
  let A = () => (A = dart.constFn(mixin_mixin7_test.A$()))();
  let B = () => (B = dart.constFn(mixin_mixin7_test.B$()))();
  let C = () => (C = dart.constFn(mixin_mixin7_test.C$()))();
  let COfint = () => (COfint = dart.constFn(mixin_mixin7_test.C$(core.int)))();
  let KOfint = () => (KOfint = dart.constFn(mixin_mixin7_test.K$(core.int)))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let SOfListOfint = () => (SOfListOfint = dart.constFn(mixin_mixin7_test.S$(ListOfint())))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  mixin_mixin7_test.I$ = dart.generic(T => {
    class I extends core.Object {}
    dart.addTypeTests(I);
    return I;
  });
  mixin_mixin7_test.I = I();
  mixin_mixin7_test.J$ = dart.generic(T => {
    class J extends core.Object {}
    dart.addTypeTests(J);
    return J;
  });
  mixin_mixin7_test.J = J();
  mixin_mixin7_test.K$ = dart.generic(T => {
    class K extends core.Object {}
    dart.addTypeTests(K);
    return K;
  });
  mixin_mixin7_test.K = K();
  mixin_mixin7_test.S$ = dart.generic(T => {
    class S extends core.Object {}
    dart.addTypeTests(S);
    return S;
  });
  mixin_mixin7_test.S = S();
  mixin_mixin7_test.M$ = dart.generic(T => {
    class M extends core.Object {
      m() {
        return dart.wrapType(T);
      }
    }
    dart.addTypeTests(M);
    dart.setSignature(M, {
      methods: () => ({m: dart.definiteFunctionType(dart.dynamic, [])})
    });
    return M;
  });
  mixin_mixin7_test.M = M();
  mixin_mixin7_test.A$ = dart.generic((U, V) => {
    class A extends dart.mixin(core.Object, mixin_mixin7_test.M) {}
    return A;
  });
  mixin_mixin7_test.A = A();
  mixin_mixin7_test.B$ = dart.generic(T => {
    class B extends dart.mixin(core.Object, mixin_mixin7_test.A) {}
    return B;
  });
  mixin_mixin7_test.B = B();
  mixin_mixin7_test.C$ = dart.generic(T => {
    class C extends dart.mixin(mixin_mixin7_test.S$(core.List$(T)), mixin_mixin7_test.B) {
      new() {
        super.new();
      }
    }
    return C;
  });
  mixin_mixin7_test.C = C();
  mixin_mixin7_test.main = function() {
    let c = new (COfint())();
    expect$.Expect.equals("dynamic", dart.toString(c.m()));
    expect$.Expect.isTrue(KOfint().is(c));
    expect$.Expect.isTrue(mixin_mixin7_test.J.is(c));
    expect$.Expect.isTrue(mixin_mixin7_test.I.is(c));
    expect$.Expect.isTrue(SOfListOfint().is(c));
    expect$.Expect.isTrue(mixin_mixin7_test.A.is(c));
    expect$.Expect.isTrue(mixin_mixin7_test.M.is(c));
  };
  dart.fn(mixin_mixin7_test.main, VoidTodynamic());
  // Exports:
  exports.mixin_mixin7_test = mixin_mixin7_test;
});
