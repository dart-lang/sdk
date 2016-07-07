dart_library.library('corelib/bit_twiddling_bigint_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__bit_twiddling_bigint_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const bit_twiddling_bigint_test = Object.create(null);
  let intAnddynamicTodynamic = () => (intAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.int, dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicAnddynamicAnddynamicTodynamic = () => (dynamicAnddynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic])))();
  bit_twiddling_bigint_test.testBitLength = function() {
    function check(i, width) {
      expect$.Expect.equals(width, i[dartx.bitLength], dart.str`${i}.bitLength ==  ${width}`);
      expect$.Expect.equals(width, (-dart.notNull(i) - 1)[dartx.bitLength], dart.str`(~${i}).bitLength == ${width}`);
    }
    dart.fn(check, intAnddynamicTodynamic());
    check(72057594037927935, 56);
    check(18446744073709551615, 64);
    check(4722366482869645213695, 72);
    check(4722366482869645213696, 73);
    check(4722366482869645213697, 73);
    check(5708990770823839524233143877797980545530986494, 152);
    check(5708990770823839524233143877797980545530986495, 152);
    check(5708990770823839524233143877797980545530986496, 153);
    check(5708990770823839524233143877797980545530986497, 153);
  };
  dart.fn(bit_twiddling_bigint_test.testBitLength, VoidTodynamic());
  bit_twiddling_bigint_test.testToUnsigned = function() {
    function checkU(src, width, expected) {
      expect$.Expect.equals(expected, dart.dsend(src, 'toUnsigned', width));
    }
    dart.fn(checkU, dynamicAnddynamicAnddynamicTodynamic());
    checkU(1208925891672223212634113, 2, 1);
    checkU(1208925963729817250562049, 60, 144115188075855873);
    checkU(1208925963729817250562049, 59, 144115188075855873);
    checkU(1208925963729817250562049, 58, 144115188075855873);
    checkU(1208925963729817250562049, 57, 1);
  };
  dart.fn(bit_twiddling_bigint_test.testToUnsigned, VoidTodynamic());
  bit_twiddling_bigint_test.testToSigned = function() {
    function checkS(src, width, expected) {
      expect$.Expect.equals(expected, dart.dsend(src, 'toSigned', width), dart.str`${src}.toSigned(${width}) == ${expected}`);
    }
    dart.fn(checkS, dynamicAnddynamicAnddynamicTodynamic());
    checkS(1208925891672223212634113, 2, 1);
    checkS(1208925963729817250562049, 60, 144115188075855873);
    checkS(1208925963729817250562049, 59, 144115188075855873);
    checkS(1208925963729817250562049, 58, -144115188075855872 + 1);
    checkS(1208925963729817250562049, 57, 1);
  };
  dart.fn(bit_twiddling_bigint_test.testToSigned, VoidTodynamic());
  bit_twiddling_bigint_test.main = function() {
    bit_twiddling_bigint_test.testBitLength();
    bit_twiddling_bigint_test.testToUnsigned();
    bit_twiddling_bigint_test.testToSigned();
  };
  dart.fn(bit_twiddling_bigint_test.main, VoidTodynamic());
  // Exports:
  exports.bit_twiddling_bigint_test = bit_twiddling_bigint_test;
});
