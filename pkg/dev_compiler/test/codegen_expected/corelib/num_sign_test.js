dart_library.library('corelib/num_sign_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__num_sign_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const num_sign_test = Object.create(null);
  let JSArrayOfnum = () => (JSArrayOfnum = dart.constFn(_interceptors.JSArray$(core.num)))();
  let numTonum = () => (numTonum = dart.constFn(dart.definiteFunctionType(core.num, [core.num])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  num_sign_test.sign = function(value) {
    if (typeof value == 'number') {
      if (dart.notNull(value) < 0) return -1;
      if (dart.notNull(value) > 0) return 1;
      return 0;
    }
    if (dart.test(value[dartx.isNaN])) return value;
    if (value == 0.0) return value;
    if (dart.notNull(value) > 0.0) return 1.0;
    return -1.0;
  };
  dart.fn(num_sign_test.sign, numTonum());
  dart.defineLazy(num_sign_test, {
    get numbers() {
      return JSArrayOfnum().of([0, 1, 2, 127, 128, 255, 256, 65535, 65536, 1073741823, 1073741824, 1073741825, 2147483647, 2147483648, 2147483649, 68719476735, 4294967296, 4294967297, 4503599627370496, 4503599627370497, 9007199254740991, 9007199254740992, 9007199254740993, 9007199254740994, 9223372036854775807, 9223372036854775808, 9223372036854775809, 18446744073709551615, 18446744073709551616, 18446744073709551617, 179769313486231570814527423731704356798070567525844996598917476803157260780028538760589558632766878171540458953514382464234321326889464182768467546703537516986049910576551282076245490090389328944075868508455133942304583236903222948165808559332123348274797826204144723168738177180919299881250404026184124858368, 179769313486231580793728971405303415079934132710037826936173778980444968292764750946649017977587207096330286416692887910946555547851940402630657488671505820681908902000708383676273854845817711531764475730270069855571366959622842914819860834936475292719074168444365510704342711559699508093042880177904174497792, 179769313486231590772930519078902473361797697894230657273430081157732675805500963132708477322407536021120113879871393357658789768814416622492847430639474124377767893424865485276302219601246094119453082952085005768838150682342462881473913110540827237163350510684586298239947245938479716304835356329624224137216, 0.0, 5e-324, 2.225073858507201e-308, 2.2250738585072014e-308, 0.49999999999999994, 0.5, 0.5000000000000001, 0.9999999999999999, 1.0, 1.0000000000000002, 4294967295.0, 4294967296.0, 4503599627370495.5, 4503599627370497.0, 9007199254740991.0, 9007199254740992.0, 1.7976931348623157e+308, 1.0 / 0.0, 0.0 / 0.0]);
    },
    set numbers(_) {}
  });
  num_sign_test.main = function() {
    for (let number of num_sign_test.numbers) {
      num_sign_test.test(number);
      num_sign_test.test(-dart.notNull(number));
    }
  };
  dart.fn(num_sign_test.main, VoidTodynamic());
  num_sign_test.test = function(number) {
    let expectSign = num_sign_test.sign(core.num._check(number));
    let actualSign = core.num._check(dart.dload(number, 'sign'));
    if (dart.test(expectSign[dartx.isNaN])) {
      expect$.Expect.isTrue(actualSign[dartx.isNaN], dart.str`${number}: ${actualSign} != NaN`);
    } else {
      if (typeof number == 'number') {
        expect$.Expect.isTrue(typeof actualSign == 'number', dart.str`${number}.sign is int`);
      } else {
        expect$.Expect.isTrue(typeof actualSign == 'number', dart.str`${number}.sign is double`);
      }
      expect$.Expect.equals(expectSign, actualSign, dart.str`${number}`);
      expect$.Expect.equals(dart.dload(number, 'isNegative'), actualSign[dartx.isNegative], dart.str`${number}:negative`);
      let renumber = dart.notNull(actualSign) * dart.notNull(core.num._check(dart.dsend(number, 'abs')));
      expect$.Expect.equals(number, renumber, dart.str`${number} (sign*abs)`);
      if (typeof number == 'number') {
        expect$.Expect.isTrue(typeof renumber == 'number', dart.str`${number} (sign*abs) is int`);
      } else {
        expect$.Expect.isTrue(typeof renumber == 'number', dart.str`${number} (sign*abs) is double`);
      }
    }
  };
  dart.fn(num_sign_test.test, dynamicTovoid());
  // Exports:
  exports.num_sign_test = num_sign_test;
});
