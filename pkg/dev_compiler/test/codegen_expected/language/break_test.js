dart_library.library('language/break_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__break_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const break_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  break_test.BreakTest = class BreakTest extends core.Object {
    static testMain() {
      let i = null;
      let forCounter = 0;
      for (i = 0; dart.notNull(i) < 10; i = dart.notNull(i) + 1) {
        forCounter++;
        if (dart.notNull(i) > 3) break;
      }
      expect$.Expect.equals(5, forCounter);
      expect$.Expect.equals(4, i);
      i = 0;
      let doWhileCounter = 0;
      do {
        i = dart.notNull(i) + 1;
        doWhileCounter++;
        if (dart.notNull(i) > 3) break;
      } while (dart.notNull(i) < 10);
      expect$.Expect.equals(4, doWhileCounter);
      expect$.Expect.equals(4, i);
      i = 0;
      let whileCounter = 0;
      while (dart.notNull(i) < 10) {
        i = dart.notNull(i) + 1;
        whileCounter++;
        if (dart.notNull(i) > 3) break;
      }
      expect$.Expect.equals(4, whileCounter);
      expect$.Expect.equals(4, i);
      i = 0;
      L:
        while (dart.notNull(i) < 10) {
          i = dart.notNull(i) + 1;
          while (dart.notNull(i) > 5) {
            break L;
          }
        }
      expect$.Expect.equals(6, i);
    }
  };
  dart.setSignature(break_test.BreakTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  break_test.main = function() {
    break_test.BreakTest.testMain();
  };
  dart.fn(break_test.main, VoidTodynamic());
  // Exports:
  exports.break_test = break_test;
});
