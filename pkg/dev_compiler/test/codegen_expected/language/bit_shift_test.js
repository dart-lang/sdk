dart_library.library('language/bit_shift_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__bit_shift_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const bit_shift_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  bit_shift_test.constants = function() {
    expect$.Expect.equals(0, (499)[dartx['>>']](33));
    expect$.Expect.equals(0, ((499)[dartx['<<']](33) & 4294967295) >>> 0);
  };
  dart.fn(bit_shift_test.constants, VoidTodynamic());
  bit_shift_test.foo = function(i) {
    if (!dart.equals(i, 0)) {
      bit_shift_test.y = dart.dsend(bit_shift_test.y, '-', 1);
      bit_shift_test.foo(dart.dsend(i, '-', 1));
      bit_shift_test.y = dart.dsend(bit_shift_test.y, '+', 1);
    }
  };
  dart.fn(bit_shift_test.foo, dynamicTodynamic());
  bit_shift_test.y = null;
  bit_shift_test.id = function(x) {
    bit_shift_test.y = x;
    bit_shift_test.foo(10);
    return bit_shift_test.y;
  };
  dart.fn(bit_shift_test.id, dynamicTodynamic());
  bit_shift_test.interceptors = function() {
    expect$.Expect.equals(0, dart.dsend(bit_shift_test.id(499), '>>', 33));
    expect$.Expect.equals(0, dart.dsend(dart.dsend(bit_shift_test.id(499), '<<', 33), '&', 4294967295));
  };
  dart.fn(bit_shift_test.interceptors, VoidTodynamic());
  bit_shift_test.speculative = function() {
    let a = bit_shift_test.id(499);
    for (let i = 0; i < 1; i++) {
      expect$.Expect.equals(0, dart.dsend(a, '>>', 33));
      expect$.Expect.equals(0, dart.dsend(dart.dsend(a, '<<', 33), '&', 4294967295));
    }
  };
  dart.fn(bit_shift_test.speculative, VoidTodynamic());
  bit_shift_test.main = function() {
    bit_shift_test.constants();
    bit_shift_test.interceptors();
    bit_shift_test.speculative();
  };
  dart.fn(bit_shift_test.main, VoidTodynamic());
  // Exports:
  exports.bit_shift_test = bit_shift_test;
});
