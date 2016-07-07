dart_library.library('corelib/regexp/assertion_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__assertion_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const assertion_test = Object.create(null);
  const v8_regexp_utils = Object.create(null);
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.functionType(dart.void, [])))();
  let ListOfString = () => (ListOfString = dart.constFn(core.List$(core.String)))();
  let VoidTovoid$ = () => (VoidTovoid$ = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicAnddynamic__Tovoid = () => (dynamicAnddynamic__Tovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic], [core.String])))();
  let dynamic__Tovoid = () => (dynamic__Tovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic], [core.String])))();
  let dynamic__Tovoid$ = () => (dynamic__Tovoid$ = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic], [core.num])))();
  let dynamicAnddynamicAndnumTovoid = () => (dynamicAnddynamicAndnumTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic, core.num])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  let StringAndRegExpToMatch = () => (StringAndRegExpToMatch = dart.constFn(dart.definiteFunctionType(core.Match, [core.String, core.RegExp])))();
  let MatchToString = () => (MatchToString = dart.constFn(dart.definiteFunctionType(core.String, [core.Match])))();
  let StringAndRegExpToListOfString = () => (StringAndRegExpToListOfString = dart.constFn(dart.definiteFunctionType(ListOfString(), [core.String, core.RegExp])))();
  assertion_test.main = function() {
    v8_regexp_utils.description("This page tests handling of parenthetical assertions.");
    let regex1 = core.RegExp.new("(x)(?=\\1)x");
    v8_regexp_utils.shouldBe(regex1.firstMatch('xx'), JSArrayOfString().of(['xx', 'x']));
    let regex2 = core.RegExp.new("(.*?)a(?!(a+)b\\2c)\\2(.*)");
    v8_regexp_utils.shouldBe(regex2.firstMatch('baaabaac'), JSArrayOfString().of(['baaabaac', 'ba', null, 'abaac']));
    let regex3 = core.RegExp.new("(?=(a+?))(\\1ab)");
    v8_regexp_utils.shouldBe(regex3.firstMatch('aaab'), JSArrayOfString().of(['aab', 'a', 'aab']));
    let regex4 = core.RegExp.new("(?=(a+?))(\\1ab)");
    v8_regexp_utils.shouldBe(regex4.firstMatch('aaab'), JSArrayOfString().of(['aab', 'a', 'aab']));
    let regex5 = core.RegExp.new("^P([1-6])(?=\\1)([1-6])$");
    v8_regexp_utils.shouldBe(regex5.firstMatch('P11'), JSArrayOfString().of(['P11', '1', '1']));
    let regex6 = core.RegExp.new("(([a-c])b*?\\2)*");
    v8_regexp_utils.shouldBe(regex6.firstMatch('ababbbcbc'), JSArrayOfString().of(['ababb', 'bb', 'b']));
    let regex7 = core.RegExp.new("(x)(?=x)x");
    v8_regexp_utils.shouldBe(regex7.firstMatch('xx'), JSArrayOfString().of(['xx', 'x']));
    let regex8 = core.RegExp.new("(x)(\\1)");
    v8_regexp_utils.shouldBe(regex8.firstMatch('xx'), JSArrayOfString().of(['xx', 'x', 'x']));
    let regex9 = core.RegExp.new("(x)(?=\\1)x");
    v8_regexp_utils.shouldBeNull(regex9.firstMatch('xy'));
    let regex10 = core.RegExp.new("(x)(?=x)x");
    v8_regexp_utils.shouldBeNull(regex10.firstMatch('xy'));
    let regex11 = core.RegExp.new("(x)(\\1)");
    v8_regexp_utils.shouldBeNull(regex11.firstMatch('xy'));
    let regex12 = core.RegExp.new("(x)(?=\\1)x");
    v8_regexp_utils.shouldBeNull(regex12.firstMatch('x'));
    v8_regexp_utils.shouldBe(regex12.firstMatch('xx'), JSArrayOfString().of(['xx', 'x']));
    v8_regexp_utils.shouldBe(regex12.firstMatch('xxy'), JSArrayOfString().of(['xx', 'x']));
    let regex13 = core.RegExp.new("(x)zzz(?=\\1)x");
    v8_regexp_utils.shouldBe(regex13.firstMatch('xzzzx'), JSArrayOfString().of(['xzzzx', 'x']));
    v8_regexp_utils.shouldBe(regex13.firstMatch('xzzzxy'), JSArrayOfString().of(['xzzzx', 'x']));
    let regex14 = core.RegExp.new("(a)\\1(?=(b*c))bc");
    v8_regexp_utils.shouldBe(regex14.firstMatch('aabc'), JSArrayOfString().of(['aabc', 'a', 'bc']));
    v8_regexp_utils.shouldBe(regex14.firstMatch('aabcx'), JSArrayOfString().of(['aabc', 'a', 'bc']));
    let regex15 = core.RegExp.new("(a)a(?=(b*c))bc");
    v8_regexp_utils.shouldBe(regex15.firstMatch('aabc'), JSArrayOfString().of(['aabc', 'a', 'bc']));
    v8_regexp_utils.shouldBe(regex15.firstMatch('aabcx'), JSArrayOfString().of(['aabc', 'a', 'bc']));
    let regex16 = core.RegExp.new("a(?=(b*c))bc");
    v8_regexp_utils.shouldBeNull(regex16.firstMatch('ab'));
    v8_regexp_utils.shouldBe(regex16.firstMatch('abc'), JSArrayOfString().of(['abc', 'bc']));
    let regex17 = core.RegExp.new("(?=((?:ab)*))a");
    v8_regexp_utils.shouldBe(regex17.firstMatch('ab'), JSArrayOfString().of(['a', 'ab']));
    v8_regexp_utils.shouldBe(regex17.firstMatch('abc'), JSArrayOfString().of(['a', 'ab']));
    let regex18 = core.RegExp.new("(?=((?:xx)*))x");
    v8_regexp_utils.shouldBe(regex18.firstMatch('x'), JSArrayOfString().of(['x', '']));
    v8_regexp_utils.shouldBe(regex18.firstMatch('xx'), JSArrayOfString().of(['x', 'xx']));
    v8_regexp_utils.shouldBe(regex18.firstMatch('xxx'), JSArrayOfString().of(['x', 'xx']));
    let regex19 = core.RegExp.new("(?=((xx)*))x");
    v8_regexp_utils.shouldBe(regex19.firstMatch('x'), JSArrayOfString().of(['x', '', null]));
    v8_regexp_utils.shouldBe(regex19.firstMatch('xx'), JSArrayOfString().of(['x', 'xx', 'xx']));
    v8_regexp_utils.shouldBe(regex19.firstMatch('xxx'), JSArrayOfString().of(['x', 'xx', 'xx']));
    let regex20 = core.RegExp.new("(?=(xx))+x");
    v8_regexp_utils.shouldBeNull(regex20.firstMatch('x'));
    v8_regexp_utils.shouldBe(regex20.firstMatch('xx'), JSArrayOfString().of(['x', 'xx']));
    v8_regexp_utils.shouldBe(regex20.firstMatch('xxx'), JSArrayOfString().of(['x', 'xx']));
    let regex21 = core.RegExp.new("(?=a+b)aab");
    v8_regexp_utils.shouldBe(regex21.firstMatch('aab'), JSArrayOfString().of(['aab']));
    let regex22 = core.RegExp.new("(?!(u|m{0,}g+)u{1,}|2{2,}!1%n|(?!K|(?=y)|(?=ip))+?)(?=(?=(((?:7))*?)*?))p", {multiLine: true});
    v8_regexp_utils.shouldBeNull(regex22.firstMatch('55up'));
    let regex23 = core.RegExp.new("(?=(a)b|c?)()*d");
    v8_regexp_utils.shouldBeNull(regex23.firstMatch('ax'));
    let regex24 = core.RegExp.new("(?=a|b?)c");
    v8_regexp_utils.shouldBeNull(regex24.firstMatch('x'));
  };
  dart.fn(assertion_test.main, VoidTovoid$());
  v8_regexp_utils.assertEquals = function(actual, expected, message) {
    if (message === void 0) message = null;
    expect$.Expect.equals(actual, expected, message);
  };
  dart.fn(v8_regexp_utils.assertEquals, dynamicAnddynamic__Tovoid());
  v8_regexp_utils.assertTrue = function(actual, message) {
    if (message === void 0) message = null;
    expect$.Expect.isTrue(actual, message);
  };
  dart.fn(v8_regexp_utils.assertTrue, dynamic__Tovoid());
  v8_regexp_utils.assertFalse = function(actual, message) {
    if (message === void 0) message = null;
    expect$.Expect.isFalse(actual, message);
  };
  dart.fn(v8_regexp_utils.assertFalse, dynamic__Tovoid());
  v8_regexp_utils.assertThrows = function(fn, testid) {
    if (testid === void 0) testid = null;
    expect$.Expect.throws(VoidTovoid()._check(fn), null, dart.str`Test ${testid}`);
  };
  dart.fn(v8_regexp_utils.assertThrows, dynamic__Tovoid$());
  v8_regexp_utils.assertNull = function(actual, testid) {
    if (testid === void 0) testid = null;
    expect$.Expect.isNull(actual, dart.str`Test ${testid}`);
  };
  dart.fn(v8_regexp_utils.assertNull, dynamic__Tovoid$());
  v8_regexp_utils.assertToStringEquals = function(str, match, testid) {
    let actual = [];
    for (let i = 0; i <= dart.notNull(core.num._check(dart.dload(match, 'groupCount'))); i++) {
      let g = dart.dsend(match, 'group', i);
      actual[dartx.add](g == null ? "" : g);
    }
    expect$.Expect.equals(str, actual[dartx.join](","), dart.str`Test ${testid}`);
  };
  dart.fn(v8_regexp_utils.assertToStringEquals, dynamicAnddynamicAndnumTovoid());
  v8_regexp_utils.shouldBeTrue = function(actual) {
    expect$.Expect.isTrue(actual);
  };
  dart.fn(v8_regexp_utils.shouldBeTrue, dynamicTovoid());
  v8_regexp_utils.shouldBeFalse = function(actual) {
    expect$.Expect.isFalse(actual);
  };
  dart.fn(v8_regexp_utils.shouldBeFalse, dynamicTovoid());
  v8_regexp_utils.shouldBeNull = function(actual) {
    expect$.Expect.isNull(actual);
  };
  dart.fn(v8_regexp_utils.shouldBeNull, dynamicTovoid());
  v8_regexp_utils.shouldBe = function(actual, expected, message) {
    if (message === void 0) message = null;
    if (expected == null) {
      expect$.Expect.isNull(actual, message);
    } else {
      expect$.Expect.equals(dart.dload(expected, 'length'), dart.dsend(dart.dload(actual, 'groupCount'), '+', 1));
      for (let i = 0; i <= dart.notNull(core.num._check(dart.dload(actual, 'groupCount'))); i++) {
        expect$.Expect.equals(dart.dindex(expected, i), dart.dsend(actual, 'group', i), message);
      }
    }
  };
  dart.fn(v8_regexp_utils.shouldBe, dynamicAnddynamic__Tovoid());
  v8_regexp_utils.firstMatch = function(str, pattern) {
    return pattern.firstMatch(str);
  };
  dart.fn(v8_regexp_utils.firstMatch, StringAndRegExpToMatch());
  v8_regexp_utils.allStringMatches = function(str, pattern) {
    return pattern.allMatches(str)[dartx.map](core.String)(dart.fn(m => m.group(0), MatchToString()))[dartx.toList]();
  };
  dart.fn(v8_regexp_utils.allStringMatches, StringAndRegExpToListOfString());
  v8_regexp_utils.description = function(str) {
  };
  dart.fn(v8_regexp_utils.description, dynamicTovoid());
  // Exports:
  exports.assertion_test = assertion_test;
  exports.v8_regexp_utils = v8_regexp_utils;
});
