dart_library.library('language/generic_creation_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__generic_creation_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const generic_creation_test = Object.create(null);
  let A = () => (A = dart.constFn(generic_creation_test.A$()))();
  let C = () => (C = dart.constFn(generic_creation_test.C$()))();
  let D = () => (D = dart.constFn(generic_creation_test.D$()))();
  let AOfU$V$W = () => (AOfU$V$W = dart.constFn(generic_creation_test.A$(generic_creation_test.U, generic_creation_test.V, generic_creation_test.W)))();
  let AOfW$U$V = () => (AOfW$U$V = dart.constFn(generic_creation_test.A$(generic_creation_test.W, generic_creation_test.U, generic_creation_test.V)))();
  let AOfW$V$U = () => (AOfW$V$U = dart.constFn(generic_creation_test.A$(generic_creation_test.W, generic_creation_test.V, generic_creation_test.U)))();
  let AOfU$U$U = () => (AOfU$U$U = dart.constFn(generic_creation_test.A$(generic_creation_test.U, generic_creation_test.U, generic_creation_test.U)))();
  let AOfW$W$W = () => (AOfW$W$W = dart.constFn(generic_creation_test.A$(generic_creation_test.W, generic_creation_test.W, generic_creation_test.W)))();
  let AOfV$V$V = () => (AOfV$V$V = dart.constFn(generic_creation_test.A$(generic_creation_test.V, generic_creation_test.V, generic_creation_test.V)))();
  let AOfAOfU$U$U$AOfV$V$V$AOfW$W$W = () => (AOfAOfU$U$U$AOfV$V$V$AOfW$W$W = dart.constFn(generic_creation_test.A$(AOfU$U$U(), AOfV$V$V(), AOfW$W$W())))();
  let COfV = () => (COfV = dart.constFn(generic_creation_test.C$(generic_creation_test.V)))();
  let DOfU$V$W = () => (DOfU$V$W = dart.constFn(generic_creation_test.D$(generic_creation_test.U, generic_creation_test.V, generic_creation_test.W)))();
  let AOfAOfV$V$V$AOfW$W$W$AOfU$U$U = () => (AOfAOfV$V$V$AOfW$W$W$AOfU$U$U = dart.constFn(generic_creation_test.A$(AOfV$V$V(), AOfW$W$W(), AOfU$U$U())))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  generic_creation_test.A$ = dart.generic((X, Y, Z) => {
    let AOfZ$X$Y = () => (AOfZ$X$Y = dart.constFn(generic_creation_test.A$(Z, X, Y)))();
    let AOfZ$Y$X = () => (AOfZ$Y$X = dart.constFn(generic_creation_test.A$(Z, Y, X)))();
    let AOfX$X$X = () => (AOfX$X$X = dart.constFn(generic_creation_test.A$(X, X, X)))();
    let AOfAOfX$X$X$AOfY$Y$Y$AOfZ$Z$Z = () => (AOfAOfX$X$X$AOfY$Y$Y$AOfZ$Z$Z = dart.constFn(generic_creation_test.A$(AOfX$X$X(), AOfY$Y$Y(), AOfZ$Z$Z())))();
    let AOfY$Y$Y = () => (AOfY$Y$Y = dart.constFn(generic_creation_test.A$(Y, Y, Y)))();
    let AOfZ$Z$Z = () => (AOfZ$Z$Z = dart.constFn(generic_creation_test.A$(Z, Z, Z)))();
    class A extends core.Object {
      shift() {
        return new (AOfZ$X$Y())();
      }
      swap() {
        return new (AOfZ$Y$X())();
      }
      first() {
        return new (AOfX$X$X())();
      }
      last() {
        return new (AOfZ$Z$Z())();
      }
      wrap() {
        return new (AOfAOfX$X$X$AOfY$Y$Y$AOfZ$Z$Z())();
      }
    }
    dart.addTypeTests(A);
    dart.setSignature(A, {
      methods: () => ({
        shift: dart.definiteFunctionType(dart.dynamic, []),
        swap: dart.definiteFunctionType(dart.dynamic, []),
        first: dart.definiteFunctionType(dart.dynamic, []),
        last: dart.definiteFunctionType(dart.dynamic, []),
        wrap: dart.definiteFunctionType(dart.dynamic, [])
      })
    });
    return A;
  });
  generic_creation_test.A = A();
  generic_creation_test.U = class U extends core.Object {};
  generic_creation_test.V = class V extends core.Object {};
  generic_creation_test.W = class W extends core.Object {};
  generic_creation_test.B = class B extends generic_creation_test.A$(generic_creation_test.U, generic_creation_test.V, generic_creation_test.W) {};
  dart.addSimpleTypeTests(generic_creation_test.B);
  generic_creation_test.C$ = dart.generic(T => {
    class C extends generic_creation_test.A$(generic_creation_test.U, T, generic_creation_test.W) {}
    return C;
  });
  generic_creation_test.C = C();
  generic_creation_test.D$ = dart.generic((X, Y, Z) => {
    class D extends generic_creation_test.A$(Y, Z, X) {}
    return D;
  });
  generic_creation_test.D = D();
  generic_creation_test.sameType = function(a, b) {
    return expect$.Expect.equals(dart.runtimeType(a), dart.runtimeType(b));
  };
  dart.fn(generic_creation_test.sameType, dynamicAnddynamicTodynamic());
  generic_creation_test.main = function() {
    let a = new (AOfU$V$W())();
    generic_creation_test.sameType(new (AOfW$U$V())(), a.shift());
    generic_creation_test.sameType(new (AOfW$V$U())(), a.swap());
    generic_creation_test.sameType(new (AOfU$U$U())(), a.first());
    generic_creation_test.sameType(new (AOfW$W$W())(), a.last());
    generic_creation_test.sameType(new (AOfAOfU$U$U$AOfV$V$V$AOfW$W$W())(), a.wrap());
    let b = new generic_creation_test.B();
    generic_creation_test.sameType(new (AOfAOfU$U$U$AOfV$V$V$AOfW$W$W())(), b.wrap());
    let c = new (COfV())();
    generic_creation_test.sameType(new (AOfAOfU$U$U$AOfV$V$V$AOfW$W$W())(), c.wrap());
    let d = new (DOfU$V$W())();
    generic_creation_test.sameType(new (AOfAOfV$V$V$AOfW$W$W$AOfU$U$U())(), d.wrap());
  };
  dart.fn(generic_creation_test.main, VoidTodynamic());
  // Exports:
  exports.generic_creation_test = generic_creation_test;
});
