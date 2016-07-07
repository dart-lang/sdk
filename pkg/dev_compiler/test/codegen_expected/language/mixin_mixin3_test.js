dart_library.library('language/mixin_mixin3_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__mixin_mixin3_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const mixin_mixin3_test = Object.create(null);
  let M = () => (M = dart.constFn(mixin_mixin3_test.M$()))();
  let A = () => (A = dart.constFn(mixin_mixin3_test.A$()))();
  let A2 = () => (A2 = dart.constFn(mixin_mixin3_test.A2$()))();
  let B2 = () => (B2 = dart.constFn(mixin_mixin3_test.B2$()))();
  let B3 = () => (B3 = dart.constFn(mixin_mixin3_test.B3$()))();
  let C2 = () => (C2 = dart.constFn(mixin_mixin3_test.C2$()))();
  let C3 = () => (C3 = dart.constFn(mixin_mixin3_test.C3$()))();
  let O = () => (O = dart.constFn(mixin_mixin3_test.O$()))();
  let P = () => (P = dart.constFn(mixin_mixin3_test.P$()))();
  let Q = () => (Q = dart.constFn(mixin_mixin3_test.Q$()))();
  let C2Ofbool = () => (C2Ofbool = dart.constFn(mixin_mixin3_test.C2$(core.bool)))();
  let C3Ofbool = () => (C3Ofbool = dart.constFn(mixin_mixin3_test.C3$(core.bool)))();
  let QOfbool$int = () => (QOfbool$int = dart.constFn(mixin_mixin3_test.Q$(core.bool, core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  mixin_mixin3_test.M$ = dart.generic(T => {
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
  mixin_mixin3_test.M = M();
  mixin_mixin3_test.A$ = dart.generic(U => {
    class A extends dart.mixin(core.Object, mixin_mixin3_test.M$(core.List$(U))) {}
    return A;
  });
  mixin_mixin3_test.A = A();
  mixin_mixin3_test.B0 = class B0 extends dart.mixin(core.Object, mixin_mixin3_test.A$(core.Set$(core.bool))) {};
  mixin_mixin3_test.B1 = class B1 extends dart.mixin(core.Object, mixin_mixin3_test.A$(core.Set$(core.int))) {};
  mixin_mixin3_test.C0 = class C0 extends mixin_mixin3_test.B0 {};
  mixin_mixin3_test.C1 = class C1 extends mixin_mixin3_test.B1 {};
  mixin_mixin3_test.A2$ = dart.generic((K, V) => {
    class A2 extends dart.mixin(core.Object, mixin_mixin3_test.M$(core.Map$(K, V))) {}
    return A2;
  });
  mixin_mixin3_test.A2 = A2();
  mixin_mixin3_test.B2$ = dart.generic(V => {
    class B2 extends dart.mixin(core.Object, mixin_mixin3_test.A2$(core.Set$(V), core.List$(V))) {}
    return B2;
  });
  mixin_mixin3_test.B2 = B2();
  mixin_mixin3_test.B3$ = dart.generic((K, V) => {
    class B3 extends dart.mixin(core.Object, mixin_mixin3_test.A2$(core.Set$(K), core.List$(V))) {}
    return B3;
  });
  mixin_mixin3_test.B3 = B3();
  mixin_mixin3_test.C2$ = dart.generic(T => {
    class C2 extends mixin_mixin3_test.B2$(T) {}
    return C2;
  });
  mixin_mixin3_test.C2 = C2();
  mixin_mixin3_test.C3$ = dart.generic(T => {
    class C3 extends mixin_mixin3_test.B3$(T, core.int) {}
    return C3;
  });
  mixin_mixin3_test.C3 = C3();
  mixin_mixin3_test.N = class N extends core.Object {
    q() {
      return 42;
    }
  };
  dart.setSignature(mixin_mixin3_test.N, {
    methods: () => ({q: dart.definiteFunctionType(dart.dynamic, [])})
  });
  mixin_mixin3_test.O$ = dart.generic(U => {
    class O extends dart.mixin(core.Object, mixin_mixin3_test.N) {}
    return O;
  });
  mixin_mixin3_test.O = O();
  mixin_mixin3_test.P$ = dart.generic((K, V) => {
    class P extends dart.mixin(core.Object, mixin_mixin3_test.O$(V)) {}
    return P;
  });
  mixin_mixin3_test.P = P();
  mixin_mixin3_test.Q$ = dart.generic((K, V) => {
    class Q extends mixin_mixin3_test.P$(K, V) {}
    return Q;
  });
  mixin_mixin3_test.Q = Q();
  mixin_mixin3_test.main = function() {
    expect$.Expect.equals("List<Set<bool>>", dart.toString(new mixin_mixin3_test.C0().t()));
    expect$.Expect.equals("List<Set<int>>", dart.toString(new mixin_mixin3_test.C1().t()));
    expect$.Expect.equals("Map<Set<bool>, List<bool>>", dart.toString(new (C2Ofbool())().t()));
    expect$.Expect.equals("Map<Set<bool>, List<int>>", dart.toString(new (C3Ofbool())().t()));
    expect$.Expect.equals(42, new (QOfbool$int())().q());
  };
  dart.fn(mixin_mixin3_test.main, VoidTodynamic());
  // Exports:
  exports.mixin_mixin3_test = mixin_mixin3_test;
});
