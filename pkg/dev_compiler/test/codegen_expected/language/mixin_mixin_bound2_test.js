dart_library.library('language/mixin_mixin_bound2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__mixin_mixin_bound2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const mixin_mixin_bound2_test = Object.create(null);
  let I = () => (I = dart.constFn(mixin_mixin_bound2_test.I$()))();
  let J = () => (J = dart.constFn(mixin_mixin_bound2_test.J$()))();
  let K = () => (K = dart.constFn(mixin_mixin_bound2_test.K$()))();
  let S = () => (S = dart.constFn(mixin_mixin_bound2_test.S$()))();
  let M = () => (M = dart.constFn(mixin_mixin_bound2_test.M$()))();
  let A = () => (A = dart.constFn(mixin_mixin_bound2_test.A$()))();
  let B = () => (B = dart.constFn(mixin_mixin_bound2_test.B$()))();
  let C = () => (C = dart.constFn(mixin_mixin_bound2_test.C$()))();
  let COfint = () => (COfint = dart.constFn(mixin_mixin_bound2_test.C$(core.int)))();
  let KOfint = () => (KOfint = dart.constFn(mixin_mixin_bound2_test.K$(core.int)))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let JOfListOfint = () => (JOfListOfint = dart.constFn(mixin_mixin_bound2_test.J$(ListOfint())))();
  let SetOfListOfint = () => (SetOfListOfint = dart.constFn(core.Set$(ListOfint())))();
  let IOfSetOfListOfint = () => (IOfSetOfListOfint = dart.constFn(mixin_mixin_bound2_test.I$(SetOfListOfint())))();
  let SetOfint = () => (SetOfint = dart.constFn(core.Set$(core.int)))();
  let SOfSetOfint$int = () => (SOfSetOfint$int = dart.constFn(mixin_mixin_bound2_test.S$(SetOfint(), core.int)))();
  let AOfListOfint$SetOfListOfint = () => (AOfListOfint$SetOfListOfint = dart.constFn(mixin_mixin_bound2_test.A$(ListOfint(), SetOfListOfint())))();
  let MapOfListOfint$SetOfListOfint = () => (MapOfListOfint$SetOfListOfint = dart.constFn(core.Map$(ListOfint(), SetOfListOfint())))();
  let MOfListOfint$SetOfListOfint$MapOfListOfint$SetOfListOfint = () => (MOfListOfint$SetOfListOfint$MapOfListOfint$SetOfListOfint = dart.constFn(mixin_mixin_bound2_test.M$(ListOfint(), SetOfListOfint(), MapOfListOfint$SetOfListOfint())))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  mixin_mixin_bound2_test.I$ = dart.generic(T => {
    class I extends core.Object {}
    dart.addTypeTests(I);
    return I;
  });
  mixin_mixin_bound2_test.I = I();
  mixin_mixin_bound2_test.J$ = dart.generic(T => {
    class J extends core.Object {}
    dart.addTypeTests(J);
    return J;
  });
  mixin_mixin_bound2_test.J = J();
  mixin_mixin_bound2_test.K$ = dart.generic(T => {
    class K extends core.Object {}
    dart.addTypeTests(K);
    return K;
  });
  mixin_mixin_bound2_test.K = K();
  mixin_mixin_bound2_test.S$ = dart.generic((U, V) => {
    class S extends core.Object {}
    dart.addTypeTests(S);
    return S;
  });
  mixin_mixin_bound2_test.S = S();
  mixin_mixin_bound2_test.M$ = dart.generic((U, V, T) => {
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
  mixin_mixin_bound2_test.M = M();
  mixin_mixin_bound2_test.A$ = dart.generic((U, V) => {
    class A extends dart.mixin(core.Object, mixin_mixin_bound2_test.M$(U, V, core.Map$(U, V))) {}
    return A;
  });
  mixin_mixin_bound2_test.A = A();
  mixin_mixin_bound2_test.B$ = dart.generic(T => {
    class B extends dart.mixin(core.Object, mixin_mixin_bound2_test.A$(T, core.Set$(T))) {}
    return B;
  });
  mixin_mixin_bound2_test.B = B();
  mixin_mixin_bound2_test.C$ = dart.generic(T => {
    class C extends dart.mixin(mixin_mixin_bound2_test.S$(core.Set$(T), T), mixin_mixin_bound2_test.B$(core.List$(T))) {
      new() {
        super.new();
      }
    }
    return C;
  });
  mixin_mixin_bound2_test.C = C();
  mixin_mixin_bound2_test.main = function() {
    let c = new (COfint())();
    expect$.Expect.equals("Map<List<int>, Set<List<int>>>", dart.toString(c.m()));
    expect$.Expect.isTrue(KOfint().is(c));
    expect$.Expect.isTrue(JOfListOfint().is(c));
    expect$.Expect.isTrue(IOfSetOfListOfint().is(c));
    expect$.Expect.isTrue(SOfSetOfint$int().is(c));
    expect$.Expect.isTrue(AOfListOfint$SetOfListOfint().is(c));
    expect$.Expect.isTrue(MOfListOfint$SetOfListOfint$MapOfListOfint$SetOfListOfint().is(c));
  };
  dart.fn(mixin_mixin_bound2_test.main, VoidTodynamic());
  // Exports:
  exports.mixin_mixin_bound2_test = mixin_mixin_bound2_test;
});
