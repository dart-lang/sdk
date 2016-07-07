dart_library.library('language/range_analysis3_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__range_analysis3_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const range_analysis3_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  range_analysis3_test.confuse = function(x) {
    if (new core.DateTime.now().millisecondsSinceEpoch == 0) {
      return range_analysis3_test.confuse(dart.dsend(x, '+', 1));
    } else if (new core.DateTime.now().millisecondsSinceEpoch == 0) {
      return range_analysis3_test.confuse(dart.dsend(x, '-', 1));
    }
    return x;
  };
  dart.fn(range_analysis3_test.confuse, dynamicTodynamic());
  range_analysis3_test.test1 = function() {
    let x = 0;
    if (dart.equals(range_analysis3_test.confuse(0), 1)) x = -1;
    let y = 0;
    if (dart.equals(range_analysis3_test.confuse(0), 1)) y = 1;
    let zero = 0;
    let status = "bad";
    if (x < zero) {
      expect$.Expect.fail("unreachable");
    } else {
      if (y <= zero) {
        status = "good";
      }
    }
    expect$.Expect.equals("good", status);
  };
  dart.fn(range_analysis3_test.test1, VoidTodynamic());
  range_analysis3_test.test2 = function() {
    let x = 0;
    if (dart.equals(range_analysis3_test.confuse(0), 1)) x = -1;
    let y = 0;
    if (dart.equals(range_analysis3_test.confuse(0), 1)) y = 1;
    if (dart.equals(range_analysis3_test.confuse(1), 2)) y = -1;
    let status = "good";
    if (x < y) {
      expect$.Expect.fail("unreachable");
    } else {
      if (y == -1) {
        status = "bad";
      }
    }
    expect$.Expect.equals("good", status);
  };
  dart.fn(range_analysis3_test.test2, VoidTodynamic());
  range_analysis3_test.test3a = function() {
    let x = 0;
    if (dart.equals(range_analysis3_test.confuse(0), 1)) x = -1;
    if (dart.equals(range_analysis3_test.confuse(1), 2)) x = 1;
    let y = 0;
    if (dart.equals(range_analysis3_test.confuse(0), 1)) y = 1;
    if (dart.equals(range_analysis3_test.confuse(1), 2)) y = -1;
    let status = "good";
    if (x < y) {
      expect$.Expect.fail("unreachable");
    } else {
      if (x <= -1) status = "bad";
      if (x >= 1) status = "bad";
      if (x < 0) status = "bad";
      if (x > 0) status = "bad";
      if (-1 >= x) status = "bad";
      if (1 <= x) status = "bad";
      if (0 > x) status = "bad";
      if (0 < x) status = "bad";
      if (y <= -1) status = "bad";
      if (y >= 1) status = "bad";
      if (y < 0) status = "bad";
      if (y > 0) status = "bad";
      if (-1 >= y) status = "bad";
      if (1 <= y) status = "bad";
      if (0 > y) status = "bad";
      if (0 < y) status = "bad";
    }
    expect$.Expect.equals("good", status);
  };
  dart.fn(range_analysis3_test.test3a, VoidTodynamic());
  range_analysis3_test.test3b = function() {
    let x = 0;
    if (dart.equals(range_analysis3_test.confuse(0), 1)) x = -2;
    let y = 0;
    if (dart.equals(range_analysis3_test.confuse(0), 1)) y = 1;
    if (dart.equals(range_analysis3_test.confuse(1), 2)) y = -1;
    let status = "good";
    if (x < y) {
      expect$.Expect.fail("unreachable");
    } else {
      if (x <= -1) status = "bad";
      if (x >= 1) status = "bad";
      if (x < 0) status = "bad";
      if (x > 0) status = "bad";
      if (-1 >= x) status = "bad";
      if (1 <= x) status = "bad";
      if (0 > x) status = "bad";
      if (0 < x) status = "bad";
      if (y <= -1) status = "bad";
      if (y >= 1) status = "bad";
      if (y < 0) status = "bad";
      if (y > 0) status = "bad";
      if (-1 >= y) status = "bad";
      if (1 <= y) status = "bad";
      if (0 > y) status = "bad";
      if (0 < y) status = "bad";
    }
    expect$.Expect.equals("good", status);
  };
  dart.fn(range_analysis3_test.test3b, VoidTodynamic());
  range_analysis3_test.test4a = function() {
    let x = -1;
    if (dart.equals(range_analysis3_test.confuse(0), 1)) x = 1;
    let y = 0;
    if (dart.equals(range_analysis3_test.confuse(0), 1)) y = 1;
    if (dart.equals(range_analysis3_test.confuse(1), 2)) y = -1;
    let status = "good";
    if (x < y) {
      if (x <= -2) status = "bad";
      if (x >= 0) status = "bad";
      if (x < -1) status = "bad";
      if (x > -1) status = "bad";
      if (-2 >= x) status = "bad";
      if (0 <= x) status = "bad";
      if (-1 > x) status = "bad";
      if (-1 < x) status = "bad";
      if (y <= -1) status = "bad";
      if (y >= 1) status = "bad";
      if (y < 0) status = "bad";
      if (y > 0) status = "bad";
      if (-1 >= y) status = "bad";
      if (1 <= y) status = "bad";
      if (0 > y) status = "bad";
      if (0 < y) status = "bad";
    } else {
      expect$.Expect.fail("unreachable");
    }
    expect$.Expect.equals("good", status);
  };
  dart.fn(range_analysis3_test.test4a, VoidTodynamic());
  range_analysis3_test.test4b = function() {
    let x = -1;
    if (dart.equals(range_analysis3_test.confuse(0), 1)) x = -2;
    if (dart.equals(range_analysis3_test.confuse(1), 2)) x = 0;
    let y = 0;
    if (dart.equals(range_analysis3_test.confuse(0), 1)) y = 1;
    if (dart.equals(range_analysis3_test.confuse(1), 2)) y = -1;
    let status = "good";
    if (x < y) {
      if (x <= -2) status = "bad";
      if (x >= 0) status = "bad";
      if (x < -1) status = "bad";
      if (x > -1) status = "bad";
      if (-2 >= x) status = "bad";
      if (0 <= x) status = "bad";
      if (-1 > x) status = "bad";
      if (-1 < x) status = "bad";
      if (y <= -1) status = "bad";
      if (y >= 1) status = "bad";
      if (y < 0) status = "bad";
      if (y > 0) status = "bad";
      if (-1 >= y) status = "bad";
      if (1 <= y) status = "bad";
      if (0 > y) status = "bad";
      if (0 < y) status = "bad";
    } else {
      expect$.Expect.fail("unreachable");
    }
    expect$.Expect.equals("good", status);
  };
  dart.fn(range_analysis3_test.test4b, VoidTodynamic());
  range_analysis3_test.main = function() {
    range_analysis3_test.test1();
    range_analysis3_test.test2();
    range_analysis3_test.test3a();
    range_analysis3_test.test3b();
    range_analysis3_test.test4a();
    range_analysis3_test.test4b();
  };
  dart.fn(range_analysis3_test.main, VoidTodynamic());
  // Exports:
  exports.range_analysis3_test = range_analysis3_test;
});
