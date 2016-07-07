dart_library.library('language/mixin_mixin2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__mixin_mixin2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const mixin_mixin2_test = Object.create(null);
  let M = () => (M = dart.constFn(mixin_mixin2_test.M$()))();
  let A = () => (A = dart.constFn(mixin_mixin2_test.A$()))();
  let B = () => (B = dart.constFn(mixin_mixin2_test.B$()))();
  let C = () => (C = dart.constFn(mixin_mixin2_test.C$()))();
  let D = () => (D = dart.constFn(mixin_mixin2_test.D$()))();
  let G = () => (G = dart.constFn(mixin_mixin2_test.G$()))();
  let H = () => (H = dart.constFn(mixin_mixin2_test.H$()))();
  let GOfbool = () => (GOfbool = dart.constFn(mixin_mixin2_test.G$(core.bool)))();
  let HOfint = () => (HOfint = dart.constFn(mixin_mixin2_test.H$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  mixin_mixin2_test.M$ = dart.generic(T => {
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
  mixin_mixin2_test.M = M();
  mixin_mixin2_test.A$ = dart.generic(U => {
    class A extends dart.mixin(core.Object, mixin_mixin2_test.M$(U)) {}
    return A;
  });
  mixin_mixin2_test.A = A();
  mixin_mixin2_test.B$ = dart.generic(V => {
    class B extends dart.mixin(core.Object, mixin_mixin2_test.A$(V)) {}
    return B;
  });
  mixin_mixin2_test.B = B();
  mixin_mixin2_test.C$ = dart.generic(U => {
    class C extends dart.mixin(core.Object, mixin_mixin2_test.M$(core.List$(U))) {}
    return C;
  });
  mixin_mixin2_test.C = C();
  mixin_mixin2_test.D$ = dart.generic(V => {
    class D extends dart.mixin(core.Object, mixin_mixin2_test.C$(core.Set$(V))) {}
    return D;
  });
  mixin_mixin2_test.D = D();
  mixin_mixin2_test.E = class E extends mixin_mixin2_test.A$(core.num) {};
  dart.addSimpleTypeTests(mixin_mixin2_test.E);
  mixin_mixin2_test.F = class F extends mixin_mixin2_test.B$(core.String) {};
  dart.addSimpleTypeTests(mixin_mixin2_test.F);
  mixin_mixin2_test.G$ = dart.generic(T => {
    class G extends mixin_mixin2_test.C$(T) {}
    return G;
  });
  mixin_mixin2_test.G = G();
  mixin_mixin2_test.H$ = dart.generic(T => {
    class H extends mixin_mixin2_test.D$(core.Map$(core.String, T)) {}
    return H;
  });
  mixin_mixin2_test.H = H();
  mixin_mixin2_test.main = function() {
    expect$.Expect.equals("num", dart.toString(new mixin_mixin2_test.E().t()));
    expect$.Expect.equals("String", dart.toString(new mixin_mixin2_test.F().t()));
    expect$.Expect.equals("List<bool>", dart.toString(new (GOfbool())().t()));
    expect$.Expect.equals("List<Set<Map<String, int>>>", dart.toString(new (HOfint())().t()));
  };
  dart.fn(mixin_mixin2_test.main, VoidTodynamic());
  // Exports:
  exports.mixin_mixin2_test = mixin_mixin2_test;
});
