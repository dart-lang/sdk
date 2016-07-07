dart_library.library('language/continue_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__continue_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const continue_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  continue_test.ContinueTest = class ContinueTest extends core.Object {
    static testMain() {
      let i = null;
      let forCounter = 0;
      for (i = 0; dart.notNull(i) < 10; i = dart.notNull(i) + 1) {
        if (dart.notNull(i) > 3) continue;
        forCounter++;
      }
      expect$.Expect.equals(4, forCounter);
      expect$.Expect.equals(10, i);
      i = 0;
      let doWhileCounter = 0;
      do {
        i = dart.notNull(i) + 1;
        if (dart.notNull(i) > 3) continue;
        doWhileCounter++;
      } while (dart.notNull(i) < 10);
      expect$.Expect.equals(3, doWhileCounter);
      expect$.Expect.equals(10, i);
      i = 0;
      let whileCounter = 0;
      while (dart.notNull(i) < 10) {
        i = dart.notNull(i) + 1;
        if (dart.notNull(i) > 3) continue;
        whileCounter++;
      }
      expect$.Expect.equals(3, whileCounter);
      expect$.Expect.equals(10, i);
      i = 0;
      L:
        while (dart.notNull(i) < 50) {
          i = dart.notNull(i) + 3;
          while (dart.notNull(i) < 30) {
            i = dart.notNull(i) + 2;
            if (dart.notNull(i) < 10) {
              continue L;
            } else {
              i = dart.notNull(i) + 1;
              break;
            }
          }
          break;
        }
      expect$.Expect.equals(11, i);
      do {
        i = 20;
        switch (0) {
          case 0:
          {
            i = 22;
            continue;
          }
          default:
          {
            i = 25;
            break;
          }
        }
        i = 30;
      } while (false);
      expect$.Expect.equals(22, i);
    }
  };
  dart.setSignature(continue_test.ContinueTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  continue_test.main = function() {
    continue_test.ContinueTest.testMain();
  };
  dart.fn(continue_test.main, VoidTodynamic());
  // Exports:
  exports.continue_test = continue_test;
});
