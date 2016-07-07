dart_library.library('language/regress_22976_test_01_multi', null, /* Imports */[
  'dart_sdk'
], function load__regress_22976_test_01_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const regress_22976_test_01_multi = Object.create(null);
  let A = () => (A = dart.constFn(regress_22976_test_01_multi.A$()))();
  let B = () => (B = dart.constFn(regress_22976_test_01_multi.B$()))();
  let C = () => (C = dart.constFn(regress_22976_test_01_multi.C$()))();
  let COfint$String = () => (COfint$String = dart.constFn(regress_22976_test_01_multi.C$(core.int, core.String)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  regress_22976_test_01_multi.A$ = dart.generic(T => {
    class A extends core.Object {}
    dart.addTypeTests(A);
    return A;
  });
  regress_22976_test_01_multi.A = A();
  regress_22976_test_01_multi.B$ = dart.generic(T => {
    let AOfT = () => (AOfT = dart.constFn(regress_22976_test_01_multi.A$(T)))();
    class B extends core.Object {}
    dart.addTypeTests(B);
    B[dart.implements] = () => [AOfT()];
    return B;
  });
  regress_22976_test_01_multi.B = B();
  regress_22976_test_01_multi.C$ = dart.generic((S, T) => {
    let BOfS = () => (BOfS = dart.constFn(regress_22976_test_01_multi.B$(S)))();
    let AOfT = () => (AOfT = dart.constFn(regress_22976_test_01_multi.A$(T)))();
    class C extends core.Object {}
    dart.addTypeTests(C);
    C[dart.implements] = () => [BOfS(), AOfT()];
    return C;
  });
  regress_22976_test_01_multi.C = C();
  regress_22976_test_01_multi.main = function() {
    let a0 = new (COfint$String())();
  };
  dart.fn(regress_22976_test_01_multi.main, VoidTodynamic());
  // Exports:
  exports.regress_22976_test_01_multi = regress_22976_test_01_multi;
});
