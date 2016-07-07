dart_library.library('language/generics3_test', null, /* Imports */[
  'dart_sdk'
], function load__generics3_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const generics3_test = Object.create(null);
  let C1 = () => (C1 = dart.constFn(generics3_test.C1$()))();
  let C2 = () => (C2 = dart.constFn(generics3_test.C2$()))();
  let C3 = () => (C3 = dart.constFn(generics3_test.C3$()))();
  let C4 = () => (C4 = dart.constFn(generics3_test.C4$()))();
  let C5 = () => (C5 = dart.constFn(generics3_test.C5$()))();
  let C4OfString = () => (C4OfString = dart.constFn(generics3_test.C4$(core.String)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  generics3_test.C1$ = dart.generic(T => {
    class C1 extends core.Object {}
    dart.addTypeTests(C1);
    return C1;
  });
  generics3_test.C1 = C1();
  generics3_test.C2$ = dart.generic(T => {
    class C2 extends core.Object {}
    dart.addTypeTests(C2);
    return C2;
  });
  generics3_test.C2 = C2();
  generics3_test.C3$ = dart.generic(T => {
    class C3 extends generics3_test.C2$(generics3_test.C1$(T)) {}
    return C3;
  });
  generics3_test.C3 = C3();
  generics3_test.C4$ = dart.generic(T => {
    let C1OfT = () => (C1OfT = dart.constFn(generics3_test.C1$(T)))();
    let C5OfC1OfT = () => (C5OfC1OfT = dart.constFn(generics3_test.C5$(C1OfT())))();
    class C4 extends generics3_test.C3$(T) {
      f() {
        return new (C5OfC1OfT())(new (C1OfT())());
      }
    }
    dart.setSignature(C4, {
      methods: () => ({f: dart.definiteFunctionType(dart.dynamic, [])})
    });
    return C4;
  });
  generics3_test.C4 = C4();
  generics3_test.C5$ = dart.generic(T => {
    class C5 extends core.Object {
      new(x) {
      }
    }
    dart.addTypeTests(C5);
    dart.setSignature(C5, {
      constructors: () => ({new: dart.definiteFunctionType(generics3_test.C5$(T), [T])})
    });
    return C5;
  });
  generics3_test.C5 = C5();
  generics3_test.main = function() {
    new (C4OfString())().f();
  };
  dart.fn(generics3_test.main, VoidTodynamic());
  // Exports:
  exports.generics3_test = generics3_test;
});
