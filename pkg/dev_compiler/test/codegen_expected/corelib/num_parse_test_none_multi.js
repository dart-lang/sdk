dart_library.library('corelib/num_parse_test_none_multi', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__num_parse_test_none_multi(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const num_parse_test_none_multi = Object.create(null);
  let numAndnumAndStringTovoid = () => (numAndnumAndStringTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.num, core.num, core.String])))();
  let StringAndnumTovoid = () => (StringAndnumTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.String, core.num])))();
  let intTovoid = () => (intTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.int])))();
  let doubleTovoid = () => (doubleTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.double])))();
  let StringTonum = () => (StringTonum = dart.constFn(dart.definiteFunctionType(core.num, [core.String])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let StringTovoid = () => (StringTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.String])))();
  num_parse_test_none_multi.whiteSpace = dart.constList(["", "\t", "\n", "\v", "\f", "\r", "", " ", " ", "᠎", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", "\u2028", "\u2029", " ", " ", "　", "﻿"], core.String);
  num_parse_test_none_multi.expectNumEquals = function(expect, actual, message) {
    if (typeof expect == 'number' && dart.test(expect[dartx.isNaN])) {
      expect$.Expect.isTrue(typeof actual == 'number' && dart.test(actual[dartx.isNaN]), dart.str`isNaN: ${message}`);
    } else {
      expect$.Expect.identical(expect, actual, message);
    }
  };
  dart.fn(num_parse_test_none_multi.expectNumEquals, numAndnumAndStringTovoid());
  num_parse_test_none_multi.testParseAllWhitespace = function(source, result) {
    for (let ws1 of num_parse_test_none_multi.whiteSpace) {
      for (let ws2 of num_parse_test_none_multi.whiteSpace) {
        let padded = dart.str`${ws1}${source}${ws2}`;
        num_parse_test_none_multi.expectNumEquals(result, core.num.parse(padded), dart.str`parse '${padded}'`);
        padded = dart.str`${ws1}${ws2}${source}`;
        num_parse_test_none_multi.expectNumEquals(result, core.num.parse(padded), dart.str`parse '${padded}'`);
        padded = dart.str`${source}${ws1}${ws2}`;
        num_parse_test_none_multi.expectNumEquals(result, core.num.parse(padded), dart.str`parse '${padded}'`);
      }
    }
  };
  dart.fn(num_parse_test_none_multi.testParseAllWhitespace, StringAndnumTovoid());
  num_parse_test_none_multi.testParseWhitespace = function(source, result) {
    dart.assert(dart.notNull(result) >= 0);
    num_parse_test_none_multi.testParseAllWhitespace(source, result);
    num_parse_test_none_multi.testParseAllWhitespace(dart.str`-${source}`, -dart.notNull(result));
  };
  dart.fn(num_parse_test_none_multi.testParseWhitespace, StringAndnumTovoid());
  num_parse_test_none_multi.testParse = function(source, result) {
    num_parse_test_none_multi.expectNumEquals(result, core.num.parse(source), dart.str`parse '${source}'`);
    num_parse_test_none_multi.expectNumEquals(result, core.num.parse(dart.str` ${source}`), dart.str`parse ' ${source}'`);
    num_parse_test_none_multi.expectNumEquals(result, core.num.parse(dart.str`${source} `), dart.str`parse '${source} '`);
    num_parse_test_none_multi.expectNumEquals(result, core.num.parse(dart.str` ${source} `), dart.str`parse ' ${source} '`);
  };
  dart.fn(num_parse_test_none_multi.testParse, StringAndnumTovoid());
  num_parse_test_none_multi.testInt = function(value) {
    num_parse_test_none_multi.testParse(dart.str`${value}`, value);
    num_parse_test_none_multi.testParse(dart.str`+${value}`, value);
    num_parse_test_none_multi.testParse(dart.str`-${value}`, -dart.notNull(value));
    let hex = dart.str`0x${value[dartx.toRadixString](16)}`;
    let lchex = hex[dartx.toLowerCase]();
    num_parse_test_none_multi.testParse(lchex, value);
    num_parse_test_none_multi.testParse(dart.str`+${lchex}`, value);
    num_parse_test_none_multi.testParse(dart.str`-${lchex}`, -dart.notNull(value));
    let uchex = hex[dartx.toUpperCase]();
    num_parse_test_none_multi.testParse(uchex, value);
    num_parse_test_none_multi.testParse(dart.str`+${uchex}`, value);
    num_parse_test_none_multi.testParse(dart.str`-${uchex}`, -dart.notNull(value));
  };
  dart.fn(num_parse_test_none_multi.testInt, intTovoid());
  num_parse_test_none_multi.testIntAround = function(value) {
    num_parse_test_none_multi.testInt(dart.notNull(value) - 1);
    num_parse_test_none_multi.testInt(value);
    num_parse_test_none_multi.testInt(dart.notNull(value) + 1);
  };
  dart.fn(num_parse_test_none_multi.testIntAround, intTovoid());
  num_parse_test_none_multi.testDouble = function(value) {
    num_parse_test_none_multi.testParse(dart.str`${value}`, value);
    num_parse_test_none_multi.testParse(dart.str`+${value}`, value);
    num_parse_test_none_multi.testParse(dart.str`-${value}`, -dart.notNull(value));
    if (dart.test(value[dartx.isFinite])) {
      let exp = value[dartx.toStringAsExponential]();
      let lcexp = exp[dartx.toLowerCase]();
      num_parse_test_none_multi.testParse(lcexp, value);
      num_parse_test_none_multi.testParse(dart.str`+${lcexp}`, value);
      num_parse_test_none_multi.testParse(dart.str`-${lcexp}`, -dart.notNull(value));
      let ucexp = exp[dartx.toUpperCase]();
      num_parse_test_none_multi.testParse(ucexp, value);
      num_parse_test_none_multi.testParse(dart.str`+${ucexp}`, value);
      num_parse_test_none_multi.testParse(dart.str`-${ucexp}`, -dart.notNull(value));
    }
  };
  dart.fn(num_parse_test_none_multi.testDouble, doubleTovoid());
  num_parse_test_none_multi.testFail = function(source) {
    let object = new core.Object();
    expect$.Expect.throws(dart.fn(() => {
      core.num.parse(source, dart.fn(s => {
        expect$.Expect.equals(source, s);
        dart.throw(object);
      }, StringTonum()));
    }, VoidTovoid()), dart.fn(e => core.identical(object, e), dynamicTobool()), dart.str`Fail: '${source}'`);
  };
  dart.fn(num_parse_test_none_multi.testFail, StringTovoid());
  num_parse_test_none_multi.main = function() {
    num_parse_test_none_multi.testInt(0);
    num_parse_test_none_multi.testInt(1);
    num_parse_test_none_multi.testInt(9);
    num_parse_test_none_multi.testInt(10);
    num_parse_test_none_multi.testInt(99);
    num_parse_test_none_multi.testInt(100);
    num_parse_test_none_multi.testIntAround(256);
    num_parse_test_none_multi.testIntAround(2147483648);
    num_parse_test_none_multi.testIntAround(4294967296);
    num_parse_test_none_multi.testIntAround(4503599627370496);
    num_parse_test_none_multi.testIntAround(9007199254740992);
    num_parse_test_none_multi.testIntAround(18014398509481984);
    num_parse_test_none_multi.testIntAround(9223372036854775808);
    num_parse_test_none_multi.testIntAround(18446744073709551616);
    num_parse_test_none_multi.testIntAround(1208925819614629174706176);
    num_parse_test_none_multi.testDouble(0.0);
    num_parse_test_none_multi.testDouble(5e-324);
    num_parse_test_none_multi.testDouble(2.225073858507201e-308);
    num_parse_test_none_multi.testDouble(2.2250738585072014e-308);
    num_parse_test_none_multi.testDouble(0.49999999999999994);
    num_parse_test_none_multi.testDouble(0.5);
    num_parse_test_none_multi.testDouble(0.5000000000000001);
    num_parse_test_none_multi.testDouble(0.9999999999999999);
    num_parse_test_none_multi.testDouble(1.0);
    num_parse_test_none_multi.testDouble(1.0000000000000002);
    num_parse_test_none_multi.testDouble(4294967295.0);
    num_parse_test_none_multi.testDouble(4294967296.0);
    num_parse_test_none_multi.testDouble(4503599627370495.5);
    num_parse_test_none_multi.testDouble(4503599627370497.0);
    num_parse_test_none_multi.testDouble(9007199254740991.0);
    num_parse_test_none_multi.testDouble(9007199254740992.0);
    num_parse_test_none_multi.testDouble(1.7976931348623157e+308);
    num_parse_test_none_multi.testDouble(core.double.INFINITY);
    num_parse_test_none_multi.testParse("000000000000", 0);
    num_parse_test_none_multi.testParse("000000000001", 1);
    num_parse_test_none_multi.testParse("000000000000.0000000000000", 0.0);
    num_parse_test_none_multi.testParse("000000000001.0000000000000", 1.0);
    num_parse_test_none_multi.testParse("0x0000000000", 0);
    num_parse_test_none_multi.testParse("0e0", 0.0);
    num_parse_test_none_multi.testParse("0e+0", 0.0);
    num_parse_test_none_multi.testParse("0e-0", 0.0);
    num_parse_test_none_multi.testParse("-0e0", -0.0);
    num_parse_test_none_multi.testParse("-0e+0", -0.0);
    num_parse_test_none_multi.testParse("-0e-0", -0.0);
    num_parse_test_none_multi.testParse("1e0", 1.0);
    num_parse_test_none_multi.testParse("1e+0", 1.0);
    num_parse_test_none_multi.testParse("1e-0", 1.0);
    num_parse_test_none_multi.testParse("-1e0", -1.0);
    num_parse_test_none_multi.testParse("-1e+0", -1.0);
    num_parse_test_none_multi.testParse("-1e-0", -1.0);
    num_parse_test_none_multi.testParse("1.", 1.0);
    num_parse_test_none_multi.testParse(".1", 0.1);
    num_parse_test_none_multi.testParse("1.e1", 10.0);
    num_parse_test_none_multi.testParse(".1e1", 1.0);
    num_parse_test_none_multi.testParseWhitespace("0x1", 1);
    num_parse_test_none_multi.testParseWhitespace("1", 1);
    num_parse_test_none_multi.testParseWhitespace("1.0", 1.0);
    num_parse_test_none_multi.testParseWhitespace("1e1", 10.0);
    num_parse_test_none_multi.testParseWhitespace(".1e1", 1.0);
    num_parse_test_none_multi.testParseWhitespace("1.e1", 10.0);
    num_parse_test_none_multi.testParseWhitespace("1e+1", 10.0);
    num_parse_test_none_multi.testParseWhitespace("1e-1", 0.1);
    num_parse_test_none_multi.testFail("- 1");
    num_parse_test_none_multi.testFail("+ 1");
    num_parse_test_none_multi.testFail("2 2");
    num_parse_test_none_multi.testFail("0x 42");
    num_parse_test_none_multi.testFail("1 .");
    num_parse_test_none_multi.testFail(". 1");
    num_parse_test_none_multi.testFail("1e 2");
    num_parse_test_none_multi.testFail("1 e2");
    num_parse_test_none_multi.testFail("0x1H");
    num_parse_test_none_multi.testFail("12H");
    num_parse_test_none_multi.testFail("1x2");
    num_parse_test_none_multi.testFail("00x2");
    num_parse_test_none_multi.testFail("0x2.2");
    num_parse_test_none_multi.testFail("0x");
    num_parse_test_none_multi.testFail("-0x");
    num_parse_test_none_multi.testFail("+0x");
    num_parse_test_none_multi.testFail(".e1");
    num_parse_test_none_multi.testFail("e1");
    num_parse_test_none_multi.testFail("e+1");
    num_parse_test_none_multi.testFail("e-1");
    num_parse_test_none_multi.testFail("-e1");
    num_parse_test_none_multi.testFail("-e+1");
    num_parse_test_none_multi.testFail("-e-1");
    num_parse_test_none_multi.testFail("infinity");
    num_parse_test_none_multi.testFail("INFINITY");
    num_parse_test_none_multi.testFail("1.#INF");
    num_parse_test_none_multi.testFail("inf");
    num_parse_test_none_multi.testFail("nan");
    num_parse_test_none_multi.testFail("NAN");
    num_parse_test_none_multi.testFail("1.#IND");
    num_parse_test_none_multi.testFail("indef");
    num_parse_test_none_multi.testFail("qnan");
    num_parse_test_none_multi.testFail("snan");
  };
  dart.fn(num_parse_test_none_multi.main, VoidTovoid());
  // Exports:
  exports.num_parse_test_none_multi = num_parse_test_none_multi;
});
