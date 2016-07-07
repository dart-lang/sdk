dart_library.library('language/closures_with_complex_params_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__closures_with_complex_params_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const closures_with_complex_params_test = Object.create(null);
  let Pair = () => (Pair = dart.constFn(closures_with_complex_params_test.Pair$()))();
  let PairOfint$int = () => (PairOfint$int = dart.constFn(closures_with_complex_params_test.Pair$(core.int, core.int)))();
  let PairOfint$PairOfint$int = () => (PairOfint$PairOfint$int = dart.constFn(closures_with_complex_params_test.Pair$(core.int, PairOfint$int())))();
  let PairOfint$PairOfint$intTodynamic = () => (PairOfint$PairOfint$intTodynamic = dart.constFn(dart.functionType(dart.dynamic, [PairOfint$PairOfint$int()])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let PairOfint$PairOfint$intToint = () => (PairOfint$PairOfint$intToint = dart.constFn(dart.definiteFunctionType(core.int, [PairOfint$PairOfint$int()])))();
  let __Toint = () => (__Toint = dart.constFn(dart.definiteFunctionType(core.int, [], [PairOfint$PairOfint$int()])))();
  let FnAndPairOfint$PairOfint$intTodynamic = () => (FnAndPairOfint$PairOfint$intTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [PairOfint$PairOfint$intTodynamic(), PairOfint$PairOfint$int()])))();
  closures_with_complex_params_test.main = function() {
    closures_with_complex_params_test.test1();
    closures_with_complex_params_test.test2();
    closures_with_complex_params_test.test3();
  };
  dart.fn(closures_with_complex_params_test.main, VoidTodynamic());
  closures_with_complex_params_test.Pair$ = dart.generic((A, B) => {
    class Pair extends core.Object {
      new(fst, snd) {
        this.fst = fst;
        this.snd = snd;
      }
    }
    dart.addTypeTests(Pair);
    dart.setSignature(Pair, {
      constructors: () => ({new: dart.definiteFunctionType(closures_with_complex_params_test.Pair$(A, B), [A, B])})
    });
    return Pair;
  });
  closures_with_complex_params_test.Pair = Pair();
  closures_with_complex_params_test.test1 = function() {
    let cdar1 = dart.fn(pr => pr.snd.fst, PairOfint$PairOfint$intToint());
    let cdar2 = dart.fn(pr => pr.snd.fst, PairOfint$PairOfint$intToint());
    let e = new (PairOfint$PairOfint$int())(100, new (PairOfint$int())(200, 300));
    expect$.Expect.equals(200, cdar1(e));
    expect$.Expect.equals(200, cdar2(e));
  };
  dart.fn(closures_with_complex_params_test.test1, VoidTodynamic());
  closures_with_complex_params_test.test2 = function() {
    let cdar1 = dart.fn(pr => {
      if (pr === void 0) pr = null;
      return pr.snd.fst;
    }, __Toint());
    let cdar2 = dart.fn(pr => {
      if (pr === void 0) pr = null;
      return pr.snd.fst;
    }, __Toint());
    let e = new (PairOfint$PairOfint$int())(100, new (PairOfint$int())(200, 300));
    expect$.Expect.equals(200, cdar1(e));
    expect$.Expect.equals(200, cdar2(e));
  };
  dart.fn(closures_with_complex_params_test.test2, VoidTodynamic());
  closures_with_complex_params_test.test3 = function() {
    let f1 = dart.fn(pr => dart.notNull(pr.snd.fst) + 1, PairOfint$PairOfint$intToint());
    let f2 = dart.fn(pr => dart.notNull(pr.snd.fst) + 2, PairOfint$PairOfint$intToint());
    let ap1 = dart.fn((f, pr) => dart.dsend(f(pr), '*', 10), FnAndPairOfint$PairOfint$intTodynamic());
    let ap2 = dart.fn((f, pr) => dart.dsend(f(pr), '*', 100), FnAndPairOfint$PairOfint$intTodynamic());
    let e = new (PairOfint$PairOfint$int())(100, new (PairOfint$int())(200, 300));
    expect$.Expect.equals(2010, ap1(f1, e));
    expect$.Expect.equals(2020, ap1(f2, e));
    expect$.Expect.equals(20100, ap2(f1, e));
    expect$.Expect.equals(20200, ap2(f2, e));
  };
  dart.fn(closures_with_complex_params_test.test3, VoidTodynamic());
  // Exports:
  exports.closures_with_complex_params_test = closures_with_complex_params_test;
});
