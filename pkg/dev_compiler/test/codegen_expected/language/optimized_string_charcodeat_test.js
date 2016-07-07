dart_library.library('language/optimized_string_charcodeat_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__optimized_string_charcodeat_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const optimized_string_charcodeat_test = Object.create(null);
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let StringAndintToint = () => (StringAndintToint = dart.constFn(dart.definiteFunctionType(core.int, [core.String, core.int])))();
  let intToint = () => (intToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int])))();
  let StringToint = () => (StringToint = dart.constFn(dart.definiteFunctionType(core.int, [core.String])))();
  let dynamicToint = () => (dynamicToint = dart.constFn(dart.definiteFunctionType(core.int, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  optimized_string_charcodeat_test.one_byte = "hest";
  optimized_string_charcodeat_test.two_byte = "h\u2029ns";
  optimized_string_charcodeat_test.testOneByteCodeUnitAt = function(x, j) {
    function test() {
      return x[dartx.codeUnitAt](j);
    }
    dart.fn(test, VoidToint());
    for (let i = 0; i < 20; i++)
      test();
    return test();
  };
  dart.fn(optimized_string_charcodeat_test.testOneByteCodeUnitAt, StringAndintToint());
  optimized_string_charcodeat_test.testTwoByteCodeUnitAt = function(x, j) {
    function test() {
      return x[dartx.codeUnitAt](j);
    }
    dart.fn(test, VoidToint());
    for (let i = 0; i < 20; i++)
      test();
    return test();
  };
  dart.fn(optimized_string_charcodeat_test.testTwoByteCodeUnitAt, StringAndintToint());
  optimized_string_charcodeat_test.testConstantStringCodeUnitAt = function(j) {
    function test() {
      return "høns"[dartx.codeUnitAt](j);
    }
    dart.fn(test, VoidToint());
    for (let i = 0; i < 20; i++)
      test();
    return test();
  };
  dart.fn(optimized_string_charcodeat_test.testConstantStringCodeUnitAt, intToint());
  optimized_string_charcodeat_test.testConstantIndexCodeUnitAt = function(x) {
    function test() {
      return x[dartx.codeUnitAt](1);
    }
    dart.fn(test, VoidToint());
    for (let i = 0; i < 20; i++)
      test();
    return test();
  };
  dart.fn(optimized_string_charcodeat_test.testConstantIndexCodeUnitAt, StringToint());
  optimized_string_charcodeat_test.testOneByteCodeUnitAtInLoop = function(x) {
    let result = 0;
    for (let i = 0; i < dart.notNull(core.num._check(dart.dload(x, 'length'))); i++) {
      result = dart.notNull(result) + dart.notNull(core.int._check(dart.dsend(x, 'codeUnitAt', i)));
    }
    return result;
  };
  dart.fn(optimized_string_charcodeat_test.testOneByteCodeUnitAtInLoop, dynamicToint());
  optimized_string_charcodeat_test.testTwoByteCodeUnitAtInLoop = function(x) {
    let result = 0;
    for (let i = 0; i < dart.notNull(core.num._check(dart.dload(x, 'length'))); i++) {
      result = dart.notNull(result) + dart.notNull(core.int._check(dart.dsend(x, 'codeUnitAt', i)));
    }
    return result;
  };
  dart.fn(optimized_string_charcodeat_test.testTwoByteCodeUnitAtInLoop, dynamicToint());
  optimized_string_charcodeat_test.main = function() {
    for (let j = 0; j < 10; j++) {
      expect$.Expect.equals(101, optimized_string_charcodeat_test.testOneByteCodeUnitAt(optimized_string_charcodeat_test.one_byte, 1));
      expect$.Expect.equals(8233, optimized_string_charcodeat_test.testTwoByteCodeUnitAt(optimized_string_charcodeat_test.two_byte, 1));
      expect$.Expect.equals(248, optimized_string_charcodeat_test.testConstantStringCodeUnitAt(1));
      expect$.Expect.equals(101, optimized_string_charcodeat_test.testConstantIndexCodeUnitAt(optimized_string_charcodeat_test.one_byte));
    }
    for (let j = 0; j < 20; j++) {
      expect$.Expect.equals(436, optimized_string_charcodeat_test.testOneByteCodeUnitAtInLoop(optimized_string_charcodeat_test.one_byte));
      expect$.Expect.equals(8562, optimized_string_charcodeat_test.testTwoByteCodeUnitAtInLoop(optimized_string_charcodeat_test.two_byte));
    }
    expect$.Expect.throws(dart.fn(() => optimized_string_charcodeat_test.testOneByteCodeUnitAtInLoop(123), VoidToint()));
    expect$.Expect.throws(dart.fn(() => optimized_string_charcodeat_test.testTwoByteCodeUnitAtInLoop(123), VoidToint()));
  };
  dart.fn(optimized_string_charcodeat_test.main, VoidTodynamic());
  // Exports:
  exports.optimized_string_charcodeat_test = optimized_string_charcodeat_test;
});
