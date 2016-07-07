dart_library.library('corelib/date_time2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__date_time2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const date_time2_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  date_time2_test.main = function() {
    let d = core.DateTime.parse("2000-01-01T00:00:00Z");
    let d2 = core.DateTime.parse("2000-01-01T00:00:01Z");
    expect$.Expect.isFalse(dart.hashCode(d) == dart.hashCode(d2));
  };
  dart.fn(date_time2_test.main, VoidTodynamic());
  // Exports:
  exports.date_time2_test = date_time2_test;
});
