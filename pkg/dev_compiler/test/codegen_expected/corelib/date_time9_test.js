dart_library.library('corelib/date_time9_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__date_time9_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const date_time9_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  date_time9_test.main = function() {
    let dt = new core.DateTime.now();
    expect$.Expect.isTrue(core.Comparable.is(dt));
    let dt2 = new core.DateTime.fromMillisecondsSinceEpoch(100);
    let dt3 = new core.DateTime.fromMillisecondsSinceEpoch(200, {isUtc: true});
    let dt3b = new core.DateTime.fromMillisecondsSinceEpoch(200);
    let dt4 = new core.DateTime.fromMillisecondsSinceEpoch(300);
    let dt5 = new core.DateTime.fromMillisecondsSinceEpoch(400, {isUtc: true});
    let dt5b = new core.DateTime.fromMillisecondsSinceEpoch(400);
    expect$.Expect.isTrue(dt2.compareTo(dt2) == 0);
    expect$.Expect.isTrue(dt3.compareTo(dt3) == 0);
    expect$.Expect.isTrue(dt3b.compareTo(dt3b) == 0);
    expect$.Expect.isTrue(dt4.compareTo(dt4) == 0);
    expect$.Expect.isTrue(dt5.compareTo(dt5) == 0);
    expect$.Expect.isTrue(dt5b.compareTo(dt5b) == 0);
    expect$.Expect.isTrue(dt3.compareTo(dt3b) == 0);
    expect$.Expect.isTrue(dt5.compareTo(dt5b) == 0);
    expect$.Expect.isTrue(dart.notNull(dt2.compareTo(dt3)) < 0);
    expect$.Expect.isTrue(dart.notNull(dt3.compareTo(dt4)) < 0);
    expect$.Expect.isTrue(dart.notNull(dt4.compareTo(dt5)) < 0);
    expect$.Expect.isTrue(dart.notNull(dt2.compareTo(dt3b)) < 0);
    expect$.Expect.isTrue(dart.notNull(dt4.compareTo(dt5b)) < 0);
    expect$.Expect.isTrue(dart.notNull(dt3.compareTo(dt2)) > 0);
    expect$.Expect.isTrue(dart.notNull(dt4.compareTo(dt3)) > 0);
    expect$.Expect.isTrue(dart.notNull(dt5.compareTo(dt4)) > 0);
    expect$.Expect.isTrue(dart.notNull(dt3b.compareTo(dt2)) > 0);
    expect$.Expect.isTrue(dart.notNull(dt5b.compareTo(dt4)) > 0);
  };
  dart.fn(date_time9_test.main, VoidTodynamic());
  // Exports:
  exports.date_time9_test = date_time9_test;
});
