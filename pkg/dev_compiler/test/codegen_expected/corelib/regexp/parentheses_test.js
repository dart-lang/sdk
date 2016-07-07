dart_library.library('corelib/regexp/parentheses_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__parentheses_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const parentheses_test = Object.create(null);
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
  parentheses_test.main = function() {
    v8_regexp_utils.description("This page tests handling of parentheses subexpressions.");
    let regexp1 = core.RegExp.new("(a|A)(b|B)");
    v8_regexp_utils.shouldBe(regexp1.firstMatch('abc'), JSArrayOfString().of(['ab', 'a', 'b']));
    let regexp2 = core.RegExp.new("(a((b)|c|d))e");
    v8_regexp_utils.shouldBe(regexp2.firstMatch('abacadabe'), JSArrayOfString().of(['abe', 'ab', 'b', 'b']));
    let regexp3 = core.RegExp.new("(a(b|(c)|d))e");
    v8_regexp_utils.shouldBe(regexp3.firstMatch('abacadabe'), JSArrayOfString().of(['abe', 'ab', 'b', null]));
    let regexp4 = core.RegExp.new("(a(b|c|(d)))e");
    v8_regexp_utils.shouldBe(regexp4.firstMatch('abacadabe'), JSArrayOfString().of(['abe', 'ab', 'b', null]));
    let regexp5 = core.RegExp.new("(a((b)|(c)|(d)))e");
    v8_regexp_utils.shouldBe(regexp5.firstMatch('abacadabe'), JSArrayOfString().of(['abe', 'ab', 'b', 'b', null, null]));
    let regexp6 = core.RegExp.new("(a((b)|(c)|(d)))");
    v8_regexp_utils.shouldBe(regexp6.firstMatch('abcde'), JSArrayOfString().of(['ab', 'ab', 'b', 'b', null, null]));
    let regexp7 = core.RegExp.new("(a(b)??)??c");
    v8_regexp_utils.shouldBe(regexp7.firstMatch('abc'), JSArrayOfString().of(['abc', 'ab', 'b']));
    let regexp8 = core.RegExp.new("(a|(e|q))(x|y)");
    v8_regexp_utils.shouldBe(regexp8.firstMatch('bcaddxqy'), JSArrayOfString().of(['qy', 'q', 'q', 'y']));
    let regexp9 = core.RegExp.new("((t|b)?|a)$");
    v8_regexp_utils.shouldBe(regexp9.firstMatch('asdfjejgsdflaksdfjkeljghkjea'), JSArrayOfString().of(['a', 'a', null]));
    let regexp10 = core.RegExp.new("(?:h|e?(?:t|b)?|a?(?:t|b)?)(?:$)");
    v8_regexp_utils.shouldBe(regexp10.firstMatch('asdfjejgsdflaksdfjkeljghat'), JSArrayOfString().of(['at']));
    let regexp11 = core.RegExp.new("([Jj]ava([Ss]cript)?)\\sis\\s(fun\\w*)");
    v8_regexp_utils.shouldBeNull(regexp11.firstMatch('Developing with JavaScript is dangerous, do not try it without assistance'));
    let regexp12 = core.RegExp.new("(?:(.+), )?(.+), (..) to (?:(.+), )?(.+), (..)");
    v8_regexp_utils.shouldBe(regexp12.firstMatch('Seattle, WA to Buckley, WA'), JSArrayOfString().of(['Seattle, WA to Buckley, WA', null, 'Seattle', 'WA', null, 'Buckley', 'WA']));
    let regexp13 = core.RegExp.new("(A)?(A.*)");
    v8_regexp_utils.shouldBe(regexp13.firstMatch('zxcasd;fl ^AaaAAaaaf;lrlrzs'), JSArrayOfString().of(['AaaAAaaaf;lrlrzs', null, 'AaaAAaaaf;lrlrzs']));
    let regexp14 = core.RegExp.new("(a)|(b)");
    v8_regexp_utils.shouldBe(regexp14.firstMatch('b'), JSArrayOfString().of(['b', null, 'b']));
    let regexp15 = core.RegExp.new("^(?!(ab)de|x)(abd)(f)");
    v8_regexp_utils.shouldBe(regexp15.firstMatch('abdf'), JSArrayOfString().of(['abdf', null, 'abd', 'f']));
    let regexp16 = core.RegExp.new("(a|A)(b|B)");
    v8_regexp_utils.shouldBe(regexp16.firstMatch('abc'), JSArrayOfString().of(['ab', 'a', 'b']));
    let regexp17 = core.RegExp.new("(a|d|q|)x", {caseSensitive: false});
    v8_regexp_utils.shouldBe(regexp17.firstMatch('bcaDxqy'), JSArrayOfString().of(['Dx', 'D']));
    let regexp18 = core.RegExp.new("^.*?(:|$)");
    v8_regexp_utils.shouldBe(regexp18.firstMatch('Hello: World'), JSArrayOfString().of(['Hello:', ':']));
    let regexp19 = core.RegExp.new("(ab|^.{0,2})bar");
    v8_regexp_utils.shouldBe(regexp19.firstMatch('barrel'), JSArrayOfString().of(['bar', '']));
    let regexp20 = core.RegExp.new("(?:(?!foo)...|^.{0,2})bar(.*)");
    v8_regexp_utils.shouldBe(regexp20.firstMatch('barrel'), JSArrayOfString().of(['barrel', 'rel']));
    v8_regexp_utils.shouldBe(regexp20.firstMatch('2barrel'), JSArrayOfString().of(['2barrel', 'rel']));
    let regexp21 = core.RegExp.new("([a-g](b|B)|xyz)");
    v8_regexp_utils.shouldBe(regexp21.firstMatch('abc'), JSArrayOfString().of(['ab', 'ab', 'b']));
    let regexp22 = core.RegExp.new("(?:^|;)\\s*abc=([^;]*)");
    v8_regexp_utils.shouldBeNull(regexp22.firstMatch('abcdlskfgjdslkfg'));
    let regexp23 = core.RegExp.new("\"[^<\"]*\"|'[^<']*'");
    v8_regexp_utils.shouldBe(regexp23.firstMatch('<html xmlns="http://www.w3.org/1999/xhtml"'), JSArrayOfString().of(['"http://www.w3.org/1999/xhtml"']));
    let regexp24 = core.RegExp.new("^(?:(?=abc)\\w{3}:|\\d\\d)$");
    v8_regexp_utils.shouldBeNull(regexp24.firstMatch('123'));
    let regexp25 = core.RegExp.new("^\\s*(\\*|[\\w\\-]+)(\\b|$)?");
    v8_regexp_utils.shouldBe(regexp25.firstMatch('this is a test'), JSArrayOfString().of(['this', 'this', null]));
    v8_regexp_utils.shouldBeNull(regexp25.firstMatch('!this is a test'));
    let regexp26 = core.RegExp.new("a(b)(a*)|aaa");
    v8_regexp_utils.shouldBe(regexp26.firstMatch('aaa'), JSArrayOfString().of(['aaa', null, null]));
    let regexp27 = core.RegExp.new("^" + "(?:" + "([^:/?#]+):" + ")?" + "(?:" + "(//)" + "(" + "(?:" + "(" + "([^:@]*)" + ":?" + "([^:@]*)" + ")?" + "@" + ")?" + "([^:/?#]*)" + "(?::(\\d*))?" + ")" + ")?" + "([^?#]*)" + "(?:\\?([^#]*))?" + "(?:#(.*))?");
    v8_regexp_utils.shouldBe(regexp27.firstMatch('file:///Users/Someone/Desktop/HelloWorld/index.html'), JSArrayOfString().of(['file:///Users/Someone/Desktop/HelloWorld/index.html', 'file', '//', '', null, null, null, '', null, '/Users/Someone/Desktop/HelloWorld/index.html', null, null]));
    let regexp28 = core.RegExp.new("^" + "(?:" + "([^:/?#]+):" + ")?" + "(?:" + "(//)" + "(" + "(" + "([^:@]*)" + ":?" + "([^:@]*)" + ")?" + "@" + ")" + ")?");
    v8_regexp_utils.shouldBe(regexp28.firstMatch('file:///Users/Someone/Desktop/HelloWorld/index.html'), JSArrayOfString().of(['file:', 'file', null, null, null, null, null]));
    let regexp29 = core.RegExp.new('^\\s*((\\[[^\\]]+\\])|(u?)("[^"]+"))\\s*');
    v8_regexp_utils.shouldBeNull(regexp29.firstMatch('Committer:'));
    let regexp30 = core.RegExp.new('^\\s*((\\[[^\\]]+\\])|m(u?)("[^"]+"))\\s*');
    v8_regexp_utils.shouldBeNull(regexp30.firstMatch('Committer:'));
    let regexp31 = core.RegExp.new('^\\s*(m(\\[[^\\]]+\\])|m(u?)("[^"]+"))\\s*');
    v8_regexp_utils.shouldBeNull(regexp31.firstMatch('Committer:'));
    let regexp32 = core.RegExp.new('\\s*(m(\\[[^\\]]+\\])|m(u?)("[^"]+"))\\s*');
    v8_regexp_utils.shouldBeNull(regexp32.firstMatch('Committer:'));
    let regexp33 = core.RegExp.new('^(?:(?:(a)(xyz|[^>"\'s]*)?)|(/?>)|.[^ws>]*)');
    v8_regexp_utils.shouldBe(regexp33.firstMatch('> <head>'), JSArrayOfString().of(['>', null, null, '>']));
    let regexp34 = core.RegExp.new("(?:^|\\b)btn-\\S+");
    v8_regexp_utils.shouldBeNull(regexp34.firstMatch('xyz123'));
    v8_regexp_utils.shouldBe(regexp34.firstMatch('btn-abc'), JSArrayOfString().of(['btn-abc']));
    v8_regexp_utils.shouldBeNull(regexp34.firstMatch('btn- abc'));
    v8_regexp_utils.shouldBeNull(regexp34.firstMatch('XXbtn-abc'));
    v8_regexp_utils.shouldBe(regexp34.firstMatch('XX btn-abc'), JSArrayOfString().of(['btn-abc']));
    let regexp35 = core.RegExp.new("^((a|b)(x|xxx)|)$");
    v8_regexp_utils.shouldBe(regexp35.firstMatch('ax'), JSArrayOfString().of(['ax', 'ax', 'a', 'x']));
    v8_regexp_utils.shouldBeNull(regexp35.firstMatch('axx'));
    v8_regexp_utils.shouldBe(regexp35.firstMatch('axxx'), JSArrayOfString().of(['axxx', 'axxx', 'a', 'xxx']));
    v8_regexp_utils.shouldBe(regexp35.firstMatch('bx'), JSArrayOfString().of(['bx', 'bx', 'b', 'x']));
    v8_regexp_utils.shouldBeNull(regexp35.firstMatch('bxx'));
    v8_regexp_utils.shouldBe(regexp35.firstMatch('bxxx'), JSArrayOfString().of(['bxxx', 'bxxx', 'b', 'xxx']));
    let regexp36 = core.RegExp.new("^((\\/|\\.|\\-)(\\d\\d|\\d\\d\\d\\d)|)$");
    v8_regexp_utils.shouldBe(regexp36.firstMatch('/2011'), JSArrayOfString().of(['/2011', '/2011', '/', '2011']));
    v8_regexp_utils.shouldBe(regexp36.firstMatch('/11'), JSArrayOfString().of(['/11', '/11', '/', '11']));
    v8_regexp_utils.shouldBeNull(regexp36.firstMatch('/123'));
    let regexp37 = core.RegExp.new("^([1][0-2]|[0]\\d|\\d)(\\/|\\.|\\-)([0-2]\\d|[3][0-1]|\\d)((\\/|\\.|\\-)(\\d\\d|\\d\\d\\d\\d)|)$");
    v8_regexp_utils.shouldBe(regexp37.firstMatch('7/4/1776'), JSArrayOfString().of(['7/4/1776', '7', '/', '4', '/1776', '/', '1776']));
    v8_regexp_utils.shouldBe(regexp37.firstMatch('07-04-1776'), JSArrayOfString().of(['07-04-1776', '07', '-', '04', '-1776', '-', '1776']));
    let regexp38 = core.RegExp.new("^(z|(x|xx)|b|)$");
    v8_regexp_utils.shouldBe(regexp38.firstMatch('xx'), JSArrayOfString().of(['xx', 'xx', 'xx']));
    v8_regexp_utils.shouldBe(regexp38.firstMatch('b'), JSArrayOfString().of(['b', 'b', null]));
    v8_regexp_utils.shouldBe(regexp38.firstMatch('z'), JSArrayOfString().of(['z', 'z', null]));
    v8_regexp_utils.shouldBe(regexp38.firstMatch(''), JSArrayOfString().of(['', '', null]));
    let regexp39 = core.RegExp.new("(8|((?=P)))?");
    v8_regexp_utils.shouldBe(regexp39.firstMatch(''), JSArrayOfString().of(['', null, null]));
    v8_regexp_utils.shouldBe(regexp39.firstMatch('8'), JSArrayOfString().of(['8', '8', null]));
    v8_regexp_utils.shouldBe(regexp39.firstMatch('zP'), JSArrayOfString().of(['', null, null]));
    let regexp40 = core.RegExp.new("((8)|((?=P){4}))?()");
    v8_regexp_utils.shouldBe(regexp40.firstMatch(''), JSArrayOfString().of(['', null, null, null, '']));
    v8_regexp_utils.shouldBe(regexp40.firstMatch('8'), JSArrayOfString().of(['8', '8', '8', null, '']));
    v8_regexp_utils.shouldBe(regexp40.firstMatch('zPz'), JSArrayOfString().of(['', null, null, null, '']));
    v8_regexp_utils.shouldBe(regexp40.firstMatch('zPPz'), JSArrayOfString().of(['', null, null, null, '']));
    v8_regexp_utils.shouldBe(regexp40.firstMatch('zPPPz'), JSArrayOfString().of(['', null, null, null, '']));
    v8_regexp_utils.shouldBe(regexp40.firstMatch('zPPPPz'), JSArrayOfString().of(['', null, null, null, '']));
    let regexp41 = core.RegExp.new("(([\\w\\-]+:\\/\\/?|www[.])[^\\s()<>]+(?:([\\w\\d]+)|([^\\[:punct:\\]\\s()<>\\W]|\\/)))");
    v8_regexp_utils.shouldBe(regexp41.firstMatch('Here is a link: http://www.acme.com/our_products/index.html. That is all we want!'), JSArrayOfString().of(['http://www.acme.com/our_products/index.html', 'http://www.acme.com/our_products/index.html', 'http://', 'l', null]));
    let regexp42 = core.RegExp.new("((?:(4)?))?");
    v8_regexp_utils.shouldBe(regexp42.firstMatch(''), JSArrayOfString().of(['', null, null]));
    v8_regexp_utils.shouldBe(regexp42.firstMatch('4'), JSArrayOfString().of(['4', '4', '4']));
    v8_regexp_utils.shouldBe(regexp42.firstMatch('4321'), JSArrayOfString().of(['4', '4', '4']));
    v8_regexp_utils.shouldBeTrue(core.RegExp.new("(?!(?=r{0}){2,})|((z)?)?", {caseSensitive: false}).hasMatch(''));
    let regexp43 = core.RegExp.new("(?!(?:\\1+s))");
    v8_regexp_utils.shouldBe(regexp43.firstMatch('SSS'), JSArrayOfString().of(['']));
    let regexp44 = core.RegExp.new("(?!(?:\\3+(s+?)))");
    v8_regexp_utils.shouldBe(regexp44.firstMatch('SSS'), JSArrayOfString().of(['', null]));
    let regexp45 = core.RegExp.new("((?!(?:|)v{2,}|))");
    v8_regexp_utils.shouldBeNull(regexp45.firstMatch('vt'));
    let regexp46 = core.RegExp.new("(w)(?:5{3}|())|pk");
    v8_regexp_utils.shouldBeNull(regexp46.firstMatch('5'));
    v8_regexp_utils.shouldBe(regexp46.firstMatch('pk'), JSArrayOfString().of(['pk', null, null]));
    v8_regexp_utils.shouldBe(regexp46.firstMatch('Xw555'), JSArrayOfString().of(['w555', 'w', null]));
    v8_regexp_utils.shouldBe(regexp46.firstMatch('Xw55pk5'), JSArrayOfString().of(['w', 'w', '']));
    let regexp47 = core.RegExp.new("(.*?)(?:(?:\\?(.*?)?)?)(?:(?:#)?)$");
    v8_regexp_utils.shouldBe(regexp47.firstMatch('/www.acme.com/this/is/a/path/file.txt'), JSArrayOfString().of(['/www.acme.com/this/is/a/path/file.txt', '/www.acme.com/this/is/a/path/file.txt', null]));
    let regexp48 = core.RegExp.new("^(?:(\\w+):\\/*([\\w\\.\\-\\d]+)(?::(\\d+)|)(?=(?:\\/|$))|)(?:$|\\/?(.*?)(?:\\?(.*?)?|)(?:#(.*)|)$)");
    v8_regexp_utils.shouldBe(regexp48.firstMatch('http://www.acme.com/this/is/a/path/file.txt'), JSArrayOfString().of(['http://www.acme.com/this/is/a/path/file.txt', 'http', 'www.acme.com', null, 'this/is/a/path/file.txt', null, null]));
    let regexp49 = core.RegExp.new("(?:([^:]*?)(?:(?:\\?(.*?)?)?)(?:(?:#)?)$)|(?:^(?:(\\w+):\\/*([\\w\\.\\-\\d]+)(?::(\\d+)|)(?=(?:\\/|$))|)(?:$|\\/?(.*?)(?:\\?(.*?)?|)(?:#(.*)|)$))");
    v8_regexp_utils.shouldBe(regexp49.firstMatch('http://www.acme.com/this/is/a/path/file.txt'), JSArrayOfString().of(['http://www.acme.com/this/is/a/path/file.txt', null, null, 'http', 'www.acme.com', null, 'this/is/a/path/file.txt', null, null]));
    let regexp50 = core.RegExp.new("((a)b{28,}c|d)x");
    v8_regexp_utils.shouldBeNull(regexp50.firstMatch('((a)b{28,}c|d)x'));
    v8_regexp_utils.shouldBe(regexp50.firstMatch('abbbbbbbbbbbbbbbbbbbbbbbbbbbbcx'), JSArrayOfString().of(['abbbbbbbbbbbbbbbbbbbbbbbbbbbbcx', 'abbbbbbbbbbbbbbbbbbbbbbbbbbbbc', 'a']));
    v8_regexp_utils.shouldBe(regexp50.firstMatch('dx'), JSArrayOfString().of(['dx', 'd', null]));
    let s = "((.s{-}).{28,}P{Yi}?{,30}|.){-,}P{Any}";
    let regexp51 = core.RegExp.new(s);
    v8_regexp_utils.shouldBeNull(regexp51.firstMatch('abc'));
    v8_regexp_utils.shouldBe(regexp51.firstMatch(s), JSArrayOfString().of(['){-,}P{Any}', ')', null]));
    let regexp52 = core.RegExp.new("(Rob)|(Bob)|(Robert)|(Bobby)");
    v8_regexp_utils.shouldBe(regexp52.firstMatch('Hi Bob'), JSArrayOfString().of(['Bob', null, 'Bob', null, null]));
    let regexp53 = core.RegExp.new("(?=(?:(?:(gB)|(?!cs|<))((?=(?!v6){0,})))|(?=#)+?)", {multiLine: true});
    v8_regexp_utils.shouldBe(regexp53.firstMatch('#'), JSArrayOfString().of(['', null, '']));
    let regexp54 = core.RegExp.new("((?:(?:()|(?!))((?=(?!))))|())", {multiLine: true});
    v8_regexp_utils.shouldBe(regexp54.firstMatch('#'), JSArrayOfString().of(['', '', null, null, '']));
    let regexp55 = core.RegExp.new("(?:(?:(?:a?|(?:))((?:)))|a?)", {multiLine: true});
    v8_regexp_utils.shouldBe(regexp55.firstMatch('#'), JSArrayOfString().of(['', '']));
    let regexp56 = core.RegExp.new("(|a)");
    v8_regexp_utils.shouldBe(regexp56.firstMatch('a'), JSArrayOfString().of(['', '']));
    let regexp57 = core.RegExp.new("(a|)");
    v8_regexp_utils.shouldBe(regexp57.firstMatch('a'), JSArrayOfString().of(['a', 'a']));
    let regexp58 = core.RegExp.new("a|b(?:[^b])*?c");
    v8_regexp_utils.shouldBe(regexp58.firstMatch('badbc'), JSArrayOfString().of(['a']));
    let regexp59 = core.RegExp.new("(X(?:.(?!X))*?Y)|(Y(?:.(?!Y))*?Z)");
    expect$.Expect.listEquals(regexp59.allMatches('Y aaa X Match1 Y aaa Y Match2 Z')[dartx.map](core.String)(dart.fn(m => m.group(0), MatchToString()))[dartx.toList](), JSArrayOfString().of(['X Match1 Y', 'Y Match2 Z']));
  };
  dart.fn(parentheses_test.main, VoidTovoid$());
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
  exports.parentheses_test = parentheses_test;
  exports.v8_regexp_utils = v8_regexp_utils;
});
