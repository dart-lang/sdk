dart_library.library('corelib/stopwatch2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__stopwatch2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const stopwatch2_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  stopwatch2_test.main = function() {
    let sw = new core.Stopwatch();
    sw.start();
    while (dart.notNull(sw.elapsedMilliseconds) < 2) {
    }
    sw.stop();
    expect$.Expect.equals(sw.elapsedMicroseconds, sw.elapsed.inMicroseconds);
    expect$.Expect.equals(sw.elapsedMilliseconds, sw.elapsed.inMilliseconds);
  };
  dart.fn(stopwatch2_test.main, VoidTodynamic());
  // Exports:
  exports.stopwatch2_test = stopwatch2_test;
});
