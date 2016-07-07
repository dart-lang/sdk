dart_library.library('language/guess_cid_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__guess_cid_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const guess_cid_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let intToint = () => (intToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int])))();
  let doubleTodouble = () => (doubleTodouble = dart.constFn(dart.definiteFunctionType(core.double, [core.double])))();
  let intAndintToint = () => (intAndintToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int, core.int])))();
  let doubleAnddoubleTodouble = () => (doubleAnddoubleTodouble = dart.constFn(dart.definiteFunctionType(core.double, [core.double, core.double])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  guess_cid_test.main = function() {
    for (let i = 0; i < 100; i++) {
      expect$.Expect.equals(i, guess_cid_test.compareInt(i));
      expect$.Expect.equals(i[dartx.toDouble](), guess_cid_test.compareDouble(i[dartx.toDouble]()));
      expect$.Expect.equals(i, guess_cid_test.binOpInt(i, i));
      expect$.Expect.equals(i[dartx.toDouble](), guess_cid_test.binOpDouble(i[dartx.toDouble](), i[dartx.toDouble]()));
    }
    expect$.Expect.equals(3, guess_cid_test.compareInt(3));
    expect$.Expect.equals(-2, guess_cid_test.compareInt(-2));
    expect$.Expect.equals(0, guess_cid_test.compareInt(-1));
    expect$.Expect.equals(3, guess_cid_test.binOpInt(3, 3));
    expect$.Expect.equals(0, guess_cid_test.binOpInt(-2, -2));
    expect$.Expect.equals(3.0, guess_cid_test.binOpDouble(3.0, 3.0));
    expect$.Expect.equals(0.0, guess_cid_test.binOpDouble(-2.0, -2.0));
    expect$.Expect.equals(3.0, guess_cid_test.compareDouble(3.0));
    expect$.Expect.equals(-2.0, guess_cid_test.compareDouble(-2.0));
    expect$.Expect.equals(0.0, guess_cid_test.compareDouble(-1.0));
    guess_cid_test.testOSR();
  };
  dart.fn(guess_cid_test.main, VoidTodynamic());
  guess_cid_test.compareInt = function(i) {
    if (dart.notNull(i) < 0) {
      if (i == -1) return 0;
    }
    return i;
  };
  dart.fn(guess_cid_test.compareInt, intToint());
  guess_cid_test.compareDouble = function(i) {
    if (dart.notNull(i) < 0.0) {
      if (i == -1.0) return 0.0;
    }
    return i;
  };
  dart.fn(guess_cid_test.compareDouble, doubleTodouble());
  guess_cid_test.binOpInt = function(i, x) {
    if (dart.notNull(i) < 0) {
      return dart.notNull(x) + 2;
    }
    return i;
  };
  dart.fn(guess_cid_test.binOpInt, intAndintToint());
  guess_cid_test.binOpDouble = function(i, x) {
    if (dart.notNull(i) < 0.0) {
      return dart.notNull(x) + 2.0;
    }
    return i;
  };
  dart.fn(guess_cid_test.binOpDouble, doubleAnddoubleTodouble());
  guess_cid_test.testOSR = function() {
    let y = -2147483648;
    expect$.Expect.equals(1475739525896764129300, guess_cid_test.testLoop(10, 147573952589676412928));
    expect$.Expect.equals(1475739525896764129300, guess_cid_test.testLoop(10, 147573952589676412928));
  };
  dart.fn(guess_cid_test.testOSR, VoidTodynamic());
  guess_cid_test.testLoop = function(N, x) {
    for (let i = 0; i < dart.notNull(core.num._check(N)); ++i) {
    }
    let sum = 0;
    for (let i = 0; i < dart.notNull(core.num._check(N)); ++i) {
      sum = dart.notNull(sum) + dart.notNull(core.int._check(dart.dsend(x, '+', 2)));
    }
    return sum;
  };
  dart.fn(guess_cid_test.testLoop, dynamicAnddynamicTodynamic());
  // Exports:
  exports.guess_cid_test = guess_cid_test;
});
