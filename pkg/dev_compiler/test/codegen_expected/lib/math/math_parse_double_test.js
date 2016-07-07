dart_library.library('lib/math/math_parse_double_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__math_parse_double_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const math_parse_double_test = Object.create(null);
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let ListOfObject = () => (ListOfObject = dart.constFn(core.List$(core.Object)))();
  let JSArrayOfListOfObject = () => (JSArrayOfListOfObject = dart.constFn(_interceptors.JSArray$(ListOfObject())))();
  let VoidTodouble = () => (VoidTodouble = dart.constFn(dart.definiteFunctionType(core.double, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  let doubleAndStringTovoid = () => (doubleAndStringTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.double, core.String])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  math_parse_double_test.parseDoubleThrowsFormatException = function(str) {
    expect$.Expect.throws(dart.fn(() => core.double.parse(core.String._check(str)), VoidTodouble()), dart.fn(e => core.FormatException.is(e), dynamicTobool()));
  };
  dart.fn(math_parse_double_test.parseDoubleThrowsFormatException, dynamicTovoid());
  math_parse_double_test.runTest = function(expected, input) {
    expect$.Expect.equals(expected, core.double.parse(input));
    expect$.Expect.equals(expected, core.double.parse(dart.str` ${input} `));
    expect$.Expect.equals(expected, core.double.parse(dart.str` ${input}`));
    expect$.Expect.equals(expected, core.double.parse(dart.str`${input} `));
    expect$.Expect.equals(expected, core.double.parse(dart.str`+${input}`));
    expect$.Expect.equals(expected, core.double.parse(dart.str` +${input} `));
    expect$.Expect.equals(expected, core.double.parse(dart.str`+${input} `));
    expect$.Expect.equals(expected, core.double.parse(dart.str`  ${input}  `));
    expect$.Expect.equals(expected, core.double.parse(dart.str`  ${input}`));
    expect$.Expect.equals(expected, core.double.parse(dart.str`${input}  `));
    expect$.Expect.equals(expected, core.double.parse(dart.str`  +${input}  `));
    expect$.Expect.equals(expected, core.double.parse(dart.str`+${input}  `));
    expect$.Expect.equals(expected, core.double.parse(dart.str`  ${input}  `));
    expect$.Expect.equals(expected, core.double.parse(dart.str` ᠎${input}`));
    expect$.Expect.equals(expected, core.double.parse(dart.str`${input}  `));
    expect$.Expect.equals(expected, core.double.parse(dart.str`  +${input}  `));
    expect$.Expect.equals(-dart.notNull(expected), core.double.parse(dart.str`-${input}`));
    expect$.Expect.equals(-dart.notNull(expected), core.double.parse(dart.str` -${input} `));
    expect$.Expect.equals(-dart.notNull(expected), core.double.parse(dart.str`-${input} `));
    expect$.Expect.equals(-dart.notNull(expected), core.double.parse(dart.str`  -${input}  `));
    expect$.Expect.equals(-dart.notNull(expected), core.double.parse(dart.str`-${input}  `));
    expect$.Expect.equals(-dart.notNull(expected), core.double.parse(dart.str`  -${input}  `));
  };
  dart.fn(math_parse_double_test.runTest, doubleAndStringTovoid());
  dart.defineLazy(math_parse_double_test, {
    get TESTS() {
      return JSArrayOfListOfObject().of([JSArrayOfObject().of([499.0, "499"]), JSArrayOfObject().of([499.0, "499."]), JSArrayOfObject().of([499.0, "499.0"]), JSArrayOfObject().of([0.0, "0"]), JSArrayOfObject().of([0.0, ".0"]), JSArrayOfObject().of([0.0, "0."]), JSArrayOfObject().of([0.1, "0.1"]), JSArrayOfObject().of([0.1, ".1"]), JSArrayOfObject().of([10.0, "010"]), JSArrayOfObject().of([1.5, "1.5"]), JSArrayOfObject().of([1.5, "001.5"]), JSArrayOfObject().of([1.5, "1.500"]), JSArrayOfObject().of([1234567.89, "1234567.89"]), JSArrayOfObject().of([1.234567e+95, "1234567e89"]), JSArrayOfObject().of([123456789.0, "1234567.89e2"]), JSArrayOfObject().of([123456789.0, "1234567.89e+2"]), JSArrayOfObject().of([12345.6789, "1234567.89e-2"]), JSArrayOfObject().of([5.0, "5"]), JSArrayOfObject().of([123456700.0, "1234567.e2"]), JSArrayOfObject().of([123456700.0, "1234567.e+2"]), JSArrayOfObject().of([core.double.INFINITY, "Infinity"]), JSArrayOfObject().of([5e-324, "5e-324"]), JSArrayOfObject().of([5e-324, "0.000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004940656458412465441765687928682213723650598026143247644255856825006755072702087518652998363616359923797965646954457177309266567103559397963987747960107818781263007131903114045278458171678489821036887186360569987307230500063874091535649843873124733972731696151400317153853980741262385655911710266585566867681870395603106249319452715914924553293054565444011274801297099995419319894090804165633245247571478690147267801593552386115501348035264934720193790268107107491703332226844753335720832431936092382893458368060106011506169809753078342277318329247904982524730776375927247874656084778203734469699533647017972677717585125660551199131504891101451037862738167250955837389733598993664809941164205702637090279242767544565229087538682506419718265533447265625"]), JSArrayOfObject().of([0.0, "2e-324"]), JSArrayOfObject().of([0.9999999999999999, "0.9999999999999999"]), JSArrayOfObject().of([1.0, "1.00000000000000005"]), JSArrayOfObject().of([1.0000000000000002, "1.0000000000000002"]), JSArrayOfObject().of([2147483647.0, "2147483647"]), JSArrayOfObject().of([2147483647.0000002, "2147483647.0000002"]), JSArrayOfObject().of([2147483648.0, "2147483648"]), JSArrayOfObject().of([4295967295.0, "4295967295"]), JSArrayOfObject().of([4295967295.000001, "4295967295.000001"]), JSArrayOfObject().of([4295967296.0, "4295967296"]), JSArrayOfObject().of([1.7976931348623157e+308, "1.7976931348623157e+308"]), JSArrayOfObject().of([1.7976931348623157e+308, "1.7976931348623158e+308"]), JSArrayOfObject().of([core.double.INFINITY, "1.7976931348623159e+308"]), JSArrayOfObject().of([0.049999999999999996, ".049999999999999994"]), JSArrayOfObject().of([0.05, ".04999999999999999935"]), JSArrayOfObject().of([4503599627370498.0, "4503599627370497.5"]), JSArrayOfObject().of([1.2345678901234568e+39, "1234567890123456898981341324213421342134"]), JSArrayOfObject().of([9.87291183742987e+24, "9872911837429871193379121"]), JSArrayOfObject().of([1e+21, "1e+21"])]);
    }
  });
  math_parse_double_test.main = function() {
    for (let test of math_parse_double_test.TESTS) {
      math_parse_double_test.runTest(core.double._check(test[dartx.get](0)), core.String._check(test[dartx.get](1)));
    }
    expect$.Expect.equals(true, core.double.parse("-0")[dartx.isNegative]);
    expect$.Expect.equals(true, core.double.parse("   -0   ")[dartx.isNegative]);
    expect$.Expect.equals(true, core.double.parse("    -0    ")[dartx.isNegative]);
    expect$.Expect.isTrue(core.double.parse("NaN")[dartx.isNaN]);
    expect$.Expect.isTrue(core.double.parse("-NaN")[dartx.isNaN]);
    expect$.Expect.isTrue(core.double.parse("+NaN")[dartx.isNaN]);
    expect$.Expect.isTrue(core.double.parse("NaN ")[dartx.isNaN]);
    expect$.Expect.isTrue(core.double.parse("-NaN ")[dartx.isNaN]);
    expect$.Expect.isTrue(core.double.parse("+NaN ")[dartx.isNaN]);
    expect$.Expect.isTrue(core.double.parse(" NaN ")[dartx.isNaN]);
    expect$.Expect.isTrue(core.double.parse(" -NaN ")[dartx.isNaN]);
    expect$.Expect.isTrue(core.double.parse(" +NaN ")[dartx.isNaN]);
    expect$.Expect.isTrue(core.double.parse(" NaN")[dartx.isNaN]);
    expect$.Expect.isTrue(core.double.parse(" -NaN")[dartx.isNaN]);
    expect$.Expect.isTrue(core.double.parse(" +NaN")[dartx.isNaN]);
    expect$.Expect.isTrue(core.double.parse("NaN ")[dartx.isNaN]);
    expect$.Expect.isTrue(core.double.parse("-NaN ")[dartx.isNaN]);
    expect$.Expect.isTrue(core.double.parse("+NaN ")[dartx.isNaN]);
    expect$.Expect.isTrue(core.double.parse("  NaN ")[dartx.isNaN]);
    expect$.Expect.isTrue(core.double.parse("  -NaN ")[dartx.isNaN]);
    expect$.Expect.isTrue(core.double.parse("  +NaN ")[dartx.isNaN]);
    expect$.Expect.isTrue(core.double.parse("  NaN")[dartx.isNaN]);
    expect$.Expect.isTrue(core.double.parse("  -NaN")[dartx.isNaN]);
    expect$.Expect.isTrue(core.double.parse("  +NaN")[dartx.isNaN]);
    math_parse_double_test.parseDoubleThrowsFormatException("1b");
    math_parse_double_test.parseDoubleThrowsFormatException(" 1b ");
    math_parse_double_test.parseDoubleThrowsFormatException(" 1 b ");
    math_parse_double_test.parseDoubleThrowsFormatException(" e3 ");
    math_parse_double_test.parseDoubleThrowsFormatException(" .e3 ");
    math_parse_double_test.parseDoubleThrowsFormatException("00x12");
    math_parse_double_test.parseDoubleThrowsFormatException(" 00x12 ");
    math_parse_double_test.parseDoubleThrowsFormatException("-1b");
    math_parse_double_test.parseDoubleThrowsFormatException(" -1b ");
    math_parse_double_test.parseDoubleThrowsFormatException(" -1 b ");
    math_parse_double_test.parseDoubleThrowsFormatException("-00x12");
    math_parse_double_test.parseDoubleThrowsFormatException(" -00x12 ");
    math_parse_double_test.parseDoubleThrowsFormatException("  -00x12 ");
    math_parse_double_test.parseDoubleThrowsFormatException("0x0x12");
    math_parse_double_test.parseDoubleThrowsFormatException("+ 1.5");
    math_parse_double_test.parseDoubleThrowsFormatException("- 1.5");
    math_parse_double_test.parseDoubleThrowsFormatException("");
    math_parse_double_test.parseDoubleThrowsFormatException("   ");
    math_parse_double_test.parseDoubleThrowsFormatException("+0x1234567890");
    math_parse_double_test.parseDoubleThrowsFormatException("   +0x1234567890   ");
    math_parse_double_test.parseDoubleThrowsFormatException("   +0x100   ");
    math_parse_double_test.parseDoubleThrowsFormatException("+0x100");
    math_parse_double_test.parseDoubleThrowsFormatException("0x1234567890");
    math_parse_double_test.parseDoubleThrowsFormatException("-0x1234567890");
    math_parse_double_test.parseDoubleThrowsFormatException("   0x1234567890   ");
    math_parse_double_test.parseDoubleThrowsFormatException("   -0x1234567890   ");
    math_parse_double_test.parseDoubleThrowsFormatException("0x100");
    math_parse_double_test.parseDoubleThrowsFormatException("-0x100");
    math_parse_double_test.parseDoubleThrowsFormatException("   0x100   ");
    math_parse_double_test.parseDoubleThrowsFormatException("   -0x100   ");
    math_parse_double_test.parseDoubleThrowsFormatException("0xabcdef");
    math_parse_double_test.parseDoubleThrowsFormatException("0xABCDEF");
    math_parse_double_test.parseDoubleThrowsFormatException("0xabCDEf");
    math_parse_double_test.parseDoubleThrowsFormatException("-0xabcdef");
    math_parse_double_test.parseDoubleThrowsFormatException("-0xABCDEF");
    math_parse_double_test.parseDoubleThrowsFormatException("   0xabcdef   ");
    math_parse_double_test.parseDoubleThrowsFormatException("   0xABCDEF   ");
    math_parse_double_test.parseDoubleThrowsFormatException("   -0xabcdef   ");
    math_parse_double_test.parseDoubleThrowsFormatException("   -0xABCDEF   ");
    math_parse_double_test.parseDoubleThrowsFormatException("0x00000abcdef");
    math_parse_double_test.parseDoubleThrowsFormatException("0x00000ABCDEF");
    math_parse_double_test.parseDoubleThrowsFormatException("-0x00000abcdef");
    math_parse_double_test.parseDoubleThrowsFormatException("-0x00000ABCDEF");
    math_parse_double_test.parseDoubleThrowsFormatException("   0x00000abcdef   ");
    math_parse_double_test.parseDoubleThrowsFormatException("   0x00000ABCDEF   ");
    math_parse_double_test.parseDoubleThrowsFormatException("   -0x00000abcdef   ");
    math_parse_double_test.parseDoubleThrowsFormatException("   -0x00000ABCDEF   ");
    math_parse_double_test.parseDoubleThrowsFormatException("   -INFINITY   ");
    math_parse_double_test.parseDoubleThrowsFormatException("   NAN   ");
    math_parse_double_test.parseDoubleThrowsFormatException("   inf   ");
    math_parse_double_test.parseDoubleThrowsFormatException("   nan   ");
  };
  dart.fn(math_parse_double_test.main, VoidTovoid());
  // Exports:
  exports.math_parse_double_test = math_parse_double_test;
});
