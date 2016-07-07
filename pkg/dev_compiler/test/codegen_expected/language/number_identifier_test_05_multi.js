dart_library.library('language/number_identifier_test_05_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__number_identifier_test_05_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const number_identifier_test_05_multi = Object.create(null);
  let VoidTodouble = () => (VoidTodouble = dart.constFn(dart.definiteFunctionType(core.double, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  number_identifier_test_05_multi.main = function() {
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
    expect$.Expect.throws(dart.fn(() => 100.0, VoidTodouble()), dart.fn(e => core.NoSuchMethodError.is(e), dynamicTobool()));
  };
  dart.fn(number_identifier_test_05_multi.main, VoidTodynamic());
  // Exports:
  exports.number_identifier_test_05_multi = number_identifier_test_05_multi;
});
