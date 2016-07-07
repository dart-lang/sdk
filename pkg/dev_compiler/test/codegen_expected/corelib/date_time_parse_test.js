dart_library.library('corelib/date_time_parse_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__date_time_parse_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const date_time_parse_test = Object.create(null);
  let DateTimeAndStringTodynamic = () => (DateTimeAndStringTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.DateTime, core.String])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  date_time_parse_test.check = function(expected, str) {
    let actual = core.DateTime.parse(str);
    expect$.Expect.equals(expected, actual);
    expect$.Expect.equals(expected.isUtc, actual.isUtc);
  };
  dart.fn(date_time_parse_test.check, DateTimeAndStringTodynamic());
  dart.copyProperties(date_time_parse_test, {
    get supportsMicroseconds() {
      return new core.DateTime.fromMicrosecondsSinceEpoch(1).microsecondsSinceEpoch == 1;
    }
  });
  date_time_parse_test.main = function() {
    date_time_parse_test.check(new core.DateTime(2012, 2, 27, 13, 27), "2012-02-27 13:27:00");
    if (dart.test(date_time_parse_test.supportsMicroseconds)) {
      date_time_parse_test.check(new core.DateTime.utc(2012, 2, 27, 13, 27, 0, 123, 456), "2012-02-27 13:27:00.123456z");
    } else {
      date_time_parse_test.check(new core.DateTime.utc(2012, 2, 27, 13, 27, 0, 123, 456), "2012-02-27 13:27:00.123z");
    }
    date_time_parse_test.check(new core.DateTime(2012, 2, 27, 13, 27), "20120227 13:27:00");
    date_time_parse_test.check(new core.DateTime(2012, 2, 27, 13, 27), "20120227T132700");
    date_time_parse_test.check(new core.DateTime(2012, 2, 27), "20120227");
    date_time_parse_test.check(new core.DateTime(2012, 2, 27), "+20120227");
    date_time_parse_test.check(new core.DateTime.utc(2012, 2, 27, 14), "2012-02-27T14Z");
    date_time_parse_test.check(new core.DateTime.utc(-12345, 1, 1), "-123450101 00:00:00 Z");
    date_time_parse_test.check(new core.DateTime.utc(2012, 2, 27, 14), "2012-02-27T14+00");
    date_time_parse_test.check(new core.DateTime.utc(2012, 2, 27, 14), "2012-02-27T14+0000");
    date_time_parse_test.check(new core.DateTime.utc(2012, 2, 27, 14), "2012-02-27T14+00:00");
    date_time_parse_test.check(new core.DateTime.utc(2012, 2, 27, 14), "2012-02-27T14 +00:00");
    date_time_parse_test.check(new core.DateTime.utc(2015, 2, 14, 13, 0, 0, 0), "2015-02-15T00:00+11");
    date_time_parse_test.check(new core.DateTime.utc(2015, 2, 14, 13, 0, 0, 0), "2015-02-15T00:00:00+11");
    date_time_parse_test.check(new core.DateTime.utc(2015, 2, 14, 13, 0, 0, 0), "2015-02-15T00:00:00+11:00");
    if (dart.test(date_time_parse_test.supportsMicroseconds)) {
      date_time_parse_test.check(new core.DateTime.utc(2015, 2, 15, 0, 0, 0, 500, 500), "2015-02-15T00:00:00.500500Z");
      date_time_parse_test.check(new core.DateTime.utc(2015, 2, 15, 0, 0, 0, 511, 500), "2015-02-15T00:00:00.511500Z");
    } else {
      date_time_parse_test.check(new core.DateTime.utc(2015, 2, 15, 0, 0, 0, 501), "2015-02-15T00:00:00.501Z");
      date_time_parse_test.check(new core.DateTime.utc(2015, 2, 15, 0, 0, 0, 512), "2015-02-15T00:00:00.512Z");
    }
  };
  dart.fn(date_time_parse_test.main, VoidTodynamic());
  // Exports:
  exports.date_time_parse_test = date_time_parse_test;
});
