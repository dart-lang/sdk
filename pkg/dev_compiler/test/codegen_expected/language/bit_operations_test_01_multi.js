dart_library.library('language/bit_operations_test_01_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__bit_operations_test_01_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const bit_operations_test_01_multi = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicAnddynamicTobool = () => (dynamicAnddynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic, dart.dynamic])))();
  let intAndintToint = () => (intAndintToint = dart.constFn(dart.definiteFunctionType(core.int, [core.int, core.int])))();
  let intAndintAndint__Tovoid = () => (intAndintAndint__Tovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.int, core.int, core.int, core.int])))();
  bit_operations_test_01_multi.main = function() {
    for (let i = 0; i < 4; i++) {
      bit_operations_test_01_multi.test();
    }
  };
  dart.fn(bit_operations_test_01_multi.main, VoidTovoid());
  bit_operations_test_01_multi.test = function() {
    expect$.Expect.equals(3, 3 & 7);
    expect$.Expect.equals(7, 3 | 7);
    expect$.Expect.equals(4, 3 ^ 7);
    expect$.Expect.equals(25, 100 >> 2);
    expect$.Expect.equals(400, 100 << 2);
    expect$.Expect.equals(-25, (-100)[dartx['>>']](2));
    expect$.Expect.equals(-101, ~100 >>> 0);
    expect$.Expect.equals(18446744073709551616, (1)[dartx['<<']](64));
    expect$.Expect.equals(-18446744073709551616, (-1)[dartx['<<']](64));
    expect$.Expect.equals(1073741824, 67108864 << 4);
    expect$.Expect.equals(4611686018427387904, 288230376151711744 << 4 >>> 0);
    expect$.Expect.equals(0, ~-1 >>> 0);
    expect$.Expect.equals(-1, ~0 >>> 0);
    expect$.Expect.equals(0, (1)[dartx['>>']](160));
    expect$.Expect.equals(-1, (-1)[dartx['>>']](160));
    expect$.Expect.equals(295147905179352825857, (295147905179352825857 & 295147922835963379713) >>> 0);
    expect$.Expect.equals(1, 1 & 295147922835963379713);
    expect$.Expect.equals(1, 295147922835963379713 & 1);
    expect$.Expect.equals(295147922835963379713, (295147905179352825857 | 295147922835963379713) >>> 0);
    expect$.Expect.equals(295147922835963379729, (17 | 295147922835963379713) >>> 0);
    expect$.Expect.equals(295147922835963379729, (295147922835963379713 | 17) >>> 0);
    expect$.Expect.equals(70836578106955247124480, (4428299441600861306881 ^ 75262715820734970593281) >>> 0);
    expect$.Expect.equals(49, (4428299441600861306881 ^ 4428299441600861306928) >>> 0);
    expect$.Expect.equals(4428299441600861306929, (4428299441600861306881 ^ 48) >>> 0);
    expect$.Expect.equals(4428299441600861306929, (48 ^ 4428299441600861306881) >>> 0);
    expect$.Expect.equals(4427218577690292387855, 70835497243044678205687 >>> 4);
    expect$.Expect.equals(15, (64424509440)[dartx['>>']](32));
    expect$.Expect.equals(1030792151040, 16492674416655 >>> 4);
    expect$.Expect.equals(70835497243044678205680, 4427218577690292387855 << 4 >>> 0);
    expect$.Expect.equals(64424509440, (15)[dartx['<<']](32));
    bit_operations_test_01_multi.testNegativeValueShifts();
    bit_operations_test_01_multi.testPositiveValueShifts();
    bit_operations_test_01_multi.testNoMaskingOfShiftCount();
    bit_operations_test_01_multi.testNegativeCountShifts();
    for (let i = 0; i < 20; i++) {
      bit_operations_test_01_multi.testCornerCasesRightShifts();
      bit_operations_test_01_multi.testRightShift64Bit();
      bit_operations_test_01_multi.testLeftShift64Bit();
      bit_operations_test_01_multi.testLeftShift64BitWithOverflow1();
      bit_operations_test_01_multi.testLeftShift64BitWithOverflow2();
      bit_operations_test_01_multi.testLeftShift64BitWithOverflow3();
    }
    bit_operations_test_01_multi.testPrecedence(4, 5, 3, 1);
    bit_operations_test_01_multi.testPrecedence(3, 4, 5, 9);
    bit_operations_test_01_multi.testPrecedence(23665, 27538, 30292, 32040);
  };
  dart.fn(bit_operations_test_01_multi.test, VoidTovoid());
  bit_operations_test_01_multi.testCornerCasesRightShifts = function() {
    let v32 = 4278190080;
    let v64 = 18374686479671623680;
    expect$.Expect.equals(3, v32[dartx['>>']](30));
    expect$.Expect.equals(1, v32[dartx['>>']](31));
    expect$.Expect.equals(0, v32[dartx['>>']](32));
    expect$.Expect.equals(3, v64[dartx['>>']](62));
    expect$.Expect.equals(1, v64[dartx['>>']](63));
    expect$.Expect.equals(0, v64[dartx['>>']](64));
  };
  dart.fn(bit_operations_test_01_multi.testCornerCasesRightShifts, VoidTovoid());
  bit_operations_test_01_multi.testRightShift64Bit = function() {
    let t = 8589934591;
    expect$.Expect.equals(4294967295, t[dartx['>>']](1));
  };
  dart.fn(bit_operations_test_01_multi.testRightShift64Bit, VoidTovoid());
  bit_operations_test_01_multi.testLeftShift64Bit = function() {
    let t = 4294967295;
    expect$.Expect.equals(4294967295, t << 0 >>> 0);
    expect$.Expect.equals(8589934590, t << 1 >>> 0);
    expect$.Expect.equals(9223372034707292160, t << 31 >>> 0);
    expect$.Expect.equals(18446744073709551616, 2 * (t + 1) << 31 >>> 0);
    expect$.Expect.equals(9223372036854775808, t + 1 << 31 >>> 0);
  };
  dart.fn(bit_operations_test_01_multi.testLeftShift64Bit, VoidTovoid());
  bit_operations_test_01_multi.testLeftShift64BitWithOverflow1 = function() {
    let t = 4294967295;
  };
  dart.fn(bit_operations_test_01_multi.testLeftShift64BitWithOverflow1, VoidTovoid());
  bit_operations_test_01_multi.testLeftShift64BitWithOverflow2 = function() {
    let t = 4294967295;
  };
  dart.fn(bit_operations_test_01_multi.testLeftShift64BitWithOverflow2, VoidTovoid());
  bit_operations_test_01_multi.testLeftShift64BitWithOverflow3 = function() {
    let t = 4294967295;
    expect$.Expect.equals(9223372036854775808, t + 1 << 31 >>> 0);
  };
  dart.fn(bit_operations_test_01_multi.testLeftShift64BitWithOverflow3, VoidTovoid());
  bit_operations_test_01_multi.testNegativeCountShifts = function() {
    function throwOnLeft(a, b) {
      try {
        let x = dart.dsend(a, '<<', b);
        return false;
      } catch (e) {
        return true;
      }

    }
    dart.fn(throwOnLeft, dynamicAnddynamicTobool());
    function throwOnRight(a, b) {
      try {
        let x = dart.dsend(a, '>>', b);
        return false;
      } catch (e) {
        return true;
      }

    }
    dart.fn(throwOnRight, dynamicAnddynamicTobool());
    expect$.Expect.isTrue(throwOnLeft(12, -3));
    expect$.Expect.isTrue(throwOnRight(12, -3));
    for (let i = 0; i < 20; i++) {
      expect$.Expect.isFalse(throwOnLeft(12, 3));
      expect$.Expect.isFalse(throwOnRight(12, 3));
    }
  };
  dart.fn(bit_operations_test_01_multi.testNegativeCountShifts, VoidTovoid());
  bit_operations_test_01_multi.testNegativeValueShifts = function() {
    for (let value = 0; value > -100; value--) {
      for (let i = 0; i < 300; i++) {
        let b = value[dartx['<<']](i)[dartx['>>']](i);
        expect$.Expect.equals(value, b);
      }
    }
  };
  dart.fn(bit_operations_test_01_multi.testNegativeValueShifts, VoidTovoid());
  bit_operations_test_01_multi.testPositiveValueShifts = function() {
    for (let value = 0; value < 100; value++) {
      for (let i = 0; i < 300; i++) {
        let b = value[dartx['<<']](i)[dartx['>>']](i);
        expect$.Expect.equals(value, b);
      }
    }
  };
  dart.fn(bit_operations_test_01_multi.testPositiveValueShifts, VoidTovoid());
  bit_operations_test_01_multi.testNoMaskingOfShiftCount = function() {
    expect$.Expect.equals(0, (0)[dartx['>>']](256));
    expect$.Expect.equals(0, (1)[dartx['>>']](256));
    expect$.Expect.equals(0, (2)[dartx['>>']](256));
    expect$.Expect.equals(0, bit_operations_test_01_multi.shiftRight(0, 256));
    expect$.Expect.equals(0, bit_operations_test_01_multi.shiftRight(1, 256));
    expect$.Expect.equals(0, bit_operations_test_01_multi.shiftRight(2, 256));
    for (let shift = 1; shift <= 256; shift++) {
      expect$.Expect.equals(0, bit_operations_test_01_multi.shiftRight(1, shift));
      expect$.Expect.equals(-1, bit_operations_test_01_multi.shiftRight(-1, shift));
      expect$.Expect.equals(true, dart.notNull(bit_operations_test_01_multi.shiftLeft(1, shift)) > dart.notNull(bit_operations_test_01_multi.shiftLeft(1, shift - 1)));
    }
  };
  dart.fn(bit_operations_test_01_multi.testNoMaskingOfShiftCount, VoidTovoid());
  bit_operations_test_01_multi.shiftLeft = function(a, b) {
    return a[dartx['<<']](b);
  };
  dart.fn(bit_operations_test_01_multi.shiftLeft, intAndintToint());
  bit_operations_test_01_multi.shiftRight = function(a, b) {
    return a[dartx['>>']](b);
  };
  dart.fn(bit_operations_test_01_multi.shiftRight, intAndintToint());
  bit_operations_test_01_multi.testPrecedence = function(a, b, c, d) {
    let result = (dart.notNull(a) & dart.notNull(b) ^ dart.notNull(c) | dart.notNull(d) & dart.notNull(b) ^ dart.notNull(c)) >>> 0;
    expect$.Expect.equals((dart.notNull(a) & dart.notNull(b) ^ dart.notNull(c) | dart.notNull(d) & dart.notNull(b) ^ dart.notNull(c)) >>> 0, result);
    expect$.Expect.notEquals((dart.notNull(a) & (dart.notNull(b) ^ dart.notNull(c)) | dart.notNull(d) & (dart.notNull(b) ^ dart.notNull(c))) >>> 0, result);
    expect$.Expect.notEquals((dart.notNull(a) & dart.notNull(b) ^ (dart.notNull(c) | dart.notNull(d) & dart.notNull(b)) ^ dart.notNull(c)) >>> 0, result);
    expect$.Expect.notEquals((dart.notNull(a) & dart.notNull(b) ^ (dart.notNull(c) | dart.notNull(d)) & dart.notNull(b) ^ dart.notNull(c)) >>> 0, result);
    expect$.Expect.notEquals((dart.notNull(a) & (dart.notNull(b) ^ (dart.notNull(c) | dart.notNull(d))) & (dart.notNull(b) ^ dart.notNull(c))) >>> 0, result);
    expect$.Expect.notEquals((dart.notNull(a) & (dart.notNull(b) ^ dart.notNull(c) | dart.notNull(d)) & (dart.notNull(b) ^ dart.notNull(c))) >>> 0, result);
    expect$.Expect.equals((dart.notNull(a) & dart.notNull(b)) >>> 0 < (dart.notNull(c) & dart.notNull(d)) >>> 0, (dart.notNull(a) & dart.notNull(b)) >>> 0 < (dart.notNull(c) & dart.notNull(d)) >>> 0);
    expect$.Expect.equals((dart.notNull(a) & b[dartx['<<']](c) ^ dart.notNull(d)) >>> 0, (dart.notNull(a) & b[dartx['<<']](c) ^ dart.notNull(d)) >>> 0);
    expect$.Expect.notEquals(((dart.notNull(a) & dart.notNull(b)) >>> 0)[dartx['<<']]((dart.notNull(c) ^ dart.notNull(d)) >>> 0), (dart.notNull(a) & b[dartx['<<']](c) ^ dart.notNull(d)) >>> 0);
  };
  dart.fn(bit_operations_test_01_multi.testPrecedence, intAndintAndint__Tovoid());
  // Exports:
  exports.bit_operations_test_01_multi = bit_operations_test_01_multi;
});
