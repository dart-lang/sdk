dart_library.library('corelib/regexp/unicodeCaseInsensitive_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__unicodeCaseInsensitive_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const unicodeCaseInsensitive_test = Object.create(null);
  const v8_regexp_utils = Object.create(null);
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
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
  unicodeCaseInsensitive_test.main = function() {
    v8_regexp_utils.shouldBeTrue(core.RegExp.new("ΣΤΙΓΜΑΣ", {caseSensitive: false}).hasMatch("στιγμας"));
    v8_regexp_utils.shouldBeTrue(core.RegExp.new("ΔΣΔ", {caseSensitive: false}).hasMatch("δςδ"));
    v8_regexp_utils.shouldBeTrue(core.RegExp.new("ς", {caseSensitive: false}).hasMatch("σ"));
    v8_regexp_utils.shouldBeTrue(core.RegExp.new("σ", {caseSensitive: false}).hasMatch("ς"));
    v8_regexp_utils.shouldBeTrue(core.RegExp.new("\\u1f16", {caseSensitive: false}).hasMatch("἖"));
    function ucs2CodePoint(x) {
      return core.String.fromCharCode(core.int._check(x));
    }
    dart.fn(ucs2CodePoint, dynamicTodynamic());
    function testSet(s) {
      for (let i of core.Iterable._check(s)) {
        for (let j of core.Iterable._check(s)) {
          v8_regexp_utils.shouldBeTrue(core.RegExp.new(core.String._check(ucs2CodePoint(i)), {caseSensitive: false}).hasMatch(core.String._check(ucs2CodePoint(j))));
          v8_regexp_utils.shouldBeTrue(core.RegExp.new(dart.str`[${ucs2CodePoint(dart.dsend(i, '-', 1))}-${ucs2CodePoint(dart.dsend(i, '+', 1))}]`, {caseSensitive: false}).hasMatch(core.String._check(ucs2CodePoint(j))));
        }
      }
    }
    dart.fn(testSet, dynamicTodynamic());
    testSet(JSArrayOfint().of([452, 453, 454]));
    testSet(JSArrayOfint().of([455, 456, 457]));
    testSet(JSArrayOfint().of([458, 459, 460]));
    testSet(JSArrayOfint().of([497, 498, 499]));
    testSet(JSArrayOfint().of([914, 946, 976]));
    testSet(JSArrayOfint().of([917, 949, 1013]));
    testSet(JSArrayOfint().of([920, 952, 977]));
    testSet(JSArrayOfint().of([837, 921, 953, 8126]));
    testSet(JSArrayOfint().of([922, 954, 1008]));
    testSet(JSArrayOfint().of([181, 924, 956]));
    testSet(JSArrayOfint().of([928, 960, 982]));
    testSet(JSArrayOfint().of([929, 961, 1009]));
    testSet(JSArrayOfint().of([931, 962, 963]));
    testSet(JSArrayOfint().of([934, 966, 981]));
    testSet(JSArrayOfint().of([7776, 7777, 7835]));
    v8_regexp_utils.shouldBeTrue(core.RegExp.new("\\u03cf", {caseSensitive: false}).hasMatch("Ϗ"));
    v8_regexp_utils.shouldBeTrue(core.RegExp.new("\\u03d7", {caseSensitive: false}).hasMatch("Ϗ"));
    v8_regexp_utils.shouldBeTrue(core.RegExp.new("\\u03cf", {caseSensitive: false}).hasMatch("ϗ"));
    v8_regexp_utils.shouldBeTrue(core.RegExp.new("\\u03d7", {caseSensitive: false}).hasMatch("ϗ"));
    v8_regexp_utils.shouldBeTrue(core.RegExp.new("\\u1f11", {caseSensitive: false}).hasMatch("ἑ"));
    v8_regexp_utils.shouldBeTrue(core.RegExp.new("\\u1f19", {caseSensitive: false}).hasMatch("ἑ"));
    v8_regexp_utils.shouldBeTrue(core.RegExp.new("\\u1f11", {caseSensitive: false}).hasMatch("Ἑ"));
    v8_regexp_utils.shouldBeTrue(core.RegExp.new("\\u1f19", {caseSensitive: false}).hasMatch("Ἑ"));
    v8_regexp_utils.shouldBeFalse(core.RegExp.new("\\u0489", {caseSensitive: false}).hasMatch("Ҋ"));
    v8_regexp_utils.shouldBeTrue(core.RegExp.new("\\u048a", {caseSensitive: false}).hasMatch("Ҋ"));
    v8_regexp_utils.shouldBeTrue(core.RegExp.new("\\u048b", {caseSensitive: false}).hasMatch("Ҋ"));
    v8_regexp_utils.shouldBeFalse(core.RegExp.new("\\u048c", {caseSensitive: false}).hasMatch("Ҋ"));
    v8_regexp_utils.shouldBeFalse(core.RegExp.new("\\u0489", {caseSensitive: false}).hasMatch("ҋ"));
    v8_regexp_utils.shouldBeTrue(core.RegExp.new("\\u048a", {caseSensitive: false}).hasMatch("ҋ"));
    v8_regexp_utils.shouldBeTrue(core.RegExp.new("\\u048b", {caseSensitive: false}).hasMatch("ҋ"));
    v8_regexp_utils.shouldBeFalse(core.RegExp.new("\\u048c", {caseSensitive: false}).hasMatch("ҋ"));
    v8_regexp_utils.shouldBeTrue(core.RegExp.new("[\\u0489-\\u048a]", {caseSensitive: false}).hasMatch("ҋ"));
    v8_regexp_utils.shouldBeTrue(core.RegExp.new("[\\u048b-\\u048c]", {caseSensitive: false}).hasMatch("Ҋ"));
    v8_regexp_utils.shouldBeFalse(core.RegExp.new("\\u04c4", {caseSensitive: false}).hasMatch("Ӆ"));
    v8_regexp_utils.shouldBeTrue(core.RegExp.new("\\u04c5", {caseSensitive: false}).hasMatch("Ӆ"));
    v8_regexp_utils.shouldBeTrue(core.RegExp.new("\\u04c6", {caseSensitive: false}).hasMatch("Ӆ"));
    v8_regexp_utils.shouldBeFalse(core.RegExp.new("\\u04c7", {caseSensitive: false}).hasMatch("Ӆ"));
    v8_regexp_utils.shouldBeFalse(core.RegExp.new("\\u04c4", {caseSensitive: false}).hasMatch("ӆ"));
    v8_regexp_utils.shouldBeTrue(core.RegExp.new("\\u04c5", {caseSensitive: false}).hasMatch("ӆ"));
    v8_regexp_utils.shouldBeTrue(core.RegExp.new("\\u04c6", {caseSensitive: false}).hasMatch("ӆ"));
    v8_regexp_utils.shouldBeFalse(core.RegExp.new("\\u04c7", {caseSensitive: false}).hasMatch("ӆ"));
    v8_regexp_utils.shouldBeTrue(core.RegExp.new("[\\u04c4-\\u04c5]", {caseSensitive: false}).hasMatch("ӆ"));
    v8_regexp_utils.shouldBeTrue(core.RegExp.new("[\\u04c6-\\u04c7]", {caseSensitive: false}).hasMatch("Ӆ"));
    let successfullyParsed = true;
  };
  dart.fn(unicodeCaseInsensitive_test.main, VoidTovoid$());
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
  exports.unicodeCaseInsensitive_test = unicodeCaseInsensitive_test;
  exports.v8_regexp_utils = v8_regexp_utils;
});
