dart_library.library('corelib/bit_twiddling_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__bit_twiddling_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const bit_twiddling_test = Object.create(null);
  let VoidTobool = () => (VoidTobool = dart.constFn(dart.definiteFunctionType(core.bool, [])))();
  let intAnddynamicTodynamic = () => (intAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.int, dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicAnddynamicAnddynamicTodynamic = () => (dynamicAnddynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic])))();
  bit_twiddling_test.haveBigints = function() {
    return 100000000000000000000 + 1 != 100000000000000000000;
  };
  dart.fn(bit_twiddling_test.haveBigints, VoidTobool());
  bit_twiddling_test.testBitLength = function() {
    function check(i, width) {
      expect$.Expect.equals(width, i[dartx.bitLength], dart.str`${i}.bitLength ==  ${width}`);
      expect$.Expect.equals(width, (-dart.notNull(i) - 1)[dartx.bitLength], dart.str`(~${i}).bitLength == ${width}`);
    }
    dart.fn(check, intAnddynamicTodynamic());
    check(0, 0);
    check(1, 1);
    check(2, 2);
    check(3, 2);
    check(4, 3);
    check(5, 3);
    check(6, 3);
    check(7, 3);
    check(8, 4);
    check(127, 7);
    check(128, 8);
    check(129, 8);
    check(2147483646, 31);
    check(2147483647, 31);
    check(2147483648, 32);
    check(2147483649, 32);
    check(4294967295, 32);
    check(4294967296, 33);
    check(1099511627775, 40);
    check(17592186044415, 44);
    check(281474976710655, 48);
    check(281474976710656, 49);
    check(281474976710657, 49);
    check(562949953421311, 49);
    check(562949953421312, 50);
    check(562949953421313, 50);
    if (dart.test(bit_twiddling_test.haveBigints())) {
      check(72057594037927935, 56);
      check(18446744073709551615, 64);
      check(4722366482869645213695, 72);
      check(4722366482869645213696, 73);
      check(4722366482869645213697, 73);
      check(5708990770823839524233143877797980545530986494, 152);
      check(5708990770823839524233143877797980545530986495, 152);
      check(5708990770823839524233143877797980545530986496, 153);
      check(5708990770823839524233143877797980545530986497, 153);
    }
  };
  dart.fn(bit_twiddling_test.testBitLength, VoidTodynamic());
  bit_twiddling_test.testToUnsigned = function() {
    function checkU(src, width, expected) {
      expect$.Expect.equals(expected, dart.dsend(src, 'toUnsigned', width));
    }
    dart.fn(checkU, dynamicAnddynamicAnddynamicTodynamic());
    checkU(1, 8, 1);
    checkU(255, 8, 255);
    checkU(65535, 8, 255);
    checkU(-1, 8, 255);
    checkU(4294967295, 32, 4294967295);
    checkU(2147483647, 30, 1073741823);
    checkU(2147483647, 31, 2147483647);
    checkU(2147483647, 32, 2147483647);
    checkU(2147483648, 30, 0);
    checkU(2147483648, 31, 0);
    checkU(2147483648, 32, 2147483648);
    checkU(4294967295, 30, 1073741823);
    checkU(4294967295, 31, 2147483647);
    checkU(4294967295, 32, 4294967295);
    checkU(4294967296, 30, 0);
    checkU(4294967296, 31, 0);
    checkU(4294967296, 32, 0);
    checkU(8589934591, 30, 1073741823);
    checkU(8589934591, 31, 2147483647);
    checkU(8589934591, 32, 4294967295);
    checkU(-1, 0, 0);
    checkU(0, 0, 0);
    checkU(1, 0, 0);
    checkU(2, 0, 0);
    checkU(3, 0, 0);
    checkU(-1, 1, 1);
    checkU(0, 1, 0);
    checkU(1, 1, 1);
    checkU(2, 1, 0);
    checkU(3, 1, 1);
    checkU(4, 1, 0);
    checkU(-1, 2, 3);
    checkU(0, 2, 0);
    checkU(1, 2, 1);
    checkU(2, 2, 2);
    checkU(3, 2, 3);
    checkU(4, 2, 0);
    checkU(-1, 3, 7);
    checkU(0, 3, 0);
    checkU(1, 3, 1);
    checkU(2, 3, 2);
    checkU(3, 3, 3);
    checkU(4, 3, 4);
  };
  dart.fn(bit_twiddling_test.testToUnsigned, VoidTodynamic());
  bit_twiddling_test.testToSigned = function() {
    function checkS(src, width, expected) {
      expect$.Expect.equals(expected, dart.dsend(src, 'toSigned', width), dart.str`${src}.toSigned(${width}) == ${expected}`);
    }
    dart.fn(checkS, dynamicAnddynamicAnddynamicTodynamic());
    checkS(1, 8, 1);
    checkS(255, 8, -1);
    checkS(65535, 8, -1);
    checkS(-1, 8, -1);
    checkS(128, 8, -128);
    checkS(4294967295, 32, -1);
    checkS(2147483647, 30, -1);
    checkS(2147483647, 31, -1);
    checkS(2147483647, 32, 2147483647);
    checkS(2147483648, 30, 0);
    checkS(2147483648, 31, 0);
    checkS(2147483648, 32, -2147483648);
    checkS(4294967295, 30, -1);
    checkS(4294967295, 31, -1);
    checkS(4294967295, 32, -1);
    checkS(4294967296, 30, 0);
    checkS(4294967296, 31, 0);
    checkS(4294967296, 32, 0);
    checkS(8589934591, 30, -1);
    checkS(8589934591, 31, -1);
    checkS(8589934591, 32, -1);
    checkS(-1, 1, -1);
    checkS(0, 1, 0);
    checkS(1, 1, -1);
    checkS(2, 1, 0);
    checkS(3, 1, -1);
    checkS(4, 1, 0);
    checkS(-1, 2, -1);
    checkS(0, 2, 0);
    checkS(1, 2, 1);
    checkS(2, 2, -2);
    checkS(3, 2, -1);
    checkS(4, 2, 0);
    checkS(-1, 3, -1);
    checkS(0, 3, 0);
    checkS(1, 3, 1);
    checkS(2, 3, 2);
    checkS(3, 3, 3);
    checkS(4, 3, -4);
  };
  dart.fn(bit_twiddling_test.testToSigned, VoidTodynamic());
  bit_twiddling_test.main = function() {
    bit_twiddling_test.testBitLength();
    bit_twiddling_test.testToUnsigned();
    bit_twiddling_test.testToSigned();
  };
  dart.fn(bit_twiddling_test.main, VoidTodynamic());
  // Exports:
  exports.bit_twiddling_test = bit_twiddling_test;
});
