dart_library.library('corelib/date_time4_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__date_time4_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const date_time4_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  dart.copyProperties(date_time4_test, {
    get supportsMicroseconds() {
      return new core.DateTime.fromMicrosecondsSinceEpoch(1).microsecondsSinceEpoch == 1;
    }
  });
  date_time4_test.main = function() {
    if (dart.test(date_time4_test.supportsMicroseconds)) {
      date_time4_test.testMicrosecondPrecision();
    } else {
      date_time4_test.testMillisecondPrecision();
    }
  };
  dart.fn(date_time4_test.main, VoidTodynamic());
  date_time4_test.testMillisecondPrecision = function() {
    let dt1 = core.DateTime.parse("1999-01-02 23:59:59.999519");
    expect$.Expect.equals(1999, dt1.year);
    expect$.Expect.equals(1, dt1.month);
    expect$.Expect.equals(3, dt1.day);
    expect$.Expect.equals(0, dt1.hour);
    expect$.Expect.equals(0, dt1.minute);
    expect$.Expect.equals(0, dt1.second);
    expect$.Expect.equals(0, dt1.millisecond);
    expect$.Expect.equals(false, dt1.isUtc);
    dt1 = core.DateTime.parse("1999-01-02 23:58:59.999519Z");
    expect$.Expect.equals(1999, dt1.year);
    expect$.Expect.equals(1, dt1.month);
    expect$.Expect.equals(2, dt1.day);
    expect$.Expect.equals(23, dt1.hour);
    expect$.Expect.equals(59, dt1.minute);
    expect$.Expect.equals(0, dt1.second);
    expect$.Expect.equals(0, dt1.millisecond);
    expect$.Expect.equals(true, dt1.isUtc);
    dt1 = core.DateTime.parse("0009-09-09 09:09:09.009411Z");
    expect$.Expect.equals(9, dt1.year);
    expect$.Expect.equals(9, dt1.month);
    expect$.Expect.equals(9, dt1.day);
    expect$.Expect.equals(9, dt1.hour);
    expect$.Expect.equals(9, dt1.minute);
    expect$.Expect.equals(9, dt1.second);
    expect$.Expect.equals(9, dt1.millisecond);
    expect$.Expect.equals(true, dt1.isUtc);
    let svnDate = "2012-03-30T04:28:13.752341Z";
    dt1 = core.DateTime.parse(svnDate);
    expect$.Expect.equals(2012, dt1.year);
    expect$.Expect.equals(3, dt1.month);
    expect$.Expect.equals(30, dt1.day);
    expect$.Expect.equals(4, dt1.hour);
    expect$.Expect.equals(28, dt1.minute);
    expect$.Expect.equals(13, dt1.second);
    expect$.Expect.equals(752, dt1.millisecond);
    expect$.Expect.equals(true, dt1.isUtc);
  };
  dart.fn(date_time4_test.testMillisecondPrecision, VoidTovoid());
  date_time4_test.testMicrosecondPrecision = function() {
    let dt1 = core.DateTime.parse("1999-01-02 23:59:59.999519");
    expect$.Expect.equals(1999, dt1.year);
    expect$.Expect.equals(1, dt1.month);
    expect$.Expect.equals(2, dt1.day);
    expect$.Expect.equals(23, dt1.hour);
    expect$.Expect.equals(59, dt1.minute);
    expect$.Expect.equals(59, dt1.second);
    expect$.Expect.equals(999, dt1.millisecond);
    expect$.Expect.equals(519, dt1.microsecond);
    expect$.Expect.equals(false, dt1.isUtc);
    dt1 = core.DateTime.parse("1999-01-02 23:58:59.999519Z");
    expect$.Expect.equals(1999, dt1.year);
    expect$.Expect.equals(1, dt1.month);
    expect$.Expect.equals(2, dt1.day);
    expect$.Expect.equals(23, dt1.hour);
    expect$.Expect.equals(58, dt1.minute);
    expect$.Expect.equals(59, dt1.second);
    expect$.Expect.equals(999, dt1.millisecond);
    expect$.Expect.equals(519, dt1.microsecond);
    expect$.Expect.equals(true, dt1.isUtc);
    dt1 = core.DateTime.parse("0009-09-09 09:09:09.009411Z");
    expect$.Expect.equals(9, dt1.year);
    expect$.Expect.equals(9, dt1.month);
    expect$.Expect.equals(9, dt1.day);
    expect$.Expect.equals(9, dt1.hour);
    expect$.Expect.equals(9, dt1.minute);
    expect$.Expect.equals(9, dt1.second);
    expect$.Expect.equals(9, dt1.millisecond);
    expect$.Expect.equals(411, dt1.microsecond);
    expect$.Expect.equals(true, dt1.isUtc);
    let svnDate = "2012-03-30T04:28:13.752341Z";
    dt1 = core.DateTime.parse(svnDate);
    expect$.Expect.equals(2012, dt1.year);
    expect$.Expect.equals(3, dt1.month);
    expect$.Expect.equals(30, dt1.day);
    expect$.Expect.equals(4, dt1.hour);
    expect$.Expect.equals(28, dt1.minute);
    expect$.Expect.equals(13, dt1.second);
    expect$.Expect.equals(752, dt1.millisecond);
    expect$.Expect.equals(341, dt1.microsecond);
    expect$.Expect.equals(true, dt1.isUtc);
  };
  dart.fn(date_time4_test.testMicrosecondPrecision, VoidTovoid());
  // Exports:
  exports.date_time4_test = date_time4_test;
});
