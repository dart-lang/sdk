dart_library.library('corelib/integer_to_string_test_01_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__integer_to_string_test_01_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const integer_to_string_test_01_multi = Object.create(null);
  let intAndStringTodynamic = () => (intAndStringTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.int, core.String])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  integer_to_string_test_01_multi.main = function() {
    function test(value, expect) {
      expect$.Expect.equals(expect, dart.toString(value));
      expect$.Expect.equals(expect, dart.str`${value}`);
      expect$.Expect.equals(expect, (() => {
        let _ = new core.StringBuffer();
        _.write(value);
        return _;
      })().toString());
      if (value == 0) return;
      expect = dart.str`-${expect}`;
      value = -dart.notNull(value);
      expect$.Expect.equals(expect, dart.toString(value));
      expect$.Expect.equals(expect, dart.str`${value}`);
      expect$.Expect.equals(expect, (() => {
        let _ = new core.StringBuffer();
        _.write(value);
        return _;
      })().toString());
    }
    dart.fn(test, intAndStringTodynamic());
    test(0, "0");
    test(1, "1");
    test(2, "2");
    test(5, "5");
    test(1073741823, "1073741823");
    test(1073741824, "1073741824");
    test(1073741825, "1073741825");
    test(2147483647, "2147483647");
    test(2147483648, "2147483648");
    test(2147483649, "2147483649");
    test(4294967295, "4294967295");
    test(4294967296, "4294967296");
    test(4294967297, "4294967297");
    test(2251799813685247, "2251799813685247");
    test(2251799813685248, "2251799813685248");
    test(2251799813685249, "2251799813685249");
    test(4503599627370495, "4503599627370495");
    test(4503599627370496, "4503599627370496");
    test(4503599627370497, "4503599627370497");
    test(9007199254740991, "9007199254740991");
    test(9007199254740992, "9007199254740992");
    test(9007199254740993, "9007199254740993");
    test(4611686018427387903, "4611686018427387903");
    test(4611686018427387904, "4611686018427387904");
    test(4611686018427387905, "4611686018427387905");
    test(9223372036854775807, "9223372036854775807");
    test(9223372036854775808, "9223372036854775808");
    test(9223372036854775809, "9223372036854775809");
    test(18446744073709551615, "18446744073709551615");
    test(18446744073709551616, "18446744073709551616");
    test(18446744073709551617, "18446744073709551617");
    test(123456789012345678901234567890, "123456789012345678901234567890");
    let number = 10;
    for (let i = 1; i < 15; i++) {
      test(number - 1, "9"[dartx['*']](i));
      test(number, "1" + "0"[dartx['*']](i));
      test(number + 1, "1" + "0"[dartx['*']](i - 1) + "1");
      number = number * 10;
    }
    for (let i = 15; i < 22; i++) {
      test(number - 1, "9"[dartx['*']](i));
      test(number, "1" + "0"[dartx['*']](i));
      test(number + 1, "1" + "0"[dartx['*']](i - 1) + "1");
      number = number * 10;
    }
  };
  dart.fn(integer_to_string_test_01_multi.main, VoidTodynamic());
  // Exports:
  exports.integer_to_string_test_01_multi = integer_to_string_test_01_multi;
});
