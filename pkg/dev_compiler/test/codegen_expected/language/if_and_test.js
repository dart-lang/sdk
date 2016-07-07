dart_library.library('language/if_and_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__if_and_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const if_and_test = Object.create(null);
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  if_and_test._shiftRight = function(x, y) {
    return x;
  };
  dart.fn(if_and_test._shiftRight, dynamicAnddynamicTodynamic());
  if_and_test.int64_bits = function(x) {
    return x;
  };
  dart.fn(if_and_test.int64_bits, dynamicTodynamic());
  if_and_test.A = class A extends core.Object {
    opshr(n, a2) {
      let res2 = null;
      let negative = dart.equals(a2, 496);
      res2 = core.int._check(if_and_test._shiftRight(a2, n));
      if (negative) {
        res2 = (dart.notNull(res2) | 3) >>> 0;
      }
      return if_and_test.int64_bits(res2);
    }
  };
  dart.setSignature(if_and_test.A, {
    methods: () => ({opshr: dart.definiteFunctionType(dart.dynamic, [core.int, dart.dynamic])})
  });
  if_and_test.main = function() {
    let a = new if_and_test.A();
    let t = null;
    for (let i = 0; i < 3; i++) {
      t = a.opshr(99, 496);
    }
    expect$.Expect.equals(499, t);
  };
  dart.fn(if_and_test.main, VoidTodynamic());
  // Exports:
  exports.if_and_test = if_and_test;
});
