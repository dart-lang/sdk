dart_library.library('language/mixin_mixin5_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__mixin_mixin5_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const mixin_mixin5_test = Object.create(null);
  let I = () => (I = dart.constFn(mixin_mixin5_test.I$()))();
  let J = () => (J = dart.constFn(mixin_mixin5_test.J$()))();
  let K = () => (K = dart.constFn(mixin_mixin5_test.K$()))();
  let S = () => (S = dart.constFn(mixin_mixin5_test.S$()))();
  let M = () => (M = dart.constFn(mixin_mixin5_test.M$()))();
  let A = () => (A = dart.constFn(mixin_mixin5_test.A$()))();
  let B = () => (B = dart.constFn(mixin_mixin5_test.B$()))();
  let C = () => (C = dart.constFn(mixin_mixin5_test.C$()))();
  let COfint = () => (COfint = dart.constFn(mixin_mixin5_test.C$(core.int)))();
  let KOfint = () => (KOfint = dart.constFn(mixin_mixin5_test.K$(core.int)))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let JOfListOfint = () => (JOfListOfint = dart.constFn(mixin_mixin5_test.J$(ListOfint())))();
  let SetOfListOfint = () => (SetOfListOfint = dart.constFn(core.Set$(ListOfint())))();
  let IOfSetOfListOfint = () => (IOfSetOfListOfint = dart.constFn(mixin_mixin5_test.I$(SetOfListOfint())))();
  let SOfListOfint = () => (SOfListOfint = dart.constFn(mixin_mixin5_test.S$(ListOfint())))();
  let AOfListOfint$SetOfListOfint = () => (AOfListOfint$SetOfListOfint = dart.constFn(mixin_mixin5_test.A$(ListOfint(), SetOfListOfint())))();
  let MapOfListOfint$SetOfListOfint = () => (MapOfListOfint$SetOfListOfint = dart.constFn(core.Map$(ListOfint(), SetOfListOfint())))();
  let MOfMapOfListOfint$SetOfListOfint = () => (MOfMapOfListOfint$SetOfListOfint = dart.constFn(mixin_mixin5_test.M$(MapOfListOfint$SetOfListOfint())))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  mixin_mixin5_test.I$ = dart.generic(T => {
    class I extends core.Object {}
    dart.addTypeTests(I);
    return I;
  });
  mixin_mixin5_test.I = I();
  mixin_mixin5_test.J$ = dart.generic(T => {
    class J extends core.Object {}
    dart.addTypeTests(J);
    return J;
  });
  mixin_mixin5_test.J = J();
  mixin_mixin5_test.K$ = dart.generic(T => {
    class K extends core.Object {}
    dart.addTypeTests(K);
    return K;
  });
  mixin_mixin5_test.K = K();
  mixin_mixin5_test.S$ = dart.generic(T => {
    class S extends core.Object {}
    dart.addTypeTests(S);
    return S;
  });
  mixin_mixin5_test.S = S();
  mixin_mixin5_test.M$ = dart.generic(T => {
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
  mixin_mixin5_test.M = M();
  mixin_mixin5_test.A$ = dart.generic((U, V) => {
    class A extends dart.mixin(core.Object, mixin_mixin5_test.M$(core.Map$(U, V))) {}
    return A;
  });
  mixin_mixin5_test.A = A();
  mixin_mixin5_test.B$ = dart.generic(T => {
    class B extends dart.mixin(core.Object, mixin_mixin5_test.A$(T, core.Set$(T))) {}
    return B;
  });
  mixin_mixin5_test.B = B();
  mixin_mixin5_test.C$ = dart.generic(T => {
    class C extends dart.mixin(mixin_mixin5_test.S$(core.List$(T)), mixin_mixin5_test.B$(core.List$(T))) {
      new() {
        super.new();
      }
    }
    return C;
  });
  mixin_mixin5_test.C = C();
  mixin_mixin5_test.main = function() {
    let c = new (COfint())();
    expect$.Expect.equals("Map<List<int>, Set<List<int>>>", dart.toString(c.m()));
    expect$.Expect.isTrue(KOfint().is(c));
    expect$.Expect.isTrue(JOfListOfint().is(c));
    expect$.Expect.isTrue(IOfSetOfListOfint().is(c));
    expect$.Expect.isTrue(SOfListOfint().is(c));
    expect$.Expect.isTrue(AOfListOfint$SetOfListOfint().is(c));
    expect$.Expect.isTrue(MOfMapOfListOfint$SetOfListOfint().is(c));
  };
  dart.fn(mixin_mixin5_test.main, VoidTodynamic());
  // Exports:
  exports.mixin_mixin5_test = mixin_mixin5_test;
});
