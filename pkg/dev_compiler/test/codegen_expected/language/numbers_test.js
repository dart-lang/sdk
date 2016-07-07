dart_library.library('language/numbers_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__numbers_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const numbers_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  numbers_test.NumbersTest = class NumbersTest extends core.Object {
    static testMain() {
      let one = 1;
      expect$.Expect.equals(true, core.Object.is(one));
      expect$.Expect.equals(true, typeof one == 'number');
      expect$.Expect.equals(true, typeof one == 'number');
      expect$.Expect.equals(false, typeof one == 'number');
      let two = 2.0;
      expect$.Expect.equals(true, core.Object.is(two));
      expect$.Expect.equals(true, typeof two == 'number');
      expect$.Expect.equals(false, typeof two == 'number');
      expect$.Expect.equals(true, typeof two == 'number');
      let result = one + two;
      expect$.Expect.equals(true, core.Object.is(result));
      expect$.Expect.equals(true, typeof result == 'number');
      expect$.Expect.equals(false, typeof result == 'number');
      expect$.Expect.equals(true, typeof result == 'number');
      expect$.Expect.equals(3.0, result);
      return result;
    }
  };
  dart.setSignature(numbers_test.NumbersTest, {
    statics: () => ({testMain: dart.definiteFunctionType(core.double, [])}),
    names: ['testMain']
  });
  numbers_test.main = function() {
    numbers_test.NumbersTest.testMain();
  };
  dart.fn(numbers_test.main, VoidTodynamic());
  // Exports:
  exports.numbers_test = numbers_test;
});
