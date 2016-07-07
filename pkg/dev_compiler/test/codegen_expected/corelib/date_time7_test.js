dart_library.library('corelib/date_time7_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__date_time7_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const date_time7_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let StringAndDurationTodynamic = () => (StringAndDurationTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.String, core.Duration])))();
  date_time7_test.testUtc = function() {
    let d = core.DateTime.parse("2012-03-04T03:25:38.123Z");
    expect$.Expect.equals("UTC", d.timeZoneName);
    expect$.Expect.equals(0, d.timeZoneOffset.inSeconds);
  };
  dart.fn(date_time7_test.testUtc, VoidTodynamic());
  date_time7_test.testLocal = function() {
    function checkOffset(name, offset) {
      if (name == "CET") {
        expect$.Expect.equals(1, offset.inHours);
      } else if (name == "CEST") {
        expect$.Expect.equals(2, offset.inHours);
      } else if (name == "GMT") {
        expect$.Expect.equals(0, offset.inSeconds);
      } else if (name == "EST") {
        expect$.Expect.equals(-5, offset.inHours);
      } else if (name == "EDT") {
        expect$.Expect.equals(-4, offset.inHours);
      } else if (name == "PDT") {
        expect$.Expect.equals(-7, offset.inHours);
      }
    }
    dart.fn(checkOffset, StringAndDurationTodynamic());
    let d = core.DateTime.parse("2012-01-02T13:45:23");
    let name = d.timeZoneName;
    checkOffset(name, d.timeZoneOffset);
    d = core.DateTime.parse("2012-07-02T13:45:23");
    name = d.timeZoneName;
    checkOffset(name, d.timeZoneOffset);
  };
  dart.fn(date_time7_test.testLocal, VoidTodynamic());
  date_time7_test.main = function() {
    date_time7_test.testUtc();
    date_time7_test.testLocal();
  };
  dart.fn(date_time7_test.main, VoidTodynamic());
  // Exports:
  exports.date_time7_test = date_time7_test;
});
