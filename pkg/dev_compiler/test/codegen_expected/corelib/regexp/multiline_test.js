dart_library.library('corelib/regexp/multiline_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__multiline_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const multiline_test = Object.create(null);
  const v8_regexp_utils = Object.create(null);
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.functionType(dart.void, [])))();
  let ListOfString = () => (ListOfString = dart.constFn(core.List$(core.String)))();
  let dynamicAnddynamicTodynamic = () => (dynamicAnddynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic])))();
  let VoidToRegExp = () => (VoidToRegExp = dart.constFn(dart.definiteFunctionType(core.RegExp, [])))();
  let VoidTovoid$ = () => (VoidTovoid$ = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicAnddynamic__Tovoid = () => (dynamicAnddynamic__Tovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic], [core.String])))();
  let dynamic__Tovoid = () => (dynamic__Tovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic], [core.String])))();
  let dynamic__Tovoid$ = () => (dynamic__Tovoid$ = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic], [core.num])))();
  let dynamicAnddynamicAndnumTovoid = () => (dynamicAnddynamicAndnumTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic, core.num])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  let StringAndRegExpToMatch = () => (StringAndRegExpToMatch = dart.constFn(dart.definiteFunctionType(core.Match, [core.String, core.RegExp])))();
  let MatchToString = () => (MatchToString = dart.constFn(dart.definiteFunctionType(core.String, [core.Match])))();
  let StringAndRegExpToListOfString = () => (StringAndRegExpToListOfString = dart.constFn(dart.definiteFunctionType(ListOfString(), [core.String, core.RegExp])))();
  multiline_test.main = function() {
    v8_regexp_utils.assertTrue(core.RegExp.new("^bar").hasMatch("bar"));
    v8_regexp_utils.assertTrue(core.RegExp.new("^bar").hasMatch("bar\nfoo"));
    v8_regexp_utils.assertFalse(core.RegExp.new("^bar").hasMatch("foo\nbar"));
    v8_regexp_utils.assertTrue(core.RegExp.new("^bar", {multiLine: true}).hasMatch("bar"));
    v8_regexp_utils.assertTrue(core.RegExp.new("^bar", {multiLine: true}).hasMatch("bar\nfoo"));
    v8_regexp_utils.assertTrue(core.RegExp.new("^bar", {multiLine: true}).hasMatch("foo\nbar"));
    v8_regexp_utils.assertTrue(core.RegExp.new("bar$").hasMatch("bar"));
    v8_regexp_utils.assertFalse(core.RegExp.new("bar$").hasMatch("bar\nfoo"));
    v8_regexp_utils.assertTrue(core.RegExp.new("bar$").hasMatch("foo\nbar"));
    v8_regexp_utils.assertTrue(core.RegExp.new("bar$", {multiLine: true}).hasMatch("bar"));
    v8_regexp_utils.assertTrue(core.RegExp.new("bar$", {multiLine: true}).hasMatch("bar\nfoo"));
    v8_regexp_utils.assertTrue(core.RegExp.new("bar$", {multiLine: true}).hasMatch("foo\nbar"));
    v8_regexp_utils.assertFalse(core.RegExp.new("^bxr").hasMatch("bar"));
    v8_regexp_utils.assertFalse(core.RegExp.new("^bxr").hasMatch("bar\nfoo"));
    v8_regexp_utils.assertFalse(core.RegExp.new("^bxr", {multiLine: true}).hasMatch("bar"));
    v8_regexp_utils.assertFalse(core.RegExp.new("^bxr", {multiLine: true}).hasMatch("bar\nfoo"));
    v8_regexp_utils.assertFalse(core.RegExp.new("^bxr", {multiLine: true}).hasMatch("foo\nbar"));
    v8_regexp_utils.assertFalse(core.RegExp.new("bxr$").hasMatch("bar"));
    v8_regexp_utils.assertFalse(core.RegExp.new("bxr$").hasMatch("foo\nbar"));
    v8_regexp_utils.assertFalse(core.RegExp.new("bxr$", {multiLine: true}).hasMatch("bar"));
    v8_regexp_utils.assertFalse(core.RegExp.new("bxr$", {multiLine: true}).hasMatch("bar\nfoo"));
    v8_regexp_utils.assertFalse(core.RegExp.new("bxr$", {multiLine: true}).hasMatch("foo\nbar"));
    v8_regexp_utils.assertTrue(core.RegExp.new("^.*$").hasMatch(""));
    v8_regexp_utils.assertTrue(core.RegExp.new("^.*$").hasMatch("foo"));
    v8_regexp_utils.assertFalse(core.RegExp.new("^.*$").hasMatch("\n"));
    v8_regexp_utils.assertTrue(core.RegExp.new("^.*$", {multiLine: true}).hasMatch("\n"));
    v8_regexp_utils.assertTrue(core.RegExp.new("^[\\s]*$").hasMatch(" "));
    v8_regexp_utils.assertTrue(core.RegExp.new("^[\\s]*$").hasMatch("\n"));
    v8_regexp_utils.assertTrue(core.RegExp.new("^[^]*$").hasMatch(""));
    v8_regexp_utils.assertTrue(core.RegExp.new("^[^]*$").hasMatch("foo"));
    v8_regexp_utils.assertTrue(core.RegExp.new("^[^]*$").hasMatch("\n"));
    v8_regexp_utils.assertTrue(core.RegExp.new("^([()\\s]|.)*$").hasMatch("()\n()"));
    v8_regexp_utils.assertTrue(core.RegExp.new("^([()\\n]|.)*$").hasMatch("()\n()"));
    v8_regexp_utils.assertFalse(core.RegExp.new("^([()]|.)*$").hasMatch("()\n()"));
    v8_regexp_utils.assertTrue(core.RegExp.new("^([()]|.)*$", {multiLine: true}).hasMatch("()\n()"));
    v8_regexp_utils.assertTrue(core.RegExp.new("^([()]|.)*$", {multiLine: true}).hasMatch("()\n"));
    v8_regexp_utils.assertTrue(core.RegExp.new("^[()]*$", {multiLine: true}).hasMatch("()\n."));
    v8_regexp_utils.assertTrue(core.RegExp.new("^[\\].]*$").hasMatch("...]..."));
    function check_case(lc, uc) {
      let a = core.RegExp.new("^" + dart.notNull(core.String._check(lc)) + "$");
      v8_regexp_utils.assertFalse(a.hasMatch(core.String._check(uc)));
      a = core.RegExp.new("^" + dart.notNull(core.String._check(lc)) + "$", {caseSensitive: false});
      v8_regexp_utils.assertTrue(a.hasMatch(core.String._check(uc)));
      let A = core.RegExp.new("^" + dart.notNull(core.String._check(uc)) + "$");
      v8_regexp_utils.assertFalse(A.hasMatch(core.String._check(lc)));
      A = core.RegExp.new("^" + dart.notNull(core.String._check(uc)) + "$", {caseSensitive: false});
      v8_regexp_utils.assertTrue(A.hasMatch(core.String._check(lc)));
      a = core.RegExp.new("^[" + dart.notNull(core.String._check(lc)) + "]$");
      v8_regexp_utils.assertFalse(a.hasMatch(core.String._check(uc)));
      a = core.RegExp.new("^[" + dart.notNull(core.String._check(lc)) + "]$", {caseSensitive: false});
      v8_regexp_utils.assertTrue(a.hasMatch(core.String._check(uc)));
      A = core.RegExp.new("^[" + dart.notNull(core.String._check(uc)) + "]$");
      v8_regexp_utils.assertFalse(A.hasMatch(core.String._check(lc)));
      A = core.RegExp.new("^[" + dart.notNull(core.String._check(uc)) + "]$", {caseSensitive: false});
      v8_regexp_utils.assertTrue(A.hasMatch(core.String._check(lc)));
    }
    dart.fn(check_case, dynamicAnddynamicTodynamic());
    check_case("a", "A");
    check_case(core.String.fromCharCode(229), core.String.fromCharCode(197));
    check_case(core.String.fromCharCode(1043), core.String.fromCharCode(1075));
    v8_regexp_utils.assertThrows(dart.fn(() => core.RegExp.new('[z-a]'), VoidToRegExp()));
  };
  dart.fn(multiline_test.main, VoidTovoid$());
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
  exports.multiline_test = multiline_test;
  exports.v8_regexp_utils = v8_regexp_utils;
});
