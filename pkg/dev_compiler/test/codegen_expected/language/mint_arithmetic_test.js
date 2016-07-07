dart_library.library('language/mint_arithmetic_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__mint_arithmetic_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const mint_arithmetic_test = Object.create(null);
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  mint_arithmetic_test.test_and_1 = function() {
    try {
      function f(a, b) {
        let s = b;
        let t = dart.dsend(a, '&', s);
        return dart.equals(t, b);
      }
      dart.fn(f, dynamicAnddynamicTodynamic());
      let x = 4294967295;
      for (let i = 0; i < 20; i++)
        f(x, 0);
      expect$.Expect.equals(true, f(x, 0));
      expect$.Expect.equals(false, f(x, -1));
    } finally {
    }
  };
  dart.fn(mint_arithmetic_test.test_and_1, VoidTodynamic());
  mint_arithmetic_test.test_and_2 = function() {
    try {
      function f(a, b) {
        return dart.dsend(a, '&', b);
      }
      dart.fn(f, dynamicAnddynamicTodynamic());
      let x = 4294967295;
      for (let i = 0; i < 20; i++)
        f(x, x);
      expect$.Expect.equals(x, f(x, x));
      expect$.Expect.equals(1234, f(4294967295, 1234));
      expect$.Expect.equals(4294967297, f(4294967297, -1));
      expect$.Expect.equals(-1073741824, f(-1073741824, -1));
      expect$.Expect.equals(1073741824, f(1073741824, -1));
      expect$.Expect.equals(1073741823, f(1073741823, -1));
    } finally {
    }
  };
  dart.fn(mint_arithmetic_test.test_and_2, VoidTodynamic());
  mint_arithmetic_test.test_xor_1 = function() {
    try {
      function f(a, b) {
        let s = b;
        let t = dart.dsend(a, '^', s);
        return t;
      }
      dart.fn(f, dynamicAnddynamicTodynamic());
      let x = 4294967295;
      for (let i = 0; i < 20; i++)
        f(x, x);
      expect$.Expect.equals(0, f(x, x));
      expect$.Expect.equals(-x - 1, f(x, -1));
      let y = 18446744073709551615;
      expect$.Expect.equals(-y - 1, f(y, -1));
    } finally {
    }
  };
  dart.fn(mint_arithmetic_test.test_xor_1, VoidTodynamic());
  mint_arithmetic_test.test_or_1 = function() {
    try {
      function f(a, b) {
        let s = b;
        let t = dart.dsend(a, '|', s);
        return t;
      }
      dart.fn(f, dynamicAnddynamicTodynamic());
      let x = 4294967295;
      for (let i = 0; i < 20; i++)
        f(x, x);
      expect$.Expect.equals(x, f(x, x));
      expect$.Expect.equals(-1, f(x, -1));
      let y = 18446744073709551615;
      expect$.Expect.equals(-1, f(y, -1));
    } finally {
    }
  };
  dart.fn(mint_arithmetic_test.test_or_1, VoidTodynamic());
  mint_arithmetic_test.test_func = function(x, y) {
    return dart.dsend(dart.dsend(x, '&', y), '+', 1.0);
  };
  dart.fn(mint_arithmetic_test.test_func, dynamicAnddynamicTodynamic());
  mint_arithmetic_test.test_mint_double_op = function() {
    for (let i = 0; i < 20; i++)
      mint_arithmetic_test.test_func(4294967295, 1);
    expect$.Expect.equals(2.0, mint_arithmetic_test.test_func(4294967295, 1));
  };
  dart.fn(mint_arithmetic_test.test_mint_double_op, VoidTodynamic());
  mint_arithmetic_test.main = function() {
    for (let i = 0; i < 5; i++) {
      mint_arithmetic_test.test_and_1();
      mint_arithmetic_test.test_and_2();
      mint_arithmetic_test.test_xor_1();
      mint_arithmetic_test.test_or_1();
      mint_arithmetic_test.test_mint_double_op();
    }
  };
  dart.fn(mint_arithmetic_test.main, VoidTodynamic());
  // Exports:
  exports.mint_arithmetic_test = mint_arithmetic_test;
});
