dart_library.library('language/generics2_test', null, /* Imports */[
  'dart_sdk'
], function load__generics2_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const generics2_test = Object.create(null);
  let A = () => (A = dart.constFn(generics2_test.A$()))();
  let Pair = () => (Pair = dart.constFn(generics2_test.Pair$()))();
  let PairOfint$int = () => (PairOfint$int = dart.constFn(generics2_test.Pair$(core.int, core.int)))();
  let PairOfString$int = () => (PairOfString$int = dart.constFn(generics2_test.Pair$(core.String, core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  generics2_test.A$ = dart.generic(E => {
    class A extends core.Object {}
    dart.addTypeTests(A);
    return A;
  });
  generics2_test.A = A();
  generics2_test.Pair$ = dart.generic((P, Q) => {
    class Pair extends generics2_test.A {
      new(fst, snd) {
        this.fst = fst;
        this.snd = snd;
      }
    }
    dart.setSignature(Pair, {
      constructors: () => ({new: dart.definiteFunctionType(generics2_test.Pair$(P, Q), [P, Q])})
    });
    return Pair;
  });
  generics2_test.Pair = Pair();
  generics2_test.main = function() {
    core.print(new (PairOfint$int())(1, 2));
    core.print(new (PairOfString$int())("1", 2));
  };
  dart.fn(generics2_test.main, VoidTodynamic());
  // Exports:
  exports.generics2_test = generics2_test;
});
