dart_library.library('language/int_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__int_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const int_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  int_test.IntTest = class IntTest extends core.Object {
    static testMain() {
      expect$.Expect.equals(0, 0 + 0);
      expect$.Expect.equals(1, 1 + 0);
      expect$.Expect.equals(2, 1 + 1);
      expect$.Expect.equals(3, -1 + 4);
      expect$.Expect.equals(3, 4 + -1);
      expect$.Expect.equals(1, 1 - 0);
      expect$.Expect.equals(0, 1 - 1);
      expect$.Expect.equals(1, 2 - 1);
      expect$.Expect.equals(2, 4 - 2);
      expect$.Expect.equals(-2, 2 - 4);
      expect$.Expect.equals(0, 3 * 0);
      expect$.Expect.equals(0, 0 * 3);
      expect$.Expect.equals(1, 1 * 1);
      expect$.Expect.equals(5, 5 * 1);
      expect$.Expect.equals(15, 3 * 5);
      expect$.Expect.equals(-1, 1 * -1);
      expect$.Expect.equals(-15, -5 * 3);
      expect$.Expect.equals(15, -5 * -3);
      expect$.Expect.equals(1, (2 / 2)[dartx.truncate]());
      expect$.Expect.equals(2, (2 / 1)[dartx.truncate]());
      expect$.Expect.equals(2, (4 / 2)[dartx.truncate]());
      expect$.Expect.equals(2, (5 / 2)[dartx.truncate]());
      expect$.Expect.equals(-2, (-5 / 2)[dartx.truncate]());
      expect$.Expect.equals(-2, (-4 / 2)[dartx.truncate]());
      expect$.Expect.equals(-2, (5 / -2)[dartx.truncate]());
      expect$.Expect.equals(-2, (4 / -2)[dartx.truncate]());
      expect$.Expect.equals(3, (7)[dartx['%']](4));
      expect$.Expect.equals(2, (9)[dartx['%']](7));
      expect$.Expect.equals(2, (-7)[dartx['%']](9));
      expect$.Expect.equals(7, (7)[dartx['%']](-9));
      expect$.Expect.equals(7, (7)[dartx['%']](9));
      expect$.Expect.equals(2, (-7)[dartx['%']](-9));
      expect$.Expect.equals(3, (7)[dartx.remainder](4));
      expect$.Expect.equals(2, (9)[dartx.remainder](7));
      expect$.Expect.equals(-7, (-7)[dartx.remainder](9));
      expect$.Expect.equals(7, (7)[dartx.remainder](-9));
      expect$.Expect.equals(7, (7)[dartx.remainder](9));
      expect$.Expect.equals(-7, (-7)[dartx.remainder](-9));
    }
  };
  dart.setSignature(int_test.IntTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.void, [])}),
    names: ['testMain']
  });
  int_test.main = function() {
    int_test.IntTest.testMain();
  };
  dart.fn(int_test.main, VoidTodynamic());
  // Exports:
  exports.int_test = int_test;
});
