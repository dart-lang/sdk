dart_library.library('language/const_init_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__const_init_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const const_init_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  const_init_test.Point = class Point extends core.Object {
    new(x, y) {
      this.x_ = x;
      this.y_ = y;
    }
  };
  dart.setSignature(const_init_test.Point, {
    constructors: () => ({new: dart.definiteFunctionType(const_init_test.Point, [dart.dynamic, dart.dynamic])})
  });
  const_init_test.ConstInitTest = class ConstInitTest extends core.Object {
    static testMain() {
      expect$.Expect.equals(1, const_init_test.ConstInitTest.N);
      expect$.Expect.equals(4, const_init_test.ConstInitTest.O);
      expect$.Expect.equals(6, const_init_test.ConstInitTest.P);
      expect$.Expect.equals(0, const_init_test.ConstInitTest.Q.x_);
      expect$.Expect.equals(0, const_init_test.ConstInitTest.Q.y_);
    }
  };
  dart.setSignature(const_init_test.ConstInitTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  const_init_test.ConstInitTest.N = 1;
  const_init_test.ConstInitTest.O = 1 + 3;
  const_init_test.ConstInitTest.Q = dart.const(new const_init_test.Point(0, 0));
  const_init_test.ConstInitTest.Q2 = dart.const(new const_init_test.Point(0, 0));
  const_init_test.ConstInitTest.O2 = 1 + 3;
  const_init_test.ConstInitTest.N2 = 1;
  dart.defineLazy(const_init_test.ConstInitTest, {
    get P() {
      return 2 * (const_init_test.ConstInitTest.O - const_init_test.ConstInitTest.N);
    },
    get P2() {
      return 2 * (const_init_test.ConstInitTest.O - const_init_test.ConstInitTest.N);
    }
  });
  const_init_test.main = function() {
    const_init_test.ConstInitTest.testMain();
  };
  dart.fn(const_init_test.main, VoidTodynamic());
  // Exports:
  exports.const_init_test = const_init_test;
});
