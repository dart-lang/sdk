dart_library.library('corelib/regexp/ranges-and-escaped-hyphens_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__ranges$45and$45escaped$45hyphens_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const ranges$45and$45escaped$45hyphens_test = Object.create(null);
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
  ranges$45and$45escaped$45hyphens_test.main = function() {
    v8_regexp_utils.description('Tests for bug <a href="https://bugs.webkit.org/show_bug.cgi?id=21232">#21232</a>, and related range issues described in bug.');
    let regexp01 = core.RegExp.new("[1-35]+").firstMatch("-12354");
    v8_regexp_utils.shouldBe(regexp01, JSArrayOfString().of(["1235"]));
    let regexp01a = core.RegExp.new("[\\s1-35]+").firstMatch("-123 54");
    v8_regexp_utils.shouldBe(regexp01a, JSArrayOfString().of(["123 5"]));
    let regexp01b = core.RegExp.new("[1\\s-35]+").firstMatch("21-3 54");
    v8_regexp_utils.shouldBe(regexp01b, JSArrayOfString().of(["1-3 5"]));
    let regexp01c = core.RegExp.new("[1-\\s35]+").firstMatch("21-3 54");
    v8_regexp_utils.shouldBe(regexp01c, JSArrayOfString().of(["1-3 5"]));
    let regexp01d = core.RegExp.new("[1-3\\s5]+").firstMatch("-123 54");
    v8_regexp_utils.shouldBe(regexp01d, JSArrayOfString().of(["123 5"]));
    let regexp01e = core.RegExp.new("[1-35\\s5]+").firstMatch("-123 54");
    v8_regexp_utils.shouldBe(regexp01e, JSArrayOfString().of(["123 5"]));
    let regexp01f = core.RegExp.new("[-3]+").firstMatch("2-34");
    v8_regexp_utils.shouldBe(regexp01f, JSArrayOfString().of(["-3"]));
    let regexp01g = core.RegExp.new("[2-]+").firstMatch("12-3");
    v8_regexp_utils.shouldBe(regexp01g, JSArrayOfString().of(["2-"]));
    let regexp02 = core.RegExp.new("[1\\-35]+").firstMatch("21-354");
    v8_regexp_utils.shouldBe(regexp02, JSArrayOfString().of(["1-35"]));
    let regexp02a = core.RegExp.new("[\\s1\\-35]+").firstMatch("21-3 54");
    v8_regexp_utils.shouldBe(regexp02a, JSArrayOfString().of(["1-3 5"]));
    let regexp02b = core.RegExp.new("[1\\s\\-35]+").firstMatch("21-3 54");
    v8_regexp_utils.shouldBe(regexp02b, JSArrayOfString().of(["1-3 5"]));
    let regexp02c = core.RegExp.new("[1\\-\\s35]+").firstMatch("21-3 54");
    v8_regexp_utils.shouldBe(regexp02c, JSArrayOfString().of(["1-3 5"]));
    let regexp02d = core.RegExp.new("[1\\-3\\s5]+").firstMatch("21-3 54");
    v8_regexp_utils.shouldBe(regexp02d, JSArrayOfString().of(["1-3 5"]));
    let regexp02e = core.RegExp.new("[1\\-35\\s5]+").firstMatch("21-3 54");
    v8_regexp_utils.shouldBe(regexp02e, JSArrayOfString().of(["1-3 5"]));
    let regexp03a = core.RegExp.new("[\\--0]+").firstMatch(",-.01");
    v8_regexp_utils.shouldBe(regexp03a, JSArrayOfString().of(["-.0"]));
    let regexp03b = core.RegExp.new("[+-\\-]+").firstMatch("*+,-.");
    v8_regexp_utils.shouldBe(regexp03b, JSArrayOfString().of(["+,-"]));
    let bug21232 = core.RegExp.new("^[,:{}\\[\\]0-9.\\-+Eaeflnr-u \\n\\r\\t]*$").hasMatch('@');
    v8_regexp_utils.shouldBeFalse(bug21232);
  };
  dart.fn(ranges$45and$45escaped$45hyphens_test.main, VoidTovoid$());
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
  exports.ranges$45and$45escaped$45hyphens_test = ranges$45and$45escaped$45hyphens_test;
  exports.v8_regexp_utils = v8_regexp_utils;
});
