dart_library.library('language/mixin_mixin_bound_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__mixin_mixin_bound_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const mixin_mixin_bound_test = Object.create(null);
  let I = () => (I = dart.constFn(mixin_mixin_bound_test.I$()))();
  let J = () => (J = dart.constFn(mixin_mixin_bound_test.J$()))();
  let S = () => (S = dart.constFn(mixin_mixin_bound_test.S$()))();
  let M = () => (M = dart.constFn(mixin_mixin_bound_test.M$()))();
  let A = () => (A = dart.constFn(mixin_mixin_bound_test.A$()))();
  let C = () => (C = dart.constFn(mixin_mixin_bound_test.C$()))();
  let COfint$bool = () => (COfint$bool = dart.constFn(mixin_mixin_bound_test.C$(core.int, core.bool)))();
  let ListOfbool = () => (ListOfbool = dart.constFn(core.List$(core.bool)))();
  let IOfListOfbool = () => (IOfListOfbool = dart.constFn(mixin_mixin_bound_test.I$(ListOfbool())))();
  let JOfbool = () => (JOfbool = dart.constFn(mixin_mixin_bound_test.J$(core.bool)))();
  let SetOfint = () => (SetOfint = dart.constFn(core.Set$(core.int)))();
  let SOfSetOfint$int = () => (SOfSetOfint$int = dart.constFn(mixin_mixin_bound_test.S$(SetOfint(), core.int)))();
  let AOfint$ListOfbool = () => (AOfint$ListOfbool = dart.constFn(mixin_mixin_bound_test.A$(core.int, ListOfbool())))();
  let MapOfint$ListOfbool = () => (MapOfint$ListOfbool = dart.constFn(core.Map$(core.int, ListOfbool())))();
  let MOfint$ListOfbool$MapOfint$ListOfbool = () => (MOfint$ListOfbool$MapOfint$ListOfbool = dart.constFn(mixin_mixin_bound_test.M$(core.int, ListOfbool(), MapOfint$ListOfbool())))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  mixin_mixin_bound_test.I$ = dart.generic(T => {
    class I extends core.Object {}
    dart.addTypeTests(I);
    return I;
  });
  mixin_mixin_bound_test.I = I();
  mixin_mixin_bound_test.J$ = dart.generic(T => {
    class J extends core.Object {}
    dart.addTypeTests(J);
    return J;
  });
  mixin_mixin_bound_test.J = J();
  mixin_mixin_bound_test.S$ = dart.generic((U, V) => {
    class S extends core.Object {}
    dart.addTypeTests(S);
    return S;
  });
  mixin_mixin_bound_test.S = S();
  mixin_mixin_bound_test.M$ = dart.generic((U, V, T) => {
    class M extends core.Object {
      t() {
        return dart.wrapType(T);
      }
    }
    dart.addTypeTests(M);
    dart.setSignature(M, {
      methods: () => ({t: dart.definiteFunctionType(dart.dynamic, [])})
    });
    return M;
  });
  mixin_mixin_bound_test.M = M();
  mixin_mixin_bound_test.A$ = dart.generic((U, V) => {
    class A extends dart.mixin(core.Object, mixin_mixin_bound_test.M$(U, V, core.Map$(U, V))) {}
    return A;
  });
  mixin_mixin_bound_test.A = A();
  mixin_mixin_bound_test.C$ = dart.generic((T, K) => {
    class C extends dart.mixin(mixin_mixin_bound_test.S$(core.Set$(T), T), mixin_mixin_bound_test.A$(T, core.List$(K))) {
      new() {
        super.new();
      }
    }
    return C;
  });
  mixin_mixin_bound_test.C = C();
  mixin_mixin_bound_test.main = function() {
    let c = new (COfint$bool())();
    expect$.Expect.equals("Map<int, List<bool>>", dart.toString(c.t()));
    expect$.Expect.isTrue(IOfListOfbool().is(c));
    expect$.Expect.isTrue(JOfbool().is(c));
    expect$.Expect.isTrue(SOfSetOfint$int().is(c));
    expect$.Expect.isTrue(AOfint$ListOfbool().is(c));
    expect$.Expect.isTrue(MOfint$ListOfbool$MapOfint$ListOfbool().is(c));
  };
  dart.fn(mixin_mixin_bound_test.main, VoidTodynamic());
  // Exports:
  exports.mixin_mixin_bound_test = mixin_mixin_bound_test;
});
