dart_library.library('corelib/regexp/alternatives_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__alternatives_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const alternatives_test = Object.create(null);
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
  alternatives_test.main = function() {
    v8_regexp_utils.description('Test regular expression processing with alternatives.');
    let s1 = "<p>content</p>";
    v8_regexp_utils.shouldBe(v8_regexp_utils.firstMatch(s1, core.RegExp.new("<((\\\\/([^>]+)>)|(([^>]+)>))")), JSArrayOfString().of(["<p>", "p>", null, null, "p>", "p"]));
    v8_regexp_utils.shouldBe(v8_regexp_utils.firstMatch(s1, core.RegExp.new("<((ABC>)|(\\\\/([^>]+)>)|(([^>]+)>))")), JSArrayOfString().of(["<p>", "p>", null, null, null, "p>", "p"]));
    v8_regexp_utils.shouldBe(v8_regexp_utils.firstMatch(s1, core.RegExp.new("<(a|\\\\/p|.+?)>")), JSArrayOfString().of(["<p>", "p"]));
    v8_regexp_utils.shouldBe(v8_regexp_utils.firstMatch(s1, core.RegExp.new("<((\\\\/([^>]+)>)|((([^>])+)>))")), JSArrayOfString().of(["<p>", "p>", null, null, "p>", "p", "p"]));
    v8_regexp_utils.shouldBe(v8_regexp_utils.firstMatch(s1, core.RegExp.new("<((ABC>)|(\\\\/([^>]+)>)|((([^>])+)>))")), JSArrayOfString().of(["<p>", "p>", null, null, null, "p>", "p", "p"]));
    v8_regexp_utils.shouldBe(v8_regexp_utils.firstMatch(s1, core.RegExp.new("<(a|\\\\/p|(.)+?)>")), JSArrayOfString().of(["<p>", "p", "p"]));
    let s2 = "<p>p</p>";
    v8_regexp_utils.shouldBe(v8_regexp_utils.firstMatch(s2, core.RegExp.new("<((\\\\/([^>]+)>)|(([^>]+)>))\\5")), JSArrayOfString().of(["<p>p", "p>", null, null, "p>", "p"]));
    v8_regexp_utils.shouldBe(v8_regexp_utils.firstMatch(s2, core.RegExp.new("<((ABC>)|(\\\\/([^>]+)>)|(([^>]+)>))\\6")), JSArrayOfString().of(["<p>p", "p>", null, null, null, "p>", "p"]));
    v8_regexp_utils.shouldBe(v8_regexp_utils.firstMatch(s2, core.RegExp.new("<(a|\\\\/p|.+?)>\\1")), JSArrayOfString().of(["<p>p", "p"]));
  };
  dart.fn(alternatives_test.main, VoidTovoid$());
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
  exports.alternatives_test = alternatives_test;
  exports.v8_regexp_utils = v8_regexp_utils;
});
