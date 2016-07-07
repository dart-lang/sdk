dart_library.library('corelib/regexp/lookahead_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__lookahead_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const lookahead_test = Object.create(null);
  const v8_regexp_utils = Object.create(null);
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.functionType(dart.void, [])))();
  let ListOfString = () => (ListOfString = dart.constFn(core.List$(core.String)))();
  let dynamicAnddynamicAnddynamicTodynamic = () => (dynamicAnddynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic])))();
  let VoidTovoid$ = () => (VoidTovoid$ = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicAnddynamic__Tovoid = () => (dynamicAnddynamic__Tovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic], [core.String])))();
  let dynamic__Tovoid = () => (dynamic__Tovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic], [core.String])))();
  let dynamic__Tovoid$ = () => (dynamic__Tovoid$ = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic], [core.num])))();
  let dynamicAnddynamicAndnumTovoid = () => (dynamicAnddynamicAndnumTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic, core.num])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  let StringAndRegExpToMatch = () => (StringAndRegExpToMatch = dart.constFn(dart.definiteFunctionType(core.Match, [core.String, core.RegExp])))();
  let MatchToString = () => (MatchToString = dart.constFn(dart.definiteFunctionType(core.String, [core.Match])))();
  let StringAndRegExpToListOfString = () => (StringAndRegExpToListOfString = dart.constFn(dart.definiteFunctionType(ListOfString(), [core.String, core.RegExp])))();
  lookahead_test.main = function() {
    function testRE(re, input, expected_result) {
      if (dart.test(expected_result)) {
        v8_regexp_utils.assertTrue(dart.dsend(re, 'hasMatch', input));
      } else {
        v8_regexp_utils.assertFalse(dart.dsend(re, 'hasMatch', input));
      }
    }
    dart.fn(testRE, dynamicAnddynamicAnddynamicTodynamic());
    function execRE(re, input, expected_result) {
      v8_regexp_utils.shouldBe(dart.dsend(re, 'firstMatch', input), expected_result);
    }
    dart.fn(execRE, dynamicAnddynamicAnddynamicTodynamic());
    let re = core.RegExp.new("^(?=a)");
    testRE(re, "a", true);
    testRE(re, "b", false);
    execRE(re, "a", JSArrayOfString().of([""]));
    re = core.RegExp.new("^(?=\\woo)f\\w");
    testRE(re, "foo", true);
    testRE(re, "boo", false);
    testRE(re, "fao", false);
    testRE(re, "foa", false);
    execRE(re, "foo", JSArrayOfString().of(["fo"]));
    re = core.RegExp.new("(?=\\w).(?=\\W)");
    testRE(re, ".a! ", true);
    testRE(re, ".! ", false);
    testRE(re, ".ab! ", true);
    execRE(re, ".ab! ", JSArrayOfString().of(["b"]));
    re = core.RegExp.new("(?=f(?=[^f]o))..");
    testRE(re, ", foo!", true);
    testRE(re, ", fo!", false);
    testRE(re, ", ffo", false);
    execRE(re, ", foo!", JSArrayOfString().of(["fo"]));
    re = core.RegExp.new("^[^'\"]*(?=(['\"])).*\\1(\\w+)\\1");
    testRE(re, "  'foo' ", true);
    testRE(re, '  "foo" ', true);
    testRE(re, " \" 'foo' ", false);
    testRE(re, " ' \"foo\" ", false);
    testRE(re, "  'foo\" ", false);
    testRE(re, "  \"foo' ", false);
    execRE(re, "  'foo' ", JSArrayOfString().of(["  'foo'", "'", "foo"]));
    execRE(re, '  "foo" ', JSArrayOfString().of(['  "foo"', '"', 'foo']));
    re = core.RegExp.new("^(?:(?=(.))a|b)\\1$");
    testRE(re, "aa", true);
    testRE(re, "b", true);
    testRE(re, "bb", false);
    testRE(re, "a", false);
    execRE(re, "aa", JSArrayOfString().of(["aa", "a"]));
    execRE(re, "b", JSArrayOfString().of(["b", null]));
    re = core.RegExp.new("^(?=(.)(?=(.)\\1\\2)\\2\\1)\\1\\2");
    testRE(re, "abab", true);
    testRE(re, "ababxxxxxxxx", true);
    testRE(re, "aba", false);
    execRE(re, "abab", JSArrayOfString().of(["ab", "a", "b"]));
    re = core.RegExp.new("^(?:(?=(.))a|b|c)$");
    testRE(re, "a", true);
    testRE(re, "b", true);
    testRE(re, "c", true);
    testRE(re, "d", false);
    execRE(re, "a", JSArrayOfString().of(["a", "a"]));
    execRE(re, "b", JSArrayOfString().of(["b", null]));
    execRE(re, "c", JSArrayOfString().of(["c", null]));
    execRE(core.RegExp.new("^(?=(b))b"), "b", JSArrayOfString().of(["b", "b"]));
    execRE(core.RegExp.new("^(?:(?=(b))|a)b"), "ab", JSArrayOfString().of(["ab", null]));
    execRE(core.RegExp.new("^(?:(?=(b)(?:(?=(c))|d))|)bd"), "bd", JSArrayOfString().of(["bd", "b", null]));
    re = core.RegExp.new("(?!x).");
    testRE(re, "y", true);
    testRE(re, "x", false);
    execRE(re, "y", JSArrayOfString().of(["y"]));
    re = core.RegExp.new("(?!(\\d))|\\d");
    testRE(re, "4", true);
    execRE(re, "4", JSArrayOfString().of(["4", null]));
    execRE(re, "x", JSArrayOfString().of(["", null]));
    re = core.RegExp.new("^(?=(x)(?=(y)))");
    testRE(re, "xy", true);
    testRE(re, "xz", false);
    execRE(re, "xy", JSArrayOfString().of(["", "x", "y"]));
    re = core.RegExp.new("^(?!(x)(?!(y)))");
    testRE(re, "xy", true);
    testRE(re, "xz", false);
    execRE(re, "xy", JSArrayOfString().of(["", null, null]));
    re = core.RegExp.new("^(?=(x)(?!(y)))");
    testRE(re, "xz", true);
    testRE(re, "xy", false);
    execRE(re, "xz", JSArrayOfString().of(["", "x", null]));
    re = core.RegExp.new("^(?!(x)(?=(y)))");
    testRE(re, "xz", true);
    testRE(re, "xy", false);
    execRE(re, "xz", JSArrayOfString().of(["", null, null]));
    re = core.RegExp.new("^(?=(x)(?!(y)(?=(z))))");
    testRE(re, "xaz", true);
    testRE(re, "xya", true);
    testRE(re, "xyz", false);
    testRE(re, "a", false);
    execRE(re, "xaz", JSArrayOfString().of(["", "x", null, null]));
    execRE(re, "xya", JSArrayOfString().of(["", "x", null, null]));
    re = core.RegExp.new("^(?!(x)(?=(y)(?!(z))))");
    testRE(re, "a", true);
    testRE(re, "xa", true);
    testRE(re, "xyz", true);
    testRE(re, "xya", false);
    execRE(re, "a", JSArrayOfString().of(["", null, null, null]));
    execRE(re, "xa", JSArrayOfString().of(["", null, null, null]));
    execRE(re, "xyz", JSArrayOfString().of(["", null, null, null]));
  };
  dart.fn(lookahead_test.main, VoidTovoid$());
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
  exports.lookahead_test = lookahead_test;
  exports.v8_regexp_utils = v8_regexp_utils;
});
