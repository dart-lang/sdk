dart_library.library('language/positive_bit_operations_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__positive_bit_operations_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const positive_bit_operations_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  positive_bit_operations_test.constants = function() {
    expect$.Expect.equals(2147483648, (2147483648 | 0) >>> 0);
    expect$.Expect.equals(2147483649, (2147483648 | 1) >>> 0);
    expect$.Expect.equals(2147483648, (2147483648 | 2147483648) >>> 0);
    expect$.Expect.equals(4294967295, (4294901760 | 65535) >>> 0);
    expect$.Expect.equals(2147483648, (2147483648 & 4294967295) >>> 0);
    expect$.Expect.equals(2147483648, (2147483648 & 2147483648) >>> 0);
    expect$.Expect.equals(2147483648, (2147483648 & 4026531840) >>> 0);
    expect$.Expect.equals(2147483648, (4294967295 & 2147483648) >>> 0);
    expect$.Expect.equals(2147483648, (2147483648 ^ 0) >>> 0);
    expect$.Expect.equals(4294967295, (2147483648 ^ 2147483647) >>> 0);
    expect$.Expect.equals(4294967295, (2147483647 ^ 2147483648) >>> 0);
    expect$.Expect.equals(4026531840, (1879048192 ^ 2147483648) >>> 0);
    expect$.Expect.equals(2147483648, 1 << 31 >>> 0);
    expect$.Expect.equals(4294967280, 268435455 << 4 >>> 0);
    expect$.Expect.equals(2147483647, 4294967295 >>> 1);
    expect$.Expect.equals(4294967292, (((268435455 << 4 >>> 0)[dartx['>>']](1) | 2147483648) >>> 2 ^ 1073741824) >>> 0 << 1 >>> 0);
  };
  dart.fn(positive_bit_operations_test.constants, VoidTodynamic());
  positive_bit_operations_test.foo = function(i) {
    if (!dart.equals(i, 0)) {
      positive_bit_operations_test.y = dart.dsend(positive_bit_operations_test.y, '-', 1);
      positive_bit_operations_test.foo(dart.dsend(i, '-', 1));
      positive_bit_operations_test.y = dart.dsend(positive_bit_operations_test.y, '+', 1);
    }
  };
  dart.fn(positive_bit_operations_test.foo, dynamicTodynamic());
  positive_bit_operations_test.y = null;
  positive_bit_operations_test.id = function(x) {
    positive_bit_operations_test.y = x;
    positive_bit_operations_test.foo(10);
    return positive_bit_operations_test.y;
  };
  dart.fn(positive_bit_operations_test.id, dynamicTodynamic());
  positive_bit_operations_test.interceptors = function() {
    expect$.Expect.equals(2147483648, dart.dsend(positive_bit_operations_test.id(2147483648), '|', positive_bit_operations_test.id(0)));
    expect$.Expect.equals(2147483649, dart.dsend(positive_bit_operations_test.id(2147483648), '|', positive_bit_operations_test.id(1)));
    expect$.Expect.equals(2147483648, dart.dsend(positive_bit_operations_test.id(2147483648), '|', positive_bit_operations_test.id(2147483648)));
    expect$.Expect.equals(4294967295, dart.dsend(positive_bit_operations_test.id(4294901760), '|', positive_bit_operations_test.id(65535)));
    expect$.Expect.equals(2147483648, dart.dsend(positive_bit_operations_test.id(2147483648), '&', positive_bit_operations_test.id(4294967295)));
    expect$.Expect.equals(2147483648, dart.dsend(positive_bit_operations_test.id(2147483648), '&', positive_bit_operations_test.id(2147483648)));
    expect$.Expect.equals(2147483648, dart.dsend(positive_bit_operations_test.id(2147483648), '&', positive_bit_operations_test.id(4026531840)));
    expect$.Expect.equals(2147483648, dart.dsend(positive_bit_operations_test.id(4294967295), '&', positive_bit_operations_test.id(2147483648)));
    expect$.Expect.equals(2147483648, dart.dsend(positive_bit_operations_test.id(2147483648), '^', positive_bit_operations_test.id(0)));
    expect$.Expect.equals(4294967295, dart.dsend(positive_bit_operations_test.id(2147483648), '^', positive_bit_operations_test.id(2147483647)));
    expect$.Expect.equals(4294967295, dart.dsend(positive_bit_operations_test.id(2147483647), '^', positive_bit_operations_test.id(2147483648)));
    expect$.Expect.equals(4026531840, dart.dsend(positive_bit_operations_test.id(1879048192), '^', positive_bit_operations_test.id(2147483648)));
    expect$.Expect.equals(2147483648, dart.dsend(positive_bit_operations_test.id(1), '<<', positive_bit_operations_test.id(31)));
    expect$.Expect.equals(4294967280, dart.dsend(positive_bit_operations_test.id(268435455), '<<', positive_bit_operations_test.id(4)));
    expect$.Expect.equals(2147483647, dart.dsend(positive_bit_operations_test.id(4294967295), '>>', positive_bit_operations_test.id(1)));
    expect$.Expect.equals(4294967292, dart.dsend(dart.dsend(dart.dsend(dart.dsend(dart.dsend(dart.dsend(positive_bit_operations_test.id(268435455), '<<', 4), '>>', 1), '|', 2147483648), '>>', 2), '^', 1073741824), '<<', 1));
  };
  dart.fn(positive_bit_operations_test.interceptors, VoidTodynamic());
  positive_bit_operations_test.speculative = function() {
    let a = positive_bit_operations_test.id(2147483648);
    let b = positive_bit_operations_test.id(0);
    let c = positive_bit_operations_test.id(1);
    let d = positive_bit_operations_test.id(4294901760);
    let e = positive_bit_operations_test.id(65535);
    let f = positive_bit_operations_test.id(4294967295);
    let g = positive_bit_operations_test.id(4026531840);
    let h = positive_bit_operations_test.id(2147483647);
    let j = positive_bit_operations_test.id(1879048192);
    let k = positive_bit_operations_test.id(31);
    let l = positive_bit_operations_test.id(4);
    let m = positive_bit_operations_test.id(268435455);
    for (let i = 0; i < 1; i++) {
      expect$.Expect.equals(2147483648, dart.dsend(a, '|', b));
      expect$.Expect.equals(2147483649, dart.dsend(a, '|', c));
      expect$.Expect.equals(2147483648, dart.dsend(a, '|', a));
      expect$.Expect.equals(4294967295, dart.dsend(d, '|', e));
      expect$.Expect.equals(2147483648, dart.dsend(a, '&', f));
      expect$.Expect.equals(2147483648, dart.dsend(a, '&', a));
      expect$.Expect.equals(2147483648, dart.dsend(a, '&', g));
      expect$.Expect.equals(2147483648, dart.dsend(f, '&', a));
      expect$.Expect.equals(2147483648, dart.dsend(a, '^', b));
      expect$.Expect.equals(4294967295, dart.dsend(a, '^', h));
      expect$.Expect.equals(4294967295, dart.dsend(h, '^', a));
      expect$.Expect.equals(4026531840, dart.dsend(j, '^', a));
      expect$.Expect.equals(2147483648, dart.dsend(c, '<<', k));
      expect$.Expect.equals(4294967280, dart.dsend(m, '<<', l));
      expect$.Expect.equals(2147483647, dart.dsend(f, '>>', c));
      expect$.Expect.equals(4294967292, dart.dsend(dart.dsend(dart.dsend(dart.dsend(dart.dsend(dart.dsend(m, '<<', 4), '>>', 1), '|', 2147483648), '>>', 2), '^', 1073741824), '<<', 1));
    }
  };
  dart.fn(positive_bit_operations_test.speculative, VoidTodynamic());
  positive_bit_operations_test.precedence = function() {
    expect$.Expect.equals(2147483648, (-1 & 2147483648) >>> 0);
    expect$.Expect.equals(2147483648, dart.dsend(positive_bit_operations_test.id(-1), '&', 2147483648));
    expect$.Expect.equals(2147483648, ~~2147483648 >>> 0);
    expect$.Expect.equals(2147483648, dart.dsend(dart.dsend(positive_bit_operations_test.id(2147483648), '~'), '~'));
  };
  dart.fn(positive_bit_operations_test.precedence, VoidTodynamic());
  positive_bit_operations_test.main = function() {
    positive_bit_operations_test.constants();
    positive_bit_operations_test.interceptors();
    positive_bit_operations_test.speculative();
    positive_bit_operations_test.precedence();
  };
  dart.fn(positive_bit_operations_test.main, VoidTodynamic());
  // Exports:
  exports.positive_bit_operations_test = positive_bit_operations_test;
});
