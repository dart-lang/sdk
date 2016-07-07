dart_library.library('corelib/regexp/char-insensitive_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__char$45insensitive_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const char$45insensitive_test = Object.create(null);
  const v8_regexp_utils = Object.create(null);
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
  char$45insensitive_test.main = function() {
    v8_regexp_utils.description("This test checks the case-insensitive matching of character literals.");
    v8_regexp_utils.shouldBeTrue(core.RegExp.new("\\u00E5", {caseSensitive: false}).hasMatch('new RegExp(r"å")'));
    v8_regexp_utils.shouldBeTrue(core.RegExp.new("\\u00E5", {caseSensitive: false}).hasMatch('new RegExp(r"Å")'));
    v8_regexp_utils.shouldBeTrue(core.RegExp.new("\\u00C5", {caseSensitive: false}).hasMatch('new RegExp(r"å")'));
    v8_regexp_utils.shouldBeTrue(core.RegExp.new("\\u00C5", {caseSensitive: false}).hasMatch('new RegExp(r"Å")'));
    v8_regexp_utils.shouldBeFalse(core.RegExp.new("\\u00E5", {caseSensitive: false}).hasMatch('P'));
    v8_regexp_utils.shouldBeFalse(core.RegExp.new("\\u00E5", {caseSensitive: false}).hasMatch('PASS'));
    v8_regexp_utils.shouldBeFalse(core.RegExp.new("\\u00C5", {caseSensitive: false}).hasMatch('P'));
    v8_regexp_utils.shouldBeFalse(core.RegExp.new("\\u00C5", {caseSensitive: false}).hasMatch('PASS'));
    v8_regexp_utils.shouldBeNull(v8_regexp_utils.firstMatch('PASS', core.RegExp.new("\\u00C5", {caseSensitive: false})));
    v8_regexp_utils.shouldBeNull(v8_regexp_utils.firstMatch('PASS', core.RegExp.new("\\u00C5", {caseSensitive: false})));
    v8_regexp_utils.assertEquals('PASå'[dartx.replaceAll](core.RegExp.new("\\u00E5", {caseSensitive: false}), 'S'), 'PASS');
    v8_regexp_utils.assertEquals('PASå'[dartx.replaceAll](core.RegExp.new("\\u00C5", {caseSensitive: false}), 'S'), 'PASS');
    v8_regexp_utils.assertEquals('PASÅ'[dartx.replaceAll](core.RegExp.new("\\u00E5", {caseSensitive: false}), 'S'), 'PASS');
    v8_regexp_utils.assertEquals('PASÅ'[dartx.replaceAll](core.RegExp.new("\\u00C5", {caseSensitive: false}), 'S'), 'PASS');
    v8_regexp_utils.assertEquals('PASS'[dartx.replaceAll](core.RegExp.new("\\u00E5", {caseSensitive: false}), '%C3%A5'), 'PASS');
    v8_regexp_utils.assertEquals('PASS'[dartx.replaceAll](core.RegExp.new("\\u00C5", {caseSensitive: false}), '%C3%A5'), 'PASS');
  };
  dart.fn(char$45insensitive_test.main, VoidTovoid$());
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
  exports.char$45insensitive_test = char$45insensitive_test;
  exports.v8_regexp_utils = v8_regexp_utils;
});
