dart_library.library('corelib/int_modulo_arith_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__int_modulo_arith_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const math = dart_sdk.math;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const int_modulo_arith_test_none_multi = Object.create(null);
  let dynamicAnddynamicAnddynamicTodynamic = () => (dynamicAnddynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic])))();
  let VoidTobool = () => (VoidTobool = dart.constFn(dart.definiteFunctionType(core.bool, [])))();
  let dynamicAnddynamicAnddynamic__Todynamic = () => (dynamicAnddynamicAnddynamic__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  int_modulo_arith_test_none_multi.smallNumber = 1234567890;
  int_modulo_arith_test_none_multi.mediumNumber = 1234567890123456;
  int_modulo_arith_test_none_multi.bigNumber = 590295810358705600000;
  int_modulo_arith_test_none_multi.testModPow = function() {
    function test(x, e, m, expectedResult) {
      dart.assert(dart.fn(() => {
        if (typeof 1 == 'number') return true;
        function slowModPow(x, e, m) {
          let r = 1;
          while (dart.test(dart.dsend(e, '>', 0))) {
            if (dart.test(dart.dload(e, 'isOdd'))) r = dart.asInt((dart.notNull(r) * dart.notNull(core.num._check(x)))[dartx['%']](core.num._check(m)));
            e = dart.dsend(e, '>>', 1);
            x = dart.dsend(dart.dsend(x, '*', x), '%', m);
          }
          return r;
        }
        dart.fn(slowModPow, dynamicAnddynamicAnddynamicTodynamic());
        return dart.equals(slowModPow(x, e, m), expectedResult);
      }, VoidTobool()));
      let result = dart.dsend(x, 'modPow', e, m);
      expect$.Expect.equals(expectedResult, result, dart.str`${x}.modPow(${e}, ${m})`);
    }
    dart.fn(test, dynamicAnddynamicAnddynamic__Todynamic());
    test(10, 20, 1, 0);
    test(1234567890, 1000000001, 19, 11);
    test(1234567890, 19, 1000000001, 122998977);
    test(19, 1234567890, 1000000001, 619059596);
    test(19, 1000000001, 1234567890, 84910879);
    test(1000000001, 19, 1234567890, 872984351);
    test(1000000001, 1234567890, 19, 0);
    test(12345678901234567890, 10000000000000000001, 19, 2);
    test(12345678901234567890, 19, 10000000000000000001, 3239137215315834625);
    test(19, 12345678901234567890, 10000000000000000001, 4544207837373941034);
    test(19, 10000000000000000001, 12345678901234567890, 11135411705397624859);
    test(10000000000000000001, 19, 12345678901234567890, 2034013733189773841);
    test(10000000000000000001, 12345678901234567890, 19, 1);
    test(12345678901234567890, 19, 10000000000000000001, 3239137215315834625);
    test(12345678901234567890, 10000000000000000001, 19, 2);
    test(123456789012345678901234567890, 123456789012345678901234567891, 123456789012345678901234567899, 116401406051033429924651549616);
    test(123456789012345678901234567890, 123456789012345678901234567899, 123456789012345678901234567891, 123456789012345678901234567890);
    test(123456789012345678901234567899, 123456789012345678901234567890, 123456789012345678901234567891, 35088523091000351053091545070);
    test(123456789012345678901234567899, 123456789012345678901234567891, 123456789012345678901234567890, 18310047270234132455316941949);
    test(123456789012345678901234567891, 123456789012345678901234567899, 123456789012345678901234567890, 1);
    test(123456789012345678901234567891, 123456789012345678901234567890, 123456789012345678901234567899, 40128068573873018143207285483);
  };
  dart.fn(int_modulo_arith_test_none_multi.testModPow, VoidTodynamic());
  int_modulo_arith_test_none_multi.testModInverse = function() {
    function test(x, m, expectedResult) {
      dart.assert(dart.dsend(expectedResult, '<', m));
      dart.assert(typeof 1 == 'number' || dart.equals(dart.dsend(dart.dsend(dart.dsend(dart.dsend(x, '%', m), '*', expectedResult), '-', 1), '%', m), 0));
      let result = dart.dsend(x, 'modInverse', m);
      expect$.Expect.equals(expectedResult, result, dart.str`${x} modinv ${m}`);
      if (dart.test(dart.dsend(x, '>', m))) {
        x = dart.dsend(x, '%', m);
        let result = dart.dsend(x, 'modInverse', m);
        expect$.Expect.equals(expectedResult, result, dart.str`${x} modinv ${m}`);
      }
    }
    dart.fn(test, dynamicAnddynamicAnddynamicTodynamic());
    function testThrows(x, m) {
      expect$.Expect.throws(dart.fn(() => dart.dsend(x, 'modInverse', m), VoidTovoid()), null, dart.str`${x} modinv ${m}`);
      expect$.Expect.throws(dart.fn(() => dart.dsend(m, 'modInverse', x), VoidTovoid()), null, dart.str`${m} modinv ${x}`);
    }
    dart.fn(testThrows, dynamicAnddynamicTodynamic());
    test(1, 1, 0);
    testThrows(0, 1000000001);
    testThrows(2, 4);
    testThrows(99, 9);
    testThrows(19, 1000000001);
    testThrows(123456789012345678901234567890, 123456789012345678901234567899);
    test(1234567890, 19, 11);
    test(1234567890, 1000000001, 189108911);
    test(19, 1234567890, 519818059);
    test(1000000001, 1234567890, 1001100101);
    test(12345, 12346, 12345);
    test(12345, 12346, 12345);
    test(int_modulo_arith_test_none_multi.smallNumber, 137, 42);
    test(137, int_modulo_arith_test_none_multi.smallNumber, 856087223);
    test(int_modulo_arith_test_none_multi.mediumNumber, 137, 77);
    test(137, int_modulo_arith_test_none_multi.mediumNumber, 540686667207353);
  };
  dart.fn(int_modulo_arith_test_none_multi.testModInverse, VoidTodynamic());
  int_modulo_arith_test_none_multi.testGcd = function() {
    function callCombos(value, other, testFunc) {
      dart.dcall(testFunc, value, other);
      dart.dcall(testFunc, value, dart.dsend(other, 'unary-'));
      dart.dcall(testFunc, dart.dsend(value, 'unary-'), other);
      dart.dcall(testFunc, dart.dsend(value, 'unary-'), dart.dsend(other, 'unary-'));
      if (dart.equals(value, other)) return;
      dart.dcall(testFunc, other, value);
      dart.dcall(testFunc, other, dart.dsend(value, 'unary-'));
      dart.dcall(testFunc, dart.dsend(other, 'unary-'), value);
      dart.dcall(testFunc, dart.dsend(other, 'unary-'), dart.dsend(value, 'unary-'));
    }
    dart.fn(callCombos, dynamicAnddynamicAnddynamicTodynamic());
    function test(value, other, expectedResult) {
      dart.assert(dart.equals(expectedResult, 0) || dart.equals(dart.dsend(value, '%', expectedResult), 0));
      dart.assert(dart.equals(expectedResult, 0) || dart.equals(dart.dsend(other, '%', expectedResult), 0));
      callCombos(value, other, dart.fn((a, b) => {
        let result = dart.dsend(a, 'gcd', b);
        expect$.Expect.equals(0, dart.equals(result, 0) ? a : dart.dsend(a, '%', result), dart.str`${result} | ${a}`);
        expect$.Expect.equals(0, dart.equals(result, 0) ? b : dart.dsend(b, '%', result), dart.str`${result} | ${b}`);
        dart.assert(dart.dsend(result, '>=', expectedResult));
        expect$.Expect.equals(expectedResult, result, dart.str`${a}.gcd(${b})`);
      }, dynamicAnddynamicTodynamic()));
    }
    dart.fn(test, dynamicAnddynamicAnddynamicTodynamic());
    function testThrows(value, other) {
      callCombos(value, other, dart.fn((a, b) => {
        expect$.Expect.throws(dart.fn(() => dart.dsend(a, 'gcd', b), VoidTovoid()), null, dart.str`${a}.gcd(${b})`);
      }, dynamicAnddynamicTodynamic()));
    }
    dart.fn(testThrows, dynamicAnddynamicTodynamic());
    testThrows(2.5, 5);
    testThrows(5, 2.5);
    test(1, 1, 1);
    test(1, 2, 1);
    test(3, 5, 1);
    test(37, 37, 37);
    test(9999, 7272, 909);
    test(0, 1000, 1000);
    test(0, 0, 0);
    test(693, 609, 21);
    test(693 << 5, 609 << 5, 21 << 5);
    test(693 * 937, 609 * 937, 21 * 937);
    test(693 * dart.notNull(math.pow(2, 32)), 609 * dart.notNull(math.pow(2, 32)), 21 * dart.notNull(math.pow(2, 32)));
    test(693 * dart.notNull(math.pow(2, 52)), 609 * dart.notNull(math.pow(2, 52)), 21 * dart.notNull(math.pow(2, 52)));
    test(693 * dart.notNull(math.pow(2, 53)), 609 * dart.notNull(math.pow(2, 53)), 21 * dart.notNull(math.pow(2, 53)));
    test(693 * dart.notNull(math.pow(2, 99)), 609 * dart.notNull(math.pow(2, 99)), 21 * dart.notNull(math.pow(2, 99)));
    test(1234567890, 19, 1);
    test(1234567890, 1000000001, 1);
    test(19, 1000000001, 19);
    test(1073741823, 1073741823, 1073741823);
    test(1073741823, 1073741824, 1);
    test(math.pow(2, 54), math.pow(2, 53), math.pow(2, 53));
    test((dart.notNull(math.pow(2, 52)) - 1) * dart.notNull(math.pow(2, 14)), (dart.notNull(math.pow(2, 26)) - 1) * dart.notNull(math.pow(2, 22)), (dart.notNull(math.pow(2, 26)) - 1) * dart.notNull(math.pow(2, 14)));
  };
  dart.fn(int_modulo_arith_test_none_multi.testGcd, VoidTodynamic());
  int_modulo_arith_test_none_multi.main = function() {
    int_modulo_arith_test_none_multi.testModInverse();
    int_modulo_arith_test_none_multi.testGcd();
  };
  dart.fn(int_modulo_arith_test_none_multi.main, VoidTodynamic());
  // Exports:
  exports.int_modulo_arith_test_none_multi = int_modulo_arith_test_none_multi;
});
