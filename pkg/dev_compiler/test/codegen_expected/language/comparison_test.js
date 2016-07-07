dart_library.library('language/comparison_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__comparison_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const comparison_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  comparison_test.Helper = class Helper extends core.Object {
    static STRICT_EQ(a, b) {
      return core.identical(a, b);
    }
    static STRICT_NE(a, b) {
      return !core.identical(a, b);
    }
    static EQ(a, b) {
      return dart.equals(a, b);
    }
    static NE(a, b) {
      return !dart.equals(a, b);
    }
    static LT(a, b) {
      return core.bool._check(dart.dsend(a, '<', b));
    }
    static LE(a, b) {
      return core.bool._check(dart.dsend(a, '<=', b));
    }
    static GT(a, b) {
      return core.bool._check(dart.dsend(a, '>', b));
    }
    static GE(a, b) {
      return core.bool._check(dart.dsend(a, '>=', b));
    }
  };
  dart.setSignature(comparison_test.Helper, {
    statics: () => ({
      STRICT_EQ: dart.definiteFunctionType(core.bool, [dart.dynamic, dart.dynamic]),
      STRICT_NE: dart.definiteFunctionType(core.bool, [dart.dynamic, dart.dynamic]),
      EQ: dart.definiteFunctionType(core.bool, [dart.dynamic, dart.dynamic]),
      NE: dart.definiteFunctionType(core.bool, [dart.dynamic, dart.dynamic]),
      LT: dart.definiteFunctionType(core.bool, [dart.dynamic, dart.dynamic]),
      LE: dart.definiteFunctionType(core.bool, [dart.dynamic, dart.dynamic]),
      GT: dart.definiteFunctionType(core.bool, [dart.dynamic, dart.dynamic]),
      GE: dart.definiteFunctionType(core.bool, [dart.dynamic, dart.dynamic])
    }),
    names: ['STRICT_EQ', 'STRICT_NE', 'EQ', 'NE', 'LT', 'LE', 'GT', 'GE']
  });
  comparison_test.A = class A extends core.Object {
    new(x) {
      this.b = x;
    }
  };
  dart.setSignature(comparison_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(comparison_test.A, [dart.dynamic])})
  });
  comparison_test.ComparisonTest = class ComparisonTest extends core.Object {
    static testMain() {
      let a = new comparison_test.A(0);
      let b = new comparison_test.A(1);
      expect$.Expect.isTrue(comparison_test.Helper.STRICT_EQ(a, a));
      expect$.Expect.isFalse(comparison_test.Helper.STRICT_EQ(a, b));
      expect$.Expect.isFalse(comparison_test.Helper.STRICT_EQ(b, a));
      expect$.Expect.isTrue(comparison_test.Helper.STRICT_EQ(b, b));
      expect$.Expect.isFalse(comparison_test.Helper.STRICT_NE(a, a));
      expect$.Expect.isTrue(comparison_test.Helper.STRICT_NE(a, b));
      expect$.Expect.isTrue(comparison_test.Helper.STRICT_NE(b, a));
      expect$.Expect.isFalse(comparison_test.Helper.STRICT_NE(b, b));
      expect$.Expect.isTrue(comparison_test.Helper.STRICT_EQ(false, false));
      expect$.Expect.isFalse(comparison_test.Helper.STRICT_EQ(false, true));
      expect$.Expect.isFalse(comparison_test.Helper.STRICT_EQ(true, false));
      expect$.Expect.isTrue(comparison_test.Helper.STRICT_EQ(true, true));
      expect$.Expect.isFalse(comparison_test.Helper.STRICT_NE(false, false));
      expect$.Expect.isTrue(comparison_test.Helper.STRICT_NE(false, true));
      expect$.Expect.isTrue(comparison_test.Helper.STRICT_NE(true, false));
      expect$.Expect.isFalse(comparison_test.Helper.STRICT_NE(true, true));
      expect$.Expect.isTrue(comparison_test.Helper.STRICT_EQ(false, false));
      expect$.Expect.isFalse(comparison_test.Helper.STRICT_EQ(false, true));
      expect$.Expect.isFalse(comparison_test.Helper.STRICT_EQ(true, false));
      expect$.Expect.isTrue(comparison_test.Helper.STRICT_EQ(true, true));
      expect$.Expect.isFalse(comparison_test.Helper.STRICT_NE(false, false));
      expect$.Expect.isTrue(comparison_test.Helper.STRICT_NE(false, true));
      expect$.Expect.isTrue(comparison_test.Helper.STRICT_NE(true, false));
      expect$.Expect.isFalse(comparison_test.Helper.STRICT_NE(true, true));
      expect$.Expect.isTrue(comparison_test.Helper.EQ(false, false));
      expect$.Expect.isFalse(comparison_test.Helper.EQ(false, true));
      expect$.Expect.isFalse(comparison_test.Helper.EQ(true, false));
      expect$.Expect.isTrue(comparison_test.Helper.EQ(true, true));
      expect$.Expect.isFalse(comparison_test.Helper.NE(false, false));
      expect$.Expect.isTrue(comparison_test.Helper.NE(false, true));
      expect$.Expect.isTrue(comparison_test.Helper.NE(true, false));
      expect$.Expect.isFalse(comparison_test.Helper.NE(true, true));
      expect$.Expect.isTrue(comparison_test.Helper.STRICT_EQ(-1, -1));
      expect$.Expect.isTrue(comparison_test.Helper.STRICT_EQ(0, 0));
      expect$.Expect.isTrue(comparison_test.Helper.STRICT_EQ(1, 1));
      expect$.Expect.isFalse(comparison_test.Helper.STRICT_EQ(-1, 0));
      expect$.Expect.isFalse(comparison_test.Helper.STRICT_EQ(-1, 1));
      expect$.Expect.isFalse(comparison_test.Helper.STRICT_EQ(0, 1));
      expect$.Expect.isFalse(comparison_test.Helper.STRICT_NE(-1, -1));
      expect$.Expect.isFalse(comparison_test.Helper.STRICT_NE(0, 0));
      expect$.Expect.isFalse(comparison_test.Helper.STRICT_NE(1, 1));
      expect$.Expect.isTrue(comparison_test.Helper.STRICT_NE(-1, 0));
      expect$.Expect.isTrue(comparison_test.Helper.STRICT_NE(-1, 1));
      expect$.Expect.isTrue(comparison_test.Helper.STRICT_NE(0, 1));
      expect$.Expect.isTrue(comparison_test.Helper.EQ(-1, -1));
      expect$.Expect.isTrue(comparison_test.Helper.EQ(0, 0));
      expect$.Expect.isTrue(comparison_test.Helper.EQ(1, 1));
      expect$.Expect.isFalse(comparison_test.Helper.EQ(-1, 0));
      expect$.Expect.isFalse(comparison_test.Helper.EQ(-1, 1));
      expect$.Expect.isFalse(comparison_test.Helper.EQ(0, 1));
      expect$.Expect.isFalse(comparison_test.Helper.NE(-1, -1));
      expect$.Expect.isFalse(comparison_test.Helper.NE(0, 0));
      expect$.Expect.isFalse(comparison_test.Helper.NE(1, 1));
      expect$.Expect.isTrue(comparison_test.Helper.NE(-1, 0));
      expect$.Expect.isTrue(comparison_test.Helper.NE(-1, 1));
      expect$.Expect.isTrue(comparison_test.Helper.NE(0, 1));
      expect$.Expect.isFalse(comparison_test.Helper.LT(-1, -1));
      expect$.Expect.isFalse(comparison_test.Helper.LT(0, 0));
      expect$.Expect.isFalse(comparison_test.Helper.LT(1, 1));
      expect$.Expect.isTrue(comparison_test.Helper.LT(-1, 0));
      expect$.Expect.isTrue(comparison_test.Helper.LT(-1, 1));
      expect$.Expect.isTrue(comparison_test.Helper.LT(0, 1));
      expect$.Expect.isFalse(comparison_test.Helper.LT(0, -1));
      expect$.Expect.isFalse(comparison_test.Helper.LT(1, -1));
      expect$.Expect.isFalse(comparison_test.Helper.LT(1, 0));
      expect$.Expect.isTrue(comparison_test.Helper.LE(-1, -1));
      expect$.Expect.isTrue(comparison_test.Helper.LE(0, 0));
      expect$.Expect.isTrue(comparison_test.Helper.LE(1, 1));
      expect$.Expect.isTrue(comparison_test.Helper.LE(-1, 0));
      expect$.Expect.isTrue(comparison_test.Helper.LE(-1, 1));
      expect$.Expect.isTrue(comparison_test.Helper.LE(0, 1));
      expect$.Expect.isFalse(comparison_test.Helper.LE(0, -1));
      expect$.Expect.isFalse(comparison_test.Helper.LE(1, -1));
      expect$.Expect.isFalse(comparison_test.Helper.LE(1, 0));
      expect$.Expect.isFalse(comparison_test.Helper.GT(-1, -1));
      expect$.Expect.isFalse(comparison_test.Helper.GT(0, 0));
      expect$.Expect.isFalse(comparison_test.Helper.GT(1, 1));
      expect$.Expect.isFalse(comparison_test.Helper.GT(-1, 0));
      expect$.Expect.isFalse(comparison_test.Helper.GT(-1, 1));
      expect$.Expect.isFalse(comparison_test.Helper.GT(0, 1));
      expect$.Expect.isTrue(comparison_test.Helper.GT(0, -1));
      expect$.Expect.isTrue(comparison_test.Helper.GT(1, -1));
      expect$.Expect.isTrue(comparison_test.Helper.GT(1, 0));
      expect$.Expect.isTrue(comparison_test.Helper.GE(-1, -1));
      expect$.Expect.isTrue(comparison_test.Helper.GE(0, 0));
      expect$.Expect.isTrue(comparison_test.Helper.GE(1, 1));
      expect$.Expect.isFalse(comparison_test.Helper.GE(-1, 0));
      expect$.Expect.isFalse(comparison_test.Helper.GE(-1, 1));
      expect$.Expect.isFalse(comparison_test.Helper.GE(0, 1));
      expect$.Expect.isTrue(comparison_test.Helper.GE(0, -1));
      expect$.Expect.isTrue(comparison_test.Helper.GE(1, -1));
      expect$.Expect.isTrue(comparison_test.Helper.GE(1, 0));
      expect$.Expect.isTrue(comparison_test.Helper.STRICT_EQ(-1.0, -1.0));
      expect$.Expect.isTrue(comparison_test.Helper.STRICT_EQ(0.0, 0.0));
      expect$.Expect.isTrue(comparison_test.Helper.STRICT_EQ(1.0, 1.0));
      expect$.Expect.isFalse(comparison_test.Helper.STRICT_EQ(-1.0, 0.0));
      expect$.Expect.isFalse(comparison_test.Helper.STRICT_EQ(-1.0, 1.0));
      expect$.Expect.isFalse(comparison_test.Helper.STRICT_EQ(0.0, 1.0));
      expect$.Expect.isFalse(comparison_test.Helper.STRICT_NE(-1.0, -1.0));
      expect$.Expect.isFalse(comparison_test.Helper.STRICT_NE(0.0, 0.0));
      expect$.Expect.isFalse(comparison_test.Helper.STRICT_NE(1.0, 1.0));
      expect$.Expect.isTrue(comparison_test.Helper.STRICT_NE(-1.0, 0.0));
      expect$.Expect.isTrue(comparison_test.Helper.STRICT_NE(-1.0, 1.0));
      expect$.Expect.isTrue(comparison_test.Helper.STRICT_NE(0.0, 1.0));
      expect$.Expect.isTrue(comparison_test.Helper.EQ(-1.0, -1.0));
      expect$.Expect.isTrue(comparison_test.Helper.EQ(0.0, 0.0));
      expect$.Expect.isTrue(comparison_test.Helper.EQ(1.0, 1.0));
      expect$.Expect.isFalse(comparison_test.Helper.EQ(-1.0, 0.0));
      expect$.Expect.isFalse(comparison_test.Helper.EQ(-1.0, 1.0));
      expect$.Expect.isFalse(comparison_test.Helper.EQ(0.0, 1.0));
      expect$.Expect.isFalse(comparison_test.Helper.NE(-1.0, -1.0));
      expect$.Expect.isFalse(comparison_test.Helper.NE(0.0, 0.0));
      expect$.Expect.isFalse(comparison_test.Helper.NE(1.0, 1.0));
      expect$.Expect.isTrue(comparison_test.Helper.NE(-1.0, 0.0));
      expect$.Expect.isTrue(comparison_test.Helper.NE(-1.0, 1.0));
      expect$.Expect.isTrue(comparison_test.Helper.NE(0.0, 1.0));
      expect$.Expect.isFalse(comparison_test.Helper.LT(-1.0, -1.0));
      expect$.Expect.isFalse(comparison_test.Helper.LT(0.0, 0.0));
      expect$.Expect.isFalse(comparison_test.Helper.LT(1.0, 1.0));
      expect$.Expect.isTrue(comparison_test.Helper.LT(-1.0, 0.0));
      expect$.Expect.isTrue(comparison_test.Helper.LT(-1.0, 1.0));
      expect$.Expect.isTrue(comparison_test.Helper.LT(0.0, 1.0));
      expect$.Expect.isFalse(comparison_test.Helper.LT(0.0, -1.0));
      expect$.Expect.isFalse(comparison_test.Helper.LT(1.0, -1.0));
      expect$.Expect.isFalse(comparison_test.Helper.LT(1.0, 0.0));
      expect$.Expect.isTrue(comparison_test.Helper.LE(-1.0, -1.0));
      expect$.Expect.isTrue(comparison_test.Helper.LE(0.0, 0.0));
      expect$.Expect.isTrue(comparison_test.Helper.LE(1.0, 1.0));
      expect$.Expect.isTrue(comparison_test.Helper.LE(-1.0, 0.0));
      expect$.Expect.isTrue(comparison_test.Helper.LE(-1.0, 1.0));
      expect$.Expect.isTrue(comparison_test.Helper.LE(0.0, 1.0));
      expect$.Expect.isFalse(comparison_test.Helper.LE(0.0, -1.0));
      expect$.Expect.isFalse(comparison_test.Helper.LE(1.0, -1.0));
      expect$.Expect.isFalse(comparison_test.Helper.LE(1.0, 0.0));
      expect$.Expect.isFalse(comparison_test.Helper.GT(-1.0, -1.0));
      expect$.Expect.isFalse(comparison_test.Helper.GT(0.0, 0.0));
      expect$.Expect.isFalse(comparison_test.Helper.GT(1.0, 1.0));
      expect$.Expect.isFalse(comparison_test.Helper.GT(-1.0, 0.0));
      expect$.Expect.isFalse(comparison_test.Helper.GT(-1.0, 1.0));
      expect$.Expect.isFalse(comparison_test.Helper.GT(0.0, 1.0));
      expect$.Expect.isTrue(comparison_test.Helper.GT(0.0, -1.0));
      expect$.Expect.isTrue(comparison_test.Helper.GT(1.0, -1.0));
      expect$.Expect.isTrue(comparison_test.Helper.GT(1.0, 0.0));
      expect$.Expect.isTrue(comparison_test.Helper.GE(-1.0, -1.0));
      expect$.Expect.isTrue(comparison_test.Helper.GE(0.0, 0.0));
      expect$.Expect.isTrue(comparison_test.Helper.GE(1.0, 1.0));
      expect$.Expect.isFalse(comparison_test.Helper.GE(-1.0, 0.0));
      expect$.Expect.isFalse(comparison_test.Helper.GE(-1.0, 1.0));
      expect$.Expect.isFalse(comparison_test.Helper.GE(0.0, 1.0));
      expect$.Expect.isTrue(comparison_test.Helper.GE(0.0, -1.0));
      expect$.Expect.isTrue(comparison_test.Helper.GE(1.0, -1.0));
      expect$.Expect.isTrue(comparison_test.Helper.GE(1.0, 0.0));
      expect$.Expect.isTrue(comparison_test.Helper.EQ(null, null));
      expect$.Expect.isFalse(comparison_test.Helper.EQ(null, "Str"));
      expect$.Expect.isTrue(comparison_test.Helper.NE(null, 2));
      expect$.Expect.isFalse(comparison_test.Helper.NE(null, null));
      expect$.Expect.isTrue(comparison_test.Helper.STRICT_EQ(null, null));
      expect$.Expect.isFalse(comparison_test.Helper.STRICT_EQ(null, "Str"));
      expect$.Expect.isTrue(comparison_test.Helper.STRICT_NE(null, 2));
      expect$.Expect.isFalse(comparison_test.Helper.STRICT_NE(null, null));
      expect$.Expect.isFalse(comparison_test.Helper.GT(1, 1.2));
      expect$.Expect.isTrue(comparison_test.Helper.GT(3, 1.2));
      expect$.Expect.isTrue(comparison_test.Helper.GT(2.0, 1));
      expect$.Expect.isFalse(comparison_test.Helper.GT(3.1, 4));
      expect$.Expect.isFalse(comparison_test.Helper.GE(1, 1.2));
      expect$.Expect.isTrue(comparison_test.Helper.GE(3, 1.2));
      expect$.Expect.isTrue(comparison_test.Helper.GE(2.0, 1));
      expect$.Expect.isFalse(comparison_test.Helper.GE(3.1, 4));
      expect$.Expect.isTrue(comparison_test.Helper.GE(2.0, 2));
      expect$.Expect.isTrue(comparison_test.Helper.GE(2, 2.0));
      expect$.Expect.isTrue(comparison_test.Helper.LT(1, 1.2));
      expect$.Expect.isFalse(comparison_test.Helper.LT(3, 1.2));
      expect$.Expect.isFalse(comparison_test.Helper.LT(2.0, 1));
      expect$.Expect.isTrue(comparison_test.Helper.LT(3.1, 4));
      expect$.Expect.isTrue(comparison_test.Helper.LE(1, 1.2));
      expect$.Expect.isFalse(comparison_test.Helper.LE(3, 1.2));
      expect$.Expect.isFalse(comparison_test.Helper.LE(2.0, 1));
      expect$.Expect.isTrue(comparison_test.Helper.LE(3.1, 4));
      expect$.Expect.isTrue(comparison_test.Helper.LE(2.0, 2));
      expect$.Expect.isTrue(comparison_test.Helper.LE(2, 2.0));
      expect$.Expect.isTrue(comparison_test.Helper.LE(263882790666245, 263882790666246));
      expect$.Expect.isTrue(comparison_test.Helper.LE(263882790666245, 263882790666245));
      expect$.Expect.isFalse(comparison_test.Helper.LE(263882790666246, 263882790666245));
      expect$.Expect.isTrue(comparison_test.Helper.LE(12, 263882790666245));
      expect$.Expect.isTrue(comparison_test.Helper.LE(12.2, 263882790666245));
      expect$.Expect.isTrue(comparison_test.Helper.EQ(4294967295, 4294967295.0));
      expect$.Expect.isTrue(comparison_test.Helper.EQ(4294967295.0, 4294967295));
      expect$.Expect.isFalse(comparison_test.Helper.EQ(4294967295.0, 42));
      expect$.Expect.isFalse(comparison_test.Helper.EQ(42, 4294967295.0));
      expect$.Expect.isFalse(comparison_test.Helper.EQ(4294967295, 42));
      expect$.Expect.isFalse(comparison_test.Helper.EQ(42, 4294967295));
      expect$.Expect.isTrue(comparison_test.Helper.EQ(1.0, 1));
      expect$.Expect.isTrue(comparison_test.Helper.EQ(1.0, 1));
      expect$.Expect.isTrue(comparison_test.Helper.EQ(1, 1.0));
      expect$.Expect.isTrue(comparison_test.Helper.EQ(1, 1.0));
      expect$.Expect.isTrue(comparison_test.Helper.EQ(1.1, 1.1));
      expect$.Expect.isTrue(comparison_test.Helper.EQ(1.1, 1.1));
      expect$.Expect.isTrue(comparison_test.Helper.EQ(1.1, 1.1));
      expect$.Expect.isFalse(comparison_test.Helper.GT(1, 1.2));
      expect$.Expect.isTrue(comparison_test.Helper.GT(1.2, 1));
      expect$.Expect.isTrue(comparison_test.Helper.GT(1.2, 1.1));
      expect$.Expect.isTrue(comparison_test.Helper.GT(1.2, 1.1));
      expect$.Expect.isTrue(comparison_test.Helper.GT(1.2, 1.1));
      expect$.Expect.isTrue(comparison_test.Helper.LT(1, 1.2));
      expect$.Expect.isFalse(comparison_test.Helper.LT(1.2, 1));
      expect$.Expect.isFalse(comparison_test.Helper.LT(1.2, 1.1));
      expect$.Expect.isFalse(comparison_test.Helper.LT(1.2, 1.1));
      expect$.Expect.isFalse(comparison_test.Helper.LT(1.2, 1.1));
      expect$.Expect.isFalse(comparison_test.Helper.GE(1.1, 1.2));
      expect$.Expect.isFalse(comparison_test.Helper.GE(1.1, 1.2));
      expect$.Expect.isTrue(comparison_test.Helper.GE(1.2, 1.2));
      expect$.Expect.isTrue(comparison_test.Helper.GE(1.2, 1.2));
      expect$.Expect.isFalse(comparison_test.Helper.EQ(1, "eeny"));
      expect$.Expect.isFalse(comparison_test.Helper.EQ("meeny", 1));
      expect$.Expect.isFalse(comparison_test.Helper.EQ(1.1, "miny"));
      expect$.Expect.isFalse(comparison_test.Helper.EQ("moe", 1.1));
      expect$.Expect.isFalse(comparison_test.Helper.EQ(1.1, "catch"));
      expect$.Expect.isFalse(comparison_test.Helper.EQ("the", 1.1));
      expect$.Expect.isFalse(comparison_test.Helper.EQ(1, null));
      expect$.Expect.isFalse(comparison_test.Helper.EQ(null, 1));
      expect$.Expect.isFalse(comparison_test.Helper.EQ(1.1, null));
      expect$.Expect.isFalse(comparison_test.Helper.EQ(null, 1.1));
      expect$.Expect.isFalse(comparison_test.Helper.EQ(1.1, null));
      expect$.Expect.isFalse(comparison_test.Helper.EQ(null, 1.1));
    }
  };
  dart.setSignature(comparison_test.ComparisonTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  comparison_test.main = function() {
    comparison_test.ComparisonTest.testMain();
  };
  dart.fn(comparison_test.main, VoidTodynamic());
  // Exports:
  exports.comparison_test = comparison_test;
});
