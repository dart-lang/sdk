dart_library.library('corelib/regexp/regexp_kde_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__regexp_kde_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const regexp_kde_test = Object.create(null);
  const v8_regexp_utils = Object.create(null);
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.functionType(dart.void, [])))();
  let ListOfString = () => (ListOfString = dart.constFn(core.List$(core.String)))();
  let MatchToString = () => (MatchToString = dart.constFn(dart.definiteFunctionType(core.String, [core.Match])))();
  let VoidTovoid$ = () => (VoidTovoid$ = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicAnddynamic__Tovoid = () => (dynamicAnddynamic__Tovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic], [core.String])))();
  let dynamic__Tovoid = () => (dynamic__Tovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic], [core.String])))();
  let dynamic__Tovoid$ = () => (dynamic__Tovoid$ = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic], [core.num])))();
  let dynamicAnddynamicAndnumTovoid = () => (dynamicAnddynamicAndnumTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic, core.num])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  let StringAndRegExpToMatch = () => (StringAndRegExpToMatch = dart.constFn(dart.definiteFunctionType(core.Match, [core.String, core.RegExp])))();
  let StringAndRegExpToListOfString = () => (StringAndRegExpToListOfString = dart.constFn(dart.definiteFunctionType(ListOfString(), [core.String, core.RegExp])))();
  regexp_kde_test.main = function() {
    v8_regexp_utils.description("KDE JS Test");
    let ri = core.RegExp.new("a", {caseSensitive: false});
    let rm = core.RegExp.new("a", {multiLine: true});
    let rg = core.RegExp.new("a");
    v8_regexp_utils.shouldBe(core.RegExp.new("(b)c").firstMatch('abcd'), JSArrayOfString().of(["bc", "b"]));
    v8_regexp_utils.shouldBe(v8_regexp_utils.firstMatch('abcdefghi', core.RegExp.new("(abc)def(ghi)")), JSArrayOfString().of(['abcdefghi', 'abc', 'ghi']));
    v8_regexp_utils.shouldBe(core.RegExp.new("(abc)def(ghi)").firstMatch('abcdefghi'), JSArrayOfString().of(['abcdefghi', 'abc', 'ghi']));
    v8_regexp_utils.shouldBe(v8_regexp_utils.firstMatch('abcdefghi', core.RegExp.new("(a(b(c(d(e)f)g)h)i)")), JSArrayOfString().of(['abcdefghi', 'abcdefghi', 'bcdefgh', 'cdefg', 'def', 'e']));
    v8_regexp_utils.shouldBe(v8_regexp_utils.firstMatch('(100px 200px 150px 15px)', core.RegExp.new("\\((\\d+)(px)* (\\d+)(px)* (\\d+)(px)* (\\d+)(px)*\\)")), JSArrayOfString().of(['(100px 200px 150px 15px)', '100', 'px', '200', 'px', '150', 'px', '15', 'px']));
    v8_regexp_utils.shouldBeNull(v8_regexp_utils.firstMatch('', core.RegExp.new("\\((\\d+)(px)* (\\d+)(px)* (\\d+)(px)* (\\d+)(px)*\\)")));
    let invalidChars = core.RegExp.new("[^@\\.\\w]");
    v8_regexp_utils.shouldBeTrue(v8_regexp_utils.firstMatch('faure@kde.org', invalidChars) == null);
    v8_regexp_utils.shouldBeFalse(v8_regexp_utils.firstMatch('faure-kde@kde.org', invalidChars) == null);
    v8_regexp_utils.assertEquals('test1test2'[dartx.replaceAll]('test', 'X'), 'X1X2');
    v8_regexp_utils.assertEquals('test1test2'[dartx.replaceAll](core.RegExp.new("\\d"), 'X'), 'testXtestX');
    v8_regexp_utils.assertEquals('1test2test3'[dartx.replaceAll](core.RegExp.new("\\d"), ''), 'testtest');
    v8_regexp_utils.assertEquals('test1test2'[dartx.replaceAll](core.RegExp.new("test"), 'X'), 'X1X2');
    v8_regexp_utils.assertEquals('1test2test3'[dartx.replaceAll](core.RegExp.new("\\d"), ''), 'testtest');
    v8_regexp_utils.assertEquals('1test2test3'[dartx.replaceAll](core.RegExp.new("x"), ''), '1test2test3');
    v8_regexp_utils.assertEquals('test1test2'[dartx.replaceAllMapped](core.RegExp.new("(te)(st)"), dart.fn(m => dart.str`${m.group(2)}${m.group(1)}`, MatchToString())), 'stte1stte2');
    v8_regexp_utils.assertEquals('foo+bar'[dartx.replaceAll](core.RegExp.new("\\+"), '%2B'), 'foo%2Bbar');
    let caught = false;
    try {
      core.RegExp.new("+");
    } catch (e) {
      caught = true;
    }

    v8_regexp_utils.shouldBeTrue(caught);
    v8_regexp_utils.assertEquals('foo'[dartx.replaceAll](core.RegExp.new("z?"), 'x'), 'xfxoxox');
    v8_regexp_utils.assertEquals('test test'[dartx.replaceAll](core.RegExp.new("\\s*"), ''), 'testtest');
    v8_regexp_utils.assertEquals('abc$%@'[dartx.replaceAll](core.RegExp.new("[^0-9a-z]*", {caseSensitive: false}), ''), 'abc');
    v8_regexp_utils.assertEquals('ab'[dartx.replaceAll](core.RegExp.new("[^\\d\\.]*", {caseSensitive: false}), ''), '');
    v8_regexp_utils.assertEquals('1ab'[dartx.replaceAll](core.RegExp.new("[^\\d\\.]*", {caseSensitive: false}), ''), '1');
    expect$.Expect.listEquals('1test2test3blah'[dartx.split](core.RegExp.new("test")), JSArrayOfString().of(['1', '2', '3blah']));
    let reg = core.RegExp.new("(\\d\\d )");
    let str = '98 76 blah';
    v8_regexp_utils.shouldBe(reg.firstMatch(str), JSArrayOfString().of(['98 ', '98 ']));
    str = "For more information, see Chapter 3.4.5.1";
    let re = core.RegExp.new("(chapter \\d+(\\.\\d)*)", {caseSensitive: false});
    v8_regexp_utils.shouldBe(v8_regexp_utils.firstMatch(str, re), JSArrayOfString().of(['Chapter 3.4.5.1', 'Chapter 3.4.5.1', '.1']));
    str = "abcDdcba";
    re = core.RegExp.new("d", {caseSensitive: false});
    let matches = re.allMatches(str);
    expect$.Expect.listEquals(matches[dartx.map](core.String)(dart.fn(m => m.group(0), MatchToString()))[dartx.toList](), JSArrayOfString().of(['D', 'd']));
    v8_regexp_utils.shouldBe(v8_regexp_utils.firstMatch('abc', core.RegExp.new("\\u0062")), JSArrayOfString().of(['b']));
  };
  dart.fn(regexp_kde_test.main, VoidTovoid$());
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
  exports.regexp_kde_test = regexp_kde_test;
  exports.v8_regexp_utils = v8_regexp_utils;
});
