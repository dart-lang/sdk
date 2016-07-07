dart_library.library('corelib/regexp/capture-3_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__capture$453_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const capture$453_test = Object.create(null);
  const v8_regexp_utils = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.functionType(dart.void, [])))();
  let ListOfString = () => (ListOfString = dart.constFn(core.List$(core.String)))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTovoid$ = () => (VoidTovoid$ = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicAnddynamic__Tovoid = () => (dynamicAnddynamic__Tovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic], [core.String])))();
  let dynamic__Tovoid = () => (dynamic__Tovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic], [core.String])))();
  let dynamic__Tovoid$ = () => (dynamic__Tovoid$ = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic], [core.num])))();
  let dynamicAnddynamicAndnumTovoid = () => (dynamicAnddynamicAndnumTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic, core.num])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  let StringAndRegExpToMatch = () => (StringAndRegExpToMatch = dart.constFn(dart.definiteFunctionType(core.Match, [core.String, core.RegExp])))();
  let MatchToString = () => (MatchToString = dart.constFn(dart.definiteFunctionType(core.String, [core.Match])))();
  let StringAndRegExpToListOfString = () => (StringAndRegExpToListOfString = dart.constFn(dart.definiteFunctionType(ListOfString(), [core.String, core.RegExp])))();
  capture$453_test.main = function() {
    function oneMatch(re) {
      v8_regexp_utils.assertEquals("acd", "abcd"[dartx.replaceAll](core.Pattern._check(re), ""));
    }
    dart.fn(oneMatch, dynamicTodynamic());
    oneMatch(core.RegExp.new("b"));
    oneMatch(core.RegExp.new("b"));
    v8_regexp_utils.assertEquals("acdacd", "abcdabcd"[dartx.replaceAll](core.RegExp.new("b"), ""));
    function captureMatch(re) {
      let match = v8_regexp_utils.firstMatch("abcd", core.RegExp._check(re));
      v8_regexp_utils.assertEquals("b", match.group(1));
      v8_regexp_utils.assertEquals("c", match.group(2));
    }
    dart.fn(captureMatch, dynamicTodynamic());
    captureMatch(core.RegExp.new("(b)(c)"));
    captureMatch(core.RegExp.new("(b)(c)"));
    let a = "foo bar baz"[dartx.replaceAll](core.RegExp.new("^|bar"), "");
    v8_regexp_utils.assertEquals("foo  baz", a);
    a = "foo bar baz"[dartx.replaceAll](core.RegExp.new("^|bar"), "*");
    v8_regexp_utils.assertEquals("*foo * baz", a);
    function NoHang(re) {
      v8_regexp_utils.firstMatch("This is an ASCII string that could take forever", core.RegExp._check(re));
    }
    dart.fn(NoHang, dynamicTodynamic());
    NoHang(core.RegExp.new("(((.*)*)*x)Ā"));
    NoHang(core.RegExp.new("(((.*)*)*Ā)foo"));
    NoHang(core.RegExp.new("Ā(((.*)*)*x)"));
    NoHang(core.RegExp.new("(((.*)*)*x)Ā"));
    NoHang(core.RegExp.new("[ćăĀ](((.*)*)*x)"));
    NoHang(core.RegExp.new("(((.*)*)*x)[ćăĀ]"));
    NoHang(core.RegExp.new("[^\\x00-\\xff](((.*)*)*x)"));
    NoHang(core.RegExp.new("(((.*)*)*x)[^\\x00-\\xff]"));
    NoHang(core.RegExp.new("(?!(((.*)*)*x)Ā)foo"));
    NoHang(core.RegExp.new("(?!(((.*)*)*x))Ā"));
    NoHang(core.RegExp.new("(?=(((.*)*)*x)Ā)foo"));
    NoHang(core.RegExp.new("(?=(((.*)*)*x))Ā"));
    NoHang(core.RegExp.new("(?=Ā)(((.*)*)*x)"));
    NoHang(core.RegExp.new("(æ|ø|Ā)(((.*)*)*x)"));
    NoHang(core.RegExp.new("(a|b|(((.*)*)*x))Ā"));
    NoHang(core.RegExp.new("(a|(((.*)*)*x)ă|(((.*)*)*x)Ā)"));
    let s = "Don't prune based on a repetition of length 0";
    v8_regexp_utils.assertEquals(null, v8_regexp_utils.firstMatch(s, core.RegExp.new("å{1,1}prune")));
    v8_regexp_utils.assertEquals("prune", v8_regexp_utils.firstMatch(s, core.RegExp.new("å{0,0}prune")).get(0));
    let regex6 = core.RegExp.new("a*\\u0100*\\w");
    let input0 = "a";
    regex6.firstMatch(input0);
    let re = "Ā*\\w";
    for (let i = 0; i < 200; i++)
      re = "a*" + re;
    let regex7 = core.RegExp.new(re);
    regex7.firstMatch(input0);
    let regex8 = core.RegExp.new(re, {caseSensitive: false});
    regex8.firstMatch(input0);
    re = "[Ā]*\\w";
    for (let i = 0; i < 200; i++)
      re = "a*" + re;
    let regex9 = core.RegExp.new(re);
    regex9.firstMatch(input0);
    let regex10 = core.RegExp.new(re, {caseSensitive: false});
    regex10.firstMatch(input0);
    let regex11 = core.RegExp.new("^(?:[^\\u0000-\\u0080]|[0-9a-z?,.!&\\s#()])+$", {caseSensitive: false});
    regex11.firstMatch(input0);
    let regex12 = core.RegExp.new("u(\\xf0{8}?\\D*?|( ? !)$h??(|)*?(||)+?\\6((?:\\W\\B|--\\d-*-|)?$){0, }?|^Y( ? !1)\\d+)+a");
    regex12.firstMatch("");
  };
  dart.fn(capture$453_test.main, VoidTovoid$());
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
  exports.capture$453_test = capture$453_test;
  exports.v8_regexp_utils = v8_regexp_utils;
});
