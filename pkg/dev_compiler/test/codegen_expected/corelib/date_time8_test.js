dart_library.library('corelib/date_time8_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__date_time8_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const date_time8_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  date_time8_test.testUtc = function() {
    let d = new core.DateTime.utc(0, 1, 1);
    expect$.Expect.equals("0000-01-01 00:00:00.000Z", d.toString());
  };
  dart.fn(date_time8_test.testUtc, VoidTodynamic());
  date_time8_test.testLocal = function() {
    let d = new core.DateTime(0, 1, 1);
    expect$.Expect.equals("0000-01-01 00:00:00.000", d.toString());
  };
  dart.fn(date_time8_test.testLocal, VoidTodynamic());
  date_time8_test.main = function() {
    date_time8_test.testUtc();
    date_time8_test.testLocal();
  };
  dart.fn(date_time8_test.main, VoidTodynamic());
  // Exports:
  exports.date_time8_test = date_time8_test;
});
