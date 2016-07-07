dart_library.library('language/type_variable_conflict_test_none_multi', null, /* Imports */[
  'dart_sdk'
], function load__type_variable_conflict_test_none_multi(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const type_variable_conflict_test_none_multi = Object.create(null);
  let G1 = () => (G1 = dart.constFn(type_variable_conflict_test_none_multi.G1$()))();
  let G2 = () => (G2 = dart.constFn(type_variable_conflict_test_none_multi.G2$()))();
  let G3 = () => (G3 = dart.constFn(type_variable_conflict_test_none_multi.G3$()))();
  let G4 = () => (G4 = dart.constFn(type_variable_conflict_test_none_multi.G4$()))();
  let G5 = () => (G5 = dart.constFn(type_variable_conflict_test_none_multi.G5$()))();
  let G6 = () => (G6 = dart.constFn(type_variable_conflict_test_none_multi.G6$()))();
  let G1Ofint = () => (G1Ofint = dart.constFn(type_variable_conflict_test_none_multi.G1$(core.int)))();
  let G2Ofint = () => (G2Ofint = dart.constFn(type_variable_conflict_test_none_multi.G2$(core.int)))();
  let G3Ofint = () => (G3Ofint = dart.constFn(type_variable_conflict_test_none_multi.G3$(core.int)))();
  let G4Ofint = () => (G4Ofint = dart.constFn(type_variable_conflict_test_none_multi.G4$(core.int)))();
  let G5Ofint = () => (G5Ofint = dart.constFn(type_variable_conflict_test_none_multi.G5$(core.int)))();
  let G6Ofint = () => (G6Ofint = dart.constFn(type_variable_conflict_test_none_multi.G6$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  type_variable_conflict_test_none_multi.G1$ = dart.generic(T => {
    class G1 extends core.Object {}
    dart.addTypeTests(G1);
    return G1;
  });
  type_variable_conflict_test_none_multi.G1 = G1();
  type_variable_conflict_test_none_multi.G2$ = dart.generic(T => {
    class G2 extends core.Object {}
    dart.addTypeTests(G2);
    return G2;
  });
  type_variable_conflict_test_none_multi.G2 = G2();
  type_variable_conflict_test_none_multi.G3$ = dart.generic(T => {
    class G3 extends core.Object {}
    dart.addTypeTests(G3);
    return G3;
  });
  type_variable_conflict_test_none_multi.G3 = G3();
  type_variable_conflict_test_none_multi.G4$ = dart.generic(T => {
    class G4 extends core.Object {}
    dart.addTypeTests(G4);
    return G4;
  });
  type_variable_conflict_test_none_multi.G4 = G4();
  type_variable_conflict_test_none_multi.G5$ = dart.generic(T => {
    class G5 extends core.Object {}
    dart.addTypeTests(G5);
    return G5;
  });
  type_variable_conflict_test_none_multi.G5 = G5();
  type_variable_conflict_test_none_multi.G6$ = dart.generic(T => {
    class G6 extends core.Object {}
    dart.addTypeTests(G6);
    return G6;
  });
  type_variable_conflict_test_none_multi.G6 = G6();
  type_variable_conflict_test_none_multi.main = function() {
    new (G1Ofint())();
    new (G2Ofint())();
    new (G3Ofint())();
    new (G4Ofint())();
    new (G5Ofint())();
    new (G6Ofint())();
  };
  dart.fn(type_variable_conflict_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.type_variable_conflict_test_none_multi = type_variable_conflict_test_none_multi;
});
