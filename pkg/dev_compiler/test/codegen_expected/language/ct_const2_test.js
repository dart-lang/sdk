dart_library.library('language/ct_const2_test', null, /* Imports */[
  'dart_sdk'
], function load__ct_const2_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const ct_const2_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  ct_const2_test.b = true;
  ct_const2_test.s = "apple";
  ct_const2_test.i = 1;
  ct_const2_test.d = 3.3;
  ct_const2_test.h = 15;
  ct_const2_test.n = null;
  ct_const2_test.aList = dart.constList([1, 2, 3], core.int);
  ct_const2_test.aMap = dart.const(dart.map({"1": "one", "2": "banana"}, core.String, core.String));
  ct_const2_test.INT_LIT = 5;
  ct_const2_test.INT_LIT_REF = ct_const2_test.INT_LIT;
  ct_const2_test.DOUBLE_LIT = 1.5;
  ct_const2_test.BOOL_LIT = true;
  ct_const2_test.STRING_LIT = "Hello";
  ct_const2_test.BOP1_0 = ct_const2_test.INT_LIT + 1;
  ct_const2_test.BOP1_1 = 1 + ct_const2_test.INT_LIT;
  ct_const2_test.BOP1_2 = ct_const2_test.INT_LIT - 1;
  ct_const2_test.BOP1_3 = 1 - ct_const2_test.INT_LIT;
  ct_const2_test.BOP1_4 = ct_const2_test.INT_LIT * 1;
  ct_const2_test.BOP1_5 = 1 * ct_const2_test.INT_LIT;
  ct_const2_test.BOP1_6 = ct_const2_test.INT_LIT / 1;
  ct_const2_test.BOP1_7 = 1 / ct_const2_test.INT_LIT;
  ct_const2_test.BOP2_0 = ct_const2_test.DOUBLE_LIT + 1.5;
  ct_const2_test.BOP2_1 = 1.5 + ct_const2_test.DOUBLE_LIT;
  ct_const2_test.BOP2_2 = ct_const2_test.DOUBLE_LIT - 1.5;
  ct_const2_test.BOP2_3 = 1.5 - ct_const2_test.DOUBLE_LIT;
  ct_const2_test.BOP2_4 = ct_const2_test.DOUBLE_LIT * 1.5;
  ct_const2_test.BOP2_5 = 1.5 * ct_const2_test.DOUBLE_LIT;
  ct_const2_test.BOP2_6 = ct_const2_test.DOUBLE_LIT / 1.5;
  ct_const2_test.BOP2_7 = 1.5 / ct_const2_test.DOUBLE_LIT;
  ct_const2_test.BOP3_0 = 2 < ct_const2_test.INT_LIT;
  ct_const2_test.BOP3_1 = ct_const2_test.INT_LIT < 2;
  ct_const2_test.BOP3_2 = 2 > ct_const2_test.INT_LIT;
  ct_const2_test.BOP3_3 = ct_const2_test.INT_LIT > 2;
  ct_const2_test.BOP3_4 = 2 < ct_const2_test.DOUBLE_LIT;
  ct_const2_test.BOP3_5 = ct_const2_test.DOUBLE_LIT < 2;
  ct_const2_test.BOP3_6 = 2 > ct_const2_test.DOUBLE_LIT;
  ct_const2_test.BOP3_7 = ct_const2_test.DOUBLE_LIT > 2;
  ct_const2_test.BOP3_8 = 2 <= ct_const2_test.INT_LIT;
  ct_const2_test.BOP3_9 = ct_const2_test.INT_LIT <= 2;
  ct_const2_test.BOP3_10 = 2 >= ct_const2_test.INT_LIT;
  ct_const2_test.BOP3_11 = ct_const2_test.INT_LIT >= 2;
  ct_const2_test.BOP3_12 = 2.0 <= ct_const2_test.DOUBLE_LIT;
  ct_const2_test.BOP3_13 = ct_const2_test.DOUBLE_LIT <= 2.0;
  ct_const2_test.BOP3_14 = 2.0 >= ct_const2_test.DOUBLE_LIT;
  ct_const2_test.BOP3_15 = ct_const2_test.DOUBLE_LIT >= 2;
  ct_const2_test.BOP4_0 = (5)[dartx['%']](ct_const2_test.INT_LIT);
  ct_const2_test.BOP4_1 = ct_const2_test.INT_LIT[dartx['%']](5);
  ct_const2_test.BOP4_2 = 5.0[dartx['%']](ct_const2_test.DOUBLE_LIT);
  ct_const2_test.BOP4_3 = ct_const2_test.DOUBLE_LIT[dartx['%']](5.0);
  ct_const2_test.BOP5_0 = 128 & 4;
  ct_const2_test.BOP5_1 = 128 | 4;
  ct_const2_test.BOP5_2 = 128 << 4;
  ct_const2_test.BOP5_3 = 128 >> 4;
  ct_const2_test.BOP5_4 = (128 / 4)[dartx.truncate]();
  ct_const2_test.BOP5_5 = 128 ^ 4;
  ct_const2_test.BOP6 = ct_const2_test.BOOL_LIT && true;
  ct_const2_test.BOP7 = false || ct_const2_test.BOOL_LIT;
  ct_const2_test.BOP8 = ct_const2_test.STRING_LIT == "World!";
  ct_const2_test.BOP9 = "Hello" != ct_const2_test.STRING_LIT;
  ct_const2_test.BOP10 = ct_const2_test.INT_LIT == ct_const2_test.INT_LIT_REF;
  ct_const2_test.BOP11 = ct_const2_test.BOOL_LIT != true;
  ct_const2_test.BOP20 = 1 * ct_const2_test.INT_LIT / 3 + ct_const2_test.INT_LIT + 9;
  ct_const2_test.BOP30 = 1 > 2;
  ct_const2_test.BOP31 = 1 * 2 + 3;
  ct_const2_test.BOP32 = 3 + 1 * 2;
  ct_const2_test.UOP1_0 = !ct_const2_test.BOOL_LIT;
  ct_const2_test.UOP1_1 = ct_const2_test.BOOL_LIT || !true;
  ct_const2_test.UOP1_2 = !ct_const2_test.BOOL_LIT || true;
  ct_const2_test.UOP1_3 = !(ct_const2_test.BOOL_LIT && true);
  ct_const2_test.UOP2_0 = ~240 >>> 0;
  ct_const2_test.UOP2_1 = ~ct_const2_test.INT_LIT >>> 0;
  ct_const2_test.UOP2_2 = ~ct_const2_test.INT_LIT & 123;
  ct_const2_test.UOP2_3 = ~(ct_const2_test.INT_LIT | 255) >>> 0;
  ct_const2_test.UOP3_0 = -240;
  ct_const2_test.UOP3_1 = -ct_const2_test.INT_LIT;
  ct_const2_test.UOP3_2 = -ct_const2_test.INT_LIT + 123;
  ct_const2_test.UOP3_3 = -(ct_const2_test.INT_LIT * 255);
  ct_const2_test.UOP3_4 = -240;
  ct_const2_test.UOP3_5 = -ct_const2_test.DOUBLE_LIT;
  ct_const2_test.UOP3_6 = -ct_const2_test.DOUBLE_LIT + 123;
  ct_const2_test.UOP3_7 = -(ct_const2_test.DOUBLE_LIT * 255);
  ct_const2_test.A = class A extends core.Object {
    new() {
    }
  };
  dart.setSignature(ct_const2_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(ct_const2_test.A, [])})
  });
  dart.defineLazy(ct_const2_test.A, {
    get a() {
      return dart.const(new ct_const2_test.A());
    }
  });
  ct_const2_test.main = function() {
  };
  dart.fn(ct_const2_test.main, VoidTodynamic());
  // Exports:
  exports.ct_const2_test = ct_const2_test;
});
