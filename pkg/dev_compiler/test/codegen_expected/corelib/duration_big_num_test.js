dart_library.library('corelib/duration_big_num_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__duration_big_num_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const math = dart_sdk.math;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const duration_big_num_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  duration_big_num_test.main = function() {
    let d = null, d1 = null;
    d1 = new core.Duration({microseconds: dart.asInt(math.pow(2, 53))});
    d = d1['*'](2);
    expect$.Expect.equals(math.pow(2, 54), d.inMicroseconds);
    d = d1['*'](1.5);
    expect$.Expect.equals(dart.notNull(math.pow(2, 53)[dartx.toDouble]()) * 1.5, d.inMicroseconds);
    expect$.Expect.isTrue(typeof d.inMicroseconds == 'number');
    d = new core.Duration({microseconds: dart.asInt(dart.notNull(math.pow(2, 53)) + 1)})['*'](1.0);
    expect$.Expect.equals(0, d.inMicroseconds[dartx['%']](2));
  };
  dart.fn(duration_big_num_test.main, VoidTodynamic());
  // Exports:
  exports.duration_big_num_test = duration_big_num_test;
});
