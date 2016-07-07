dart_library.library('corelib/regexp/dotstar_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__dotstar_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const dotstar_test = Object.create(null);
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
  dotstar_test.main = function() {
    v8_regexp_utils.description("This page tests handling of parentheses subexpressions.");
    let regexp1 = core.RegExp.new(".*blah.*");
    v8_regexp_utils.shouldBeNull(regexp1.firstMatch('test'));
    v8_regexp_utils.shouldBe(regexp1.firstMatch('blah'), JSArrayOfString().of(['blah']));
    v8_regexp_utils.shouldBe(regexp1.firstMatch('1blah'), JSArrayOfString().of(['1blah']));
    v8_regexp_utils.shouldBe(regexp1.firstMatch('blah1'), JSArrayOfString().of(['blah1']));
    v8_regexp_utils.shouldBe(regexp1.firstMatch('blah blah blah'), JSArrayOfString().of(['blah blah blah']));
    v8_regexp_utils.shouldBe(regexp1.firstMatch('blah\nsecond'), JSArrayOfString().of(['blah']));
    v8_regexp_utils.shouldBe(regexp1.firstMatch('first\nblah'), JSArrayOfString().of(['blah']));
    v8_regexp_utils.shouldBe(regexp1.firstMatch('first\nblah\nthird'), JSArrayOfString().of(['blah']));
    v8_regexp_utils.shouldBe(regexp1.firstMatch('first\nblah2\nblah3'), JSArrayOfString().of(['blah2']));
    let regexp2 = core.RegExp.new("^.*blah.*");
    v8_regexp_utils.shouldBeNull(regexp2.firstMatch('test'));
    v8_regexp_utils.shouldBe(regexp2.firstMatch('blah'), JSArrayOfString().of(['blah']));
    v8_regexp_utils.shouldBe(regexp2.firstMatch('1blah'), JSArrayOfString().of(['1blah']));
    v8_regexp_utils.shouldBe(regexp2.firstMatch('blah1'), JSArrayOfString().of(['blah1']));
    v8_regexp_utils.shouldBe(regexp2.firstMatch('blah blah blah'), JSArrayOfString().of(['blah blah blah']));
    v8_regexp_utils.shouldBe(regexp2.firstMatch('blah\nsecond'), JSArrayOfString().of(['blah']));
    v8_regexp_utils.shouldBeNull(regexp2.firstMatch('first\nblah'));
    v8_regexp_utils.shouldBeNull(regexp2.firstMatch('first\nblah\nthird'));
    v8_regexp_utils.shouldBeNull(regexp2.firstMatch('first\nblah2\nblah3'));
    let regexp3 = core.RegExp.new(".*blah.*$");
    v8_regexp_utils.shouldBeNull(regexp3.firstMatch('test'));
    v8_regexp_utils.shouldBe(regexp3.firstMatch('blah'), JSArrayOfString().of(['blah']));
    v8_regexp_utils.shouldBe(regexp3.firstMatch('1blah'), JSArrayOfString().of(['1blah']));
    v8_regexp_utils.shouldBe(regexp3.firstMatch('blah1'), JSArrayOfString().of(['blah1']));
    v8_regexp_utils.shouldBe(regexp3.firstMatch('blah blah blah'), JSArrayOfString().of(['blah blah blah']));
    v8_regexp_utils.shouldBeNull(regexp3.firstMatch('blah\nsecond'));
    v8_regexp_utils.shouldBe(regexp3.firstMatch('first\nblah'), JSArrayOfString().of(['blah']));
    v8_regexp_utils.shouldBeNull(regexp3.firstMatch('first\nblah\nthird'));
    v8_regexp_utils.shouldBe(regexp3.firstMatch('first\nblah2\nblah3'), JSArrayOfString().of(['blah3']));
    let regexp4 = core.RegExp.new("^.*blah.*$");
    v8_regexp_utils.shouldBeNull(regexp4.firstMatch('test'));
    v8_regexp_utils.shouldBe(regexp4.firstMatch('blah'), JSArrayOfString().of(['blah']));
    v8_regexp_utils.shouldBe(regexp4.firstMatch('1blah'), JSArrayOfString().of(['1blah']));
    v8_regexp_utils.shouldBe(regexp4.firstMatch('blah1'), JSArrayOfString().of(['blah1']));
    v8_regexp_utils.shouldBe(regexp4.firstMatch('blah blah blah'), JSArrayOfString().of(['blah blah blah']));
    v8_regexp_utils.shouldBeNull(regexp4.firstMatch('blah\nsecond'));
    v8_regexp_utils.shouldBeNull(regexp4.firstMatch('first\nblah'));
    v8_regexp_utils.shouldBeNull(regexp4.firstMatch('first\nblah\nthird'));
    v8_regexp_utils.shouldBeNull(regexp4.firstMatch('first\nblah2\nblah3'));
    let regexp5 = core.RegExp.new(".*?blah.*");
    v8_regexp_utils.shouldBeNull(regexp5.firstMatch('test'));
    v8_regexp_utils.shouldBe(regexp5.firstMatch('blah'), JSArrayOfString().of(['blah']));
    v8_regexp_utils.shouldBe(regexp5.firstMatch('1blah'), JSArrayOfString().of(['1blah']));
    v8_regexp_utils.shouldBe(regexp5.firstMatch('blah1'), JSArrayOfString().of(['blah1']));
    v8_regexp_utils.shouldBe(regexp5.firstMatch('blah blah blah'), JSArrayOfString().of(['blah blah blah']));
    v8_regexp_utils.shouldBe(regexp5.firstMatch('blah\nsecond'), JSArrayOfString().of(['blah']));
    v8_regexp_utils.shouldBe(regexp5.firstMatch('first\nblah'), JSArrayOfString().of(['blah']));
    v8_regexp_utils.shouldBe(regexp5.firstMatch('first\nblah\nthird'), JSArrayOfString().of(['blah']));
    v8_regexp_utils.shouldBe(regexp5.firstMatch('first\nblah2\nblah3'), JSArrayOfString().of(['blah2']));
    let regexp6 = core.RegExp.new(".*blah.*?");
    v8_regexp_utils.shouldBeNull(regexp6.firstMatch('test'));
    v8_regexp_utils.shouldBe(regexp6.firstMatch('blah'), JSArrayOfString().of(['blah']));
    v8_regexp_utils.shouldBe(regexp6.firstMatch('1blah'), JSArrayOfString().of(['1blah']));
    v8_regexp_utils.shouldBe(regexp6.firstMatch('blah1'), JSArrayOfString().of(['blah']));
    v8_regexp_utils.shouldBe(regexp6.firstMatch('blah blah blah'), JSArrayOfString().of(['blah blah blah']));
    v8_regexp_utils.shouldBe(regexp6.firstMatch('blah\nsecond'), JSArrayOfString().of(['blah']));
    v8_regexp_utils.shouldBe(regexp6.firstMatch('first\nblah'), JSArrayOfString().of(['blah']));
    v8_regexp_utils.shouldBe(regexp6.firstMatch('first\nblah\nthird'), JSArrayOfString().of(['blah']));
    v8_regexp_utils.shouldBe(regexp6.firstMatch('first\nblah2\nblah3'), JSArrayOfString().of(['blah']));
    let regexp7 = core.RegExp.new("^.*?blah.*?$");
    v8_regexp_utils.shouldBeNull(regexp7.firstMatch('test'));
    v8_regexp_utils.shouldBe(regexp7.firstMatch('blah'), JSArrayOfString().of(['blah']));
    v8_regexp_utils.shouldBe(regexp7.firstMatch('1blah'), JSArrayOfString().of(['1blah']));
    v8_regexp_utils.shouldBe(regexp7.firstMatch('blah1'), JSArrayOfString().of(['blah1']));
    v8_regexp_utils.shouldBe(regexp7.firstMatch('blah blah blah'), JSArrayOfString().of(['blah blah blah']));
    v8_regexp_utils.shouldBeNull(regexp7.firstMatch('blah\nsecond'));
    v8_regexp_utils.shouldBeNull(regexp7.firstMatch('first\nblah'));
    v8_regexp_utils.shouldBeNull(regexp7.firstMatch('first\nblah\nthird'));
    v8_regexp_utils.shouldBeNull(regexp7.firstMatch('first\nblah2\nblah3'));
    let regexp8 = core.RegExp.new("^(.*)blah.*$");
    v8_regexp_utils.shouldBeNull(regexp8.firstMatch('test'));
    v8_regexp_utils.shouldBe(regexp8.firstMatch('blah'), JSArrayOfString().of(['blah', '']));
    v8_regexp_utils.shouldBe(regexp8.firstMatch('1blah'), JSArrayOfString().of(['1blah', '1']));
    v8_regexp_utils.shouldBe(regexp8.firstMatch('blah1'), JSArrayOfString().of(['blah1', '']));
    v8_regexp_utils.shouldBe(regexp8.firstMatch('blah blah blah'), JSArrayOfString().of(['blah blah blah', 'blah blah ']));
    v8_regexp_utils.shouldBeNull(regexp8.firstMatch('blah\nsecond'));
    v8_regexp_utils.shouldBeNull(regexp8.firstMatch('first\nblah'));
    v8_regexp_utils.shouldBeNull(regexp8.firstMatch('first\nblah\nthird'));
    v8_regexp_utils.shouldBeNull(regexp8.firstMatch('first\nblah2\nblah3'));
    let regexp9 = core.RegExp.new(".*blah.*", {multiLine: true});
    v8_regexp_utils.shouldBeNull(regexp9.firstMatch('test'));
    v8_regexp_utils.shouldBe(regexp9.firstMatch('blah'), JSArrayOfString().of(['blah']));
    v8_regexp_utils.shouldBe(regexp9.firstMatch('1blah'), JSArrayOfString().of(['1blah']));
    v8_regexp_utils.shouldBe(regexp9.firstMatch('blah1'), JSArrayOfString().of(['blah1']));
    v8_regexp_utils.shouldBe(regexp9.firstMatch('blah blah blah'), JSArrayOfString().of(['blah blah blah']));
    v8_regexp_utils.shouldBe(regexp9.firstMatch('blah\nsecond'), JSArrayOfString().of(['blah']));
    v8_regexp_utils.shouldBe(regexp9.firstMatch('first\nblah'), JSArrayOfString().of(['blah']));
    v8_regexp_utils.shouldBe(regexp9.firstMatch('first\nblah\nthird'), JSArrayOfString().of(['blah']));
    v8_regexp_utils.shouldBe(regexp9.firstMatch('first\nblah2\nblah3'), JSArrayOfString().of(['blah2']));
    let regexp10 = core.RegExp.new("^.*blah.*", {multiLine: true});
    v8_regexp_utils.shouldBeNull(regexp10.firstMatch('test'));
    v8_regexp_utils.shouldBe(regexp10.firstMatch('blah'), JSArrayOfString().of(['blah']));
    v8_regexp_utils.shouldBe(regexp10.firstMatch('1blah'), JSArrayOfString().of(['1blah']));
    v8_regexp_utils.shouldBe(regexp10.firstMatch('blah1'), JSArrayOfString().of(['blah1']));
    v8_regexp_utils.shouldBe(regexp10.firstMatch('blah blah blah'), JSArrayOfString().of(['blah blah blah']));
    v8_regexp_utils.shouldBe(regexp10.firstMatch('blah\nsecond'), JSArrayOfString().of(['blah']));
    v8_regexp_utils.shouldBe(regexp10.firstMatch('first\nblah'), JSArrayOfString().of(['blah']));
    v8_regexp_utils.shouldBe(regexp10.firstMatch('first\nblah\nthird'), JSArrayOfString().of(['blah']));
    v8_regexp_utils.shouldBe(regexp10.firstMatch('first\nblah2\nblah3'), JSArrayOfString().of(['blah2']));
    let regexp11 = core.RegExp.new(".*(?:blah).*$");
    v8_regexp_utils.shouldBeNull(regexp11.firstMatch('test'));
    v8_regexp_utils.shouldBe(regexp11.firstMatch('blah'), JSArrayOfString().of(['blah']));
    v8_regexp_utils.shouldBe(regexp11.firstMatch('1blah'), JSArrayOfString().of(['1blah']));
    v8_regexp_utils.shouldBe(regexp11.firstMatch('blah1'), JSArrayOfString().of(['blah1']));
    v8_regexp_utils.shouldBe(regexp11.firstMatch('blah blah blah'), JSArrayOfString().of(['blah blah blah']));
    v8_regexp_utils.shouldBeNull(regexp11.firstMatch('blah\nsecond'));
    v8_regexp_utils.shouldBe(regexp11.firstMatch('first\nblah'), JSArrayOfString().of(['blah']));
    v8_regexp_utils.shouldBeNull(regexp11.firstMatch('first\nblah\nthird'));
    v8_regexp_utils.shouldBe(regexp11.firstMatch('first\nblah2\nblah3'), JSArrayOfString().of(['blah3']));
    let regexp12 = core.RegExp.new(".*(?:blah|buzz|bang).*$");
    v8_regexp_utils.shouldBeNull(regexp12.firstMatch('test'));
    v8_regexp_utils.shouldBe(regexp12.firstMatch('blah'), JSArrayOfString().of(['blah']));
    v8_regexp_utils.shouldBe(regexp12.firstMatch('1blah'), JSArrayOfString().of(['1blah']));
    v8_regexp_utils.shouldBe(regexp12.firstMatch('blah1'), JSArrayOfString().of(['blah1']));
    v8_regexp_utils.shouldBe(regexp12.firstMatch('blah blah blah'), JSArrayOfString().of(['blah blah blah']));
    v8_regexp_utils.shouldBeNull(regexp12.firstMatch('blah\nsecond'));
    v8_regexp_utils.shouldBe(regexp12.firstMatch('first\nblah'), JSArrayOfString().of(['blah']));
    v8_regexp_utils.shouldBeNull(regexp12.firstMatch('first\nblah\nthird'));
    v8_regexp_utils.shouldBe(regexp12.firstMatch('first\nblah2\nblah3'), JSArrayOfString().of(['blah3']));
    let regexp13 = core.RegExp.new(".*\\n\\d+.*");
    v8_regexp_utils.shouldBe(regexp13.firstMatch('abc\n123'), JSArrayOfString().of(['abc\n123']));
  };
  dart.fn(dotstar_test.main, VoidTovoid$());
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
  exports.dotstar_test = dotstar_test;
  exports.v8_regexp_utils = v8_regexp_utils;
});
