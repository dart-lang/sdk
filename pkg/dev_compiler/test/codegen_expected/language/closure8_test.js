dart_library.library('language/closure8_test', null, /* Imports */[
  'dart_sdk'
], function load__closure8_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const closure8_test = Object.create(null);
  let A = () => (A = dart.constFn(closure8_test.A$()))();
  let C = () => (C = dart.constFn(closure8_test.C$()))();
  let D = () => (D = dart.constFn(closure8_test.D$()))();
  let COfint = () => (COfint = dart.constFn(closure8_test.C$(core.int)))();
  let DOfint = () => (DOfint = dart.constFn(closure8_test.D$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  closure8_test.A$ = dart.generic(E => {
    class A extends core.Object {}
    dart.addTypeTests(A);
    return A;
  });
  closure8_test.A = A();
  closure8_test.C$ = dart.generic(E => {
    class C extends closure8_test.A$(E) {
      forEach(callback) {}
    }
    dart.setSignature(C, {
      methods: () => ({forEach: dart.definiteFunctionType(dart.dynamic, [dart.functionType(dart.dynamic, [E])])})
    });
    return C;
  });
  closure8_test.C = C();
  closure8_test.D$ = dart.generic(E => {
    class D extends core.Object {
      lala(element) {
        E._check(element);
      }
    }
    dart.addTypeTests(D);
    dart.setSignature(D, {
      methods: () => ({lala: dart.definiteFunctionType(dart.dynamic, [E])})
    });
    return D;
  });
  closure8_test.D = D();
  closure8_test.main = function() {
    let c = new (COfint())();
    c.forEach(dart.bind(new (DOfint())(), 'lala'));
  };
  dart.fn(closure8_test.main, VoidTodynamic());
  // Exports:
  exports.closure8_test = closure8_test;
});
