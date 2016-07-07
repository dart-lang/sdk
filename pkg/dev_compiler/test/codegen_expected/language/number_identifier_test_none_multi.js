dart_library.library('language/number_identifier_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__number_identifier_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const number_identifier_test_none_multi = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  number_identifier_test_none_multi.main = function() {
    expect$.Expect.isTrue(typeof 2 == 'number');
    expect$.Expect.equals(2, 2);
    expect$.Expect.isTrue(typeof -2 == 'number');
    expect$.Expect.equals(-2, -2);
    expect$.Expect.isTrue(typeof 16 == 'number');
    expect$.Expect.isTrue(typeof -16 == 'number');
    expect$.Expect.isTrue(typeof 2.0 == 'number');
    expect$.Expect.equals(2.0, 2.0);
    expect$.Expect.isTrue(typeof -2.0 == 'number');
    expect$.Expect.equals(-2.0, -2.0);
    expect$.Expect.isTrue(typeof 0.2 == 'number');
    expect$.Expect.equals(0.2, 0.2);
    expect$.Expect.isTrue(typeof 100.0 == 'number');
    expect$.Expect.equals(100.0, 100.0);
    expect$.Expect.isTrue(typeof 0.01 == 'number');
    expect$.Expect.equals(0.01, 0.01);
    expect$.Expect.isTrue(typeof 100.0 == 'number');
    expect$.Expect.equals(100.0, 100.0);
  };
  dart.fn(number_identifier_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.number_identifier_test_none_multi = number_identifier_test_none_multi;
});
