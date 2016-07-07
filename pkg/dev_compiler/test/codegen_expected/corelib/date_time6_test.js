dart_library.library('corelib/date_time6_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__date_time6_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const date_time6_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  date_time6_test.main = function() {
    let d = new core.DateTime.fromMillisecondsSinceEpoch(0, {isUtc: true});
    let d2 = new core.DateTime.fromMillisecondsSinceEpoch(1, {isUtc: true});
    expect$.Expect.isTrue(d.isBefore(d2));
    expect$.Expect.isTrue(!dart.test(d.isAfter(d2)));
    expect$.Expect.isTrue(d2.isAfter(d));
    expect$.Expect.isTrue(!dart.test(d2.isBefore(d)));
    expect$.Expect.isFalse(d2.isBefore(d));
    expect$.Expect.isFalse(!dart.test(d2.isAfter(d)));
    expect$.Expect.isFalse(d.isAfter(d2));
    expect$.Expect.isFalse(!dart.test(d.isBefore(d2)));
    d = new core.DateTime.fromMillisecondsSinceEpoch(-1, {isUtc: true});
    d2 = new core.DateTime.fromMillisecondsSinceEpoch(0, {isUtc: true});
    expect$.Expect.isTrue(d.isBefore(d2));
    expect$.Expect.isTrue(!dart.test(d.isAfter(d2)));
    expect$.Expect.isTrue(d2.isAfter(d));
    expect$.Expect.isTrue(!dart.test(d2.isBefore(d)));
    expect$.Expect.isFalse(d2.isBefore(d));
    expect$.Expect.isFalse(!dart.test(d2.isAfter(d)));
    expect$.Expect.isFalse(d.isAfter(d2));
    expect$.Expect.isFalse(!dart.test(d.isBefore(d2)));
  };
  dart.fn(date_time6_test.main, VoidTodynamic());
  // Exports:
  exports.date_time6_test = date_time6_test;
});
