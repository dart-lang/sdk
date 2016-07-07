dart_library.library('language/mixin_generic_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__mixin_generic_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const mixin_generic_test = Object.create(null);
  let S = () => (S = dart.constFn(mixin_generic_test.S$()))();
  let M = () => (M = dart.constFn(mixin_generic_test.M$()))();
  let N = () => (N = dart.constFn(mixin_generic_test.N$()))();
  let C = () => (C = dart.constFn(mixin_generic_test.C$()))();
  let COfint$bool = () => (COfint$bool = dart.constFn(mixin_generic_test.C$(core.int, core.bool)))();
  let MapOfint$bool = () => (MapOfint$bool = dart.constFn(core.Map$(core.int, core.bool)))();
  let SOfMapOfint$bool = () => (SOfMapOfint$bool = dart.constFn(mixin_generic_test.S$(MapOfint$bool())))();
  let ListOfint = () => (ListOfint = dart.constFn(core.List$(core.int)))();
  let MOfListOfint = () => (MOfListOfint = dart.constFn(mixin_generic_test.M$(ListOfint())))();
  let SetOfbool = () => (SetOfbool = dart.constFn(core.Set$(core.bool)))();
  let NOfSetOfbool = () => (NOfSetOfbool = dart.constFn(mixin_generic_test.N$(SetOfbool())))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  mixin_generic_test.S$ = dart.generic(T => {
    class S extends core.Object {
      s() {
        return dart.wrapType(T);
      }
    }
    dart.addTypeTests(S);
    dart.setSignature(S, {
      methods: () => ({s: dart.definiteFunctionType(dart.dynamic, [])})
    });
    return S;
  });
  mixin_generic_test.S = S();
  mixin_generic_test.M$ = dart.generic(T => {
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
  mixin_generic_test.M = M();
  mixin_generic_test.N$ = dart.generic(T => {
    class N extends core.Object {
      n() {
        return dart.wrapType(T);
      }
    }
    dart.addTypeTests(N);
    dart.setSignature(N, {
      methods: () => ({n: dart.definiteFunctionType(dart.dynamic, [])})
    });
    return N;
  });
  mixin_generic_test.N = N();
  mixin_generic_test.C$ = dart.generic((U, V) => {
    class C extends dart.mixin(mixin_generic_test.S$(core.Map$(U, V)), mixin_generic_test.M$(core.List$(U)), mixin_generic_test.N$(core.Set$(V))) {}
    return C;
  });
  mixin_generic_test.C = C();
  mixin_generic_test.main = function() {
    let c = new (COfint$bool())();
    expect$.Expect.isTrue(SOfMapOfint$bool().is(c));
    expect$.Expect.equals("Map<int, bool>", dart.toString(c.s()));
    expect$.Expect.isTrue(MOfListOfint().is(c));
    expect$.Expect.equals("List<int>", dart.toString(c.m()));
    expect$.Expect.isTrue(NOfSetOfbool().is(c));
    expect$.Expect.equals("Set<bool>", dart.toString(c.n()));
  };
  dart.fn(mixin_generic_test.main, VoidTodynamic());
  // Exports:
  exports.mixin_generic_test = mixin_generic_test;
});
