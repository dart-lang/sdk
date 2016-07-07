dart_library.library('language/mixin_mixin6_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__mixin_mixin6_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const mixin_mixin6_test = Object.create(null);
  let I = () => (I = dart.constFn(mixin_mixin6_test.I$()))();
  let J = () => (J = dart.constFn(mixin_mixin6_test.J$()))();
  let K = () => (K = dart.constFn(mixin_mixin6_test.K$()))();
  let S = () => (S = dart.constFn(mixin_mixin6_test.S$()))();
  let M = () => (M = dart.constFn(mixin_mixin6_test.M$()))();
  let A = () => (A = dart.constFn(mixin_mixin6_test.A$()))();
  let B = () => (B = dart.constFn(mixin_mixin6_test.B$()))();
  let C = () => (C = dart.constFn(mixin_mixin6_test.C$()))();
  let COfint = () => (COfint = dart.constFn(mixin_mixin6_test.C$(core.int)))();
  let KOfint = () => (KOfint = dart.constFn(mixin_mixin6_test.K$(core.int)))();
  let IOfSet = () => (IOfSet = dart.constFn(mixin_mixin6_test.I$(core.Set)))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let SOfListOfint = () => (SOfListOfint = dart.constFn(mixin_mixin6_test.S$(ListOfint())))();
  let AOfdynamic$Set = () => (AOfdynamic$Set = dart.constFn(mixin_mixin6_test.A$(dart.dynamic, core.Set)))();
  let MapOfdynamic$Set = () => (MapOfdynamic$Set = dart.constFn(core.Map$(dart.dynamic, core.Set)))();
  let MOfMapOfdynamic$Set = () => (MOfMapOfdynamic$Set = dart.constFn(mixin_mixin6_test.M$(MapOfdynamic$Set())))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  mixin_mixin6_test.I$ = dart.generic(T => {
    class I extends core.Object {}
    dart.addTypeTests(I);
    return I;
  });
  mixin_mixin6_test.I = I();
  mixin_mixin6_test.J$ = dart.generic(T => {
    class J extends core.Object {}
    dart.addTypeTests(J);
    return J;
  });
  mixin_mixin6_test.J = J();
  mixin_mixin6_test.K$ = dart.generic(T => {
    class K extends core.Object {}
    dart.addTypeTests(K);
    return K;
  });
  mixin_mixin6_test.K = K();
  mixin_mixin6_test.S$ = dart.generic(T => {
    class S extends core.Object {}
    dart.addTypeTests(S);
    return S;
  });
  mixin_mixin6_test.S = S();
  mixin_mixin6_test.M$ = dart.generic(T => {
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
  mixin_mixin6_test.M = M();
  mixin_mixin6_test.A$ = dart.generic((U, V) => {
    class A extends dart.mixin(core.Object, mixin_mixin6_test.M$(core.Map$(U, V))) {}
    return A;
  });
  mixin_mixin6_test.A = A();
  mixin_mixin6_test.B$ = dart.generic(T => {
    class B extends dart.mixin(core.Object, mixin_mixin6_test.A$(T, core.Set$(T))) {}
    return B;
  });
  mixin_mixin6_test.B = B();
  mixin_mixin6_test.C$ = dart.generic(T => {
    class C extends dart.mixin(mixin_mixin6_test.S$(core.List$(T)), mixin_mixin6_test.B) {
      new() {
        super.new();
      }
    }
    return C;
  });
  mixin_mixin6_test.C = C();
  mixin_mixin6_test.main = function() {
    let c = new (COfint())();
    expect$.Expect.equals("Map<dynamic, Set>", dart.toString(c.m()));
    expect$.Expect.isTrue(KOfint().is(c));
    expect$.Expect.isTrue(mixin_mixin6_test.J.is(c));
    expect$.Expect.isTrue(IOfSet().is(c));
    expect$.Expect.isTrue(SOfListOfint().is(c));
    expect$.Expect.isTrue(AOfdynamic$Set().is(c));
    expect$.Expect.isTrue(MOfMapOfdynamic$Set().is(c));
  };
  dart.fn(mixin_mixin6_test.main, VoidTodynamic());
  // Exports:
  exports.mixin_mixin6_test = mixin_mixin6_test;
});
