dart_library.library('corelib/integer_to_radix_string_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__integer_to_radix_string_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const integer_to_radix_string_test = Object.create(null);
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  integer_to_radix_string_test.main = function() {
    let expected = JSArrayOfString().of(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z']);
    for (let radix = 2; radix <= 36; radix++) {
      for (let i = 0; i < radix; i++) {
        expect$.Expect.equals(expected[dartx.get](i), i[dartx.toRadixString](radix));
      }
    }
    let illegalRadices = JSArrayOfint().of([-1, 0, 1, 37]);
    for (let radix of illegalRadices) {
      try {
        (42)[dartx.toRadixString](radix);
        expect$.Expect.fail("Exception expected");
      } catch (e) {
        if (core.ArgumentError.is(e)) {
        } else
          throw e;
      }

    }
    let bignums = JSArrayOfint().of([2147483648, 4294967296, 4503599627370496, 4503599627370497, 9007199254740992, 9007199254740994, 1152921504606846976, 1152921504606847232, 2305843009213693952, 2305843009213694464, 9223372036854775808, 9223372036854777856, 18446744073709551616, 18446744073709555712, 295147905179352891392, 4722366482869646262272, 75557863725914340196352, 1208925819614629443141632, 19342813113834071090266112, 309485009821345137444257792]);
    for (let bignum of bignums) {
      for (let radix = 2; radix <= 36; radix++) {
        let digits = bignum[dartx.toRadixString](radix);
        let result = core.int.parse(digits, {radix: radix});
        expect$.Expect.equals(bignum, result, dart.str`${bignum[dartx.toRadixString](16)} -> ${digits}/${radix}`);
      }
    }
  };
  dart.fn(integer_to_radix_string_test.main, VoidTodynamic());
  // Exports:
  exports.integer_to_radix_string_test = integer_to_radix_string_test;
});
