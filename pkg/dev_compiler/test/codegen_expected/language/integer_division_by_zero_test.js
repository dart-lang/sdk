dart_library.library('language/integer_division_by_zero_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__integer_division_by_zero_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const integer_division_by_zero_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  integer_division_by_zero_test.divBy0 = function(a) {
    return dart.dsend(a, '~/', 0);
  };
  dart.fn(integer_division_by_zero_test.divBy0, dynamicTodynamic());
  integer_division_by_zero_test.main = function() {
    expect$.Expect.throws(dart.fn(() => integer_division_by_zero_test.divBy0(4), VoidTovoid()), dart.fn(e => core.IntegerDivisionByZeroException.is(e), dynamicTobool()));
  };
  dart.fn(integer_division_by_zero_test.main, VoidTodynamic());
  // Exports:
  exports.integer_division_by_zero_test = integer_division_by_zero_test;
});
