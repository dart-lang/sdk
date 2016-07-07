dart_library.library('corelib/date_time3_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__date_time3_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const date_time3_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  date_time3_test.main = function() {
    let s = "2012-01-30 08:30:00.010";
    let d = core.DateTime.parse(s);
    expect$.Expect.equals(s, dart.toString(d));
  };
  dart.fn(date_time3_test.main, VoidTodynamic());
  // Exports:
  exports.date_time3_test = date_time3_test;
});
