dart_library.library('corelib/stopwatch_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__stopwatch_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const stopwatch_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  stopwatch_test.StopwatchTest = class StopwatchTest extends core.Object {
    static checkTicking(sw) {
      expect$.Expect.isFalse(sw.isRunning);
      sw.start();
      expect$.Expect.isTrue(sw.isRunning);
      for (let i = 0; i < 1000000; i++) {
        core.int.parse(dart.toString(i));
        if (dart.notNull(sw.elapsedTicks) > 0) {
          break;
        }
      }
      return dart.notNull(sw.elapsedTicks) > 0;
    }
    static checkStopping(sw) {
      sw.stop();
      expect$.Expect.isFalse(sw.isRunning);
      let v1 = sw.elapsedTicks;
      expect$.Expect.isTrue(dart.notNull(v1) > 0);
      let sw2 = new core.Stopwatch();
      sw2.start();
      expect$.Expect.isTrue(sw2.isRunning);
      let sw2LastElapsed = 0;
      for (let i = 0; i < 100000; i++) {
        core.int.parse(dart.toString(i));
        let v2 = sw.elapsedTicks;
        if (v1 != v2) {
          return false;
        }
        if (dart.notNull(sw2LastElapsed) > 0 && dart.notNull(sw2.elapsedTicks) > dart.notNull(sw2LastElapsed)) {
          break;
        }
        sw2LastElapsed = sw2.elapsedTicks;
      }
      expect$.Expect.isTrue(dart.notNull(sw2.elapsedTicks) > 0);
      return true;
    }
    static checkRestart() {
      let sw = new core.Stopwatch();
      expect$.Expect.isFalse(sw.isRunning);
      sw.start();
      expect$.Expect.isTrue(sw.isRunning);
      for (let i = 0; i < 100000; i++) {
        core.int.parse(dart.toString(i));
        if (dart.notNull(sw.elapsedTicks) > 0) {
          break;
        }
      }
      sw.stop();
      expect$.Expect.isFalse(sw.isRunning);
      let initial = sw.elapsedTicks;
      sw.start();
      expect$.Expect.isTrue(sw.isRunning);
      for (let i = 0; i < 100000; i++) {
        core.int.parse(dart.toString(i));
        if (dart.notNull(sw.elapsedTicks) > dart.notNull(initial)) {
          break;
        }
      }
      sw.stop();
      expect$.Expect.isFalse(sw.isRunning);
      expect$.Expect.isTrue(dart.notNull(sw.elapsedTicks) > dart.notNull(initial));
    }
    static checkReset() {
      let sw = new core.Stopwatch();
      expect$.Expect.isFalse(sw.isRunning);
      sw.start();
      expect$.Expect.isTrue(sw.isRunning);
      for (let i = 0; i < 100000; i++) {
        core.int.parse(dart.toString(i));
        if (dart.notNull(sw.elapsedTicks) > 0) {
          break;
        }
      }
      sw.stop();
      expect$.Expect.isFalse(sw.isRunning);
      sw.reset();
      expect$.Expect.isFalse(sw.isRunning);
      expect$.Expect.equals(0, sw.elapsedTicks);
      sw.start();
      expect$.Expect.isTrue(sw.isRunning);
      for (let i = 0; i < 100000; i++) {
        core.int.parse(dart.toString(i));
        if (dart.notNull(sw.elapsedTicks) > 0) {
          break;
        }
      }
      sw.reset();
      expect$.Expect.isTrue(sw.isRunning);
      for (let i = 0; i < 100000; i++) {
        core.int.parse(dart.toString(i));
        if (dart.notNull(sw.elapsedTicks) > 0) {
          break;
        }
      }
      sw.stop();
      expect$.Expect.isFalse(sw.isRunning);
      expect$.Expect.isTrue(dart.notNull(sw.elapsedTicks) > 0);
    }
    static testMain() {
      let sw = new core.Stopwatch();
      expect$.Expect.isTrue(stopwatch_test.StopwatchTest.checkTicking(sw));
      expect$.Expect.isTrue(stopwatch_test.StopwatchTest.checkStopping(sw));
      stopwatch_test.StopwatchTest.checkRestart();
      stopwatch_test.StopwatchTest.checkReset();
    }
  };
  dart.setSignature(stopwatch_test.StopwatchTest, {
    statics: () => ({
      checkTicking: dart.definiteFunctionType(core.bool, [core.Stopwatch]),
      checkStopping: dart.definiteFunctionType(core.bool, [core.Stopwatch]),
      checkRestart: dart.definiteFunctionType(dart.dynamic, []),
      checkReset: dart.definiteFunctionType(dart.dynamic, []),
      testMain: dart.definiteFunctionType(dart.dynamic, [])
    }),
    names: ['checkTicking', 'checkStopping', 'checkRestart', 'checkReset', 'testMain']
  });
  stopwatch_test.main = function() {
    stopwatch_test.StopwatchTest.testMain();
  };
  dart.fn(stopwatch_test.main, VoidTodynamic());
  // Exports:
  exports.stopwatch_test = stopwatch_test;
});
