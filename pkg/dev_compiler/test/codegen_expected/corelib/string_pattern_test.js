dart_library.library('corelib/string_pattern_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__string_pattern_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const string_pattern_test = Object.create(null);
  let IterableOfMatch = () => (IterableOfMatch = dart.constFn(core.Iterable$(core.Match)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidToMatch = () => (VoidToMatch = dart.constFn(dart.definiteFunctionType(core.Match, [])))();
  let VoidToIterableOfMatch = () => (VoidToIterableOfMatch = dart.constFn(dart.definiteFunctionType(IterableOfMatch(), [])))();
  string_pattern_test.str = "this is a string with hello here and hello there";
  string_pattern_test.main = function() {
    string_pattern_test.testNoMatch();
    string_pattern_test.testOneMatch();
    string_pattern_test.testTwoMatches();
    string_pattern_test.testEmptyPattern();
    string_pattern_test.testEmptyString();
    string_pattern_test.testEmptyPatternAndString();
    string_pattern_test.testMatchAsPrefix();
    string_pattern_test.testAllMatchesStart();
  };
  dart.fn(string_pattern_test.main, VoidTodynamic());
  string_pattern_test.testNoMatch = function() {
    let helloPattern = "with (hello)";
    let matches = helloPattern[dartx.allMatches](string_pattern_test.str);
    expect$.Expect.isFalse(matches[dartx.iterator].moveNext());
  };
  dart.fn(string_pattern_test.testNoMatch, VoidTodynamic());
  string_pattern_test.testOneMatch = function() {
    let helloPattern = "with hello";
    let matches = helloPattern[dartx.allMatches](string_pattern_test.str);
    let iterator = matches[dartx.iterator];
    expect$.Expect.isTrue(iterator.moveNext());
    let match = iterator.current;
    expect$.Expect.isFalse(iterator.moveNext());
    expect$.Expect.equals(string_pattern_test.str[dartx.indexOf]('with', 0), match.start);
    expect$.Expect.equals(dart.notNull(string_pattern_test.str[dartx.indexOf]('with', 0)) + dart.notNull(helloPattern[dartx.length]), match.end);
    expect$.Expect.equals(helloPattern, match.pattern);
    expect$.Expect.equals(string_pattern_test.str, match.input);
    expect$.Expect.equals(helloPattern, match.get(0));
    expect$.Expect.equals(0, match.groupCount);
  };
  dart.fn(string_pattern_test.testOneMatch, VoidTodynamic());
  string_pattern_test.testTwoMatches = function() {
    let helloPattern = "hello";
    let matches = helloPattern[dartx.allMatches](string_pattern_test.str);
    let count = 0;
    let start = 0;
    for (let match of matches) {
      count++;
      expect$.Expect.equals(string_pattern_test.str[dartx.indexOf]('hello', start), match.start);
      expect$.Expect.equals(dart.notNull(string_pattern_test.str[dartx.indexOf]('hello', start)) + dart.notNull(helloPattern[dartx.length]), match.end);
      expect$.Expect.equals(helloPattern, match.pattern);
      expect$.Expect.equals(string_pattern_test.str, match.input);
      expect$.Expect.equals(helloPattern, match.get(0));
      expect$.Expect.equals(0, match.groupCount);
      start = match.end;
    }
    expect$.Expect.equals(2, count);
  };
  dart.fn(string_pattern_test.testTwoMatches, VoidTodynamic());
  string_pattern_test.testEmptyPattern = function() {
    let pattern = "";
    let matches = pattern[dartx.allMatches](string_pattern_test.str);
    expect$.Expect.isTrue(matches[dartx.iterator].moveNext());
  };
  dart.fn(string_pattern_test.testEmptyPattern, VoidTodynamic());
  string_pattern_test.testEmptyString = function() {
    let pattern = "foo";
    let str = "";
    let matches = pattern[dartx.allMatches](str);
    expect$.Expect.isFalse(matches[dartx.iterator].moveNext());
  };
  dart.fn(string_pattern_test.testEmptyString, VoidTodynamic());
  string_pattern_test.testEmptyPatternAndString = function() {
    let pattern = "";
    let str = "";
    let matches = pattern[dartx.allMatches](str);
    expect$.Expect.isTrue(matches[dartx.iterator].moveNext());
  };
  dart.fn(string_pattern_test.testEmptyPatternAndString, VoidTodynamic());
  string_pattern_test.testMatchAsPrefix = function() {
    let pattern = "an";
    let str = "banana";
    expect$.Expect.isNull(pattern[dartx.matchAsPrefix](str));
    expect$.Expect.isNull(pattern[dartx.matchAsPrefix](str, 0));
    let m = pattern[dartx.matchAsPrefix](str, 1);
    expect$.Expect.equals("an", m.get(0));
    expect$.Expect.equals(1, m.start);
    expect$.Expect.isNull(pattern[dartx.matchAsPrefix](str, 2));
    m = pattern[dartx.matchAsPrefix](str, 3);
    expect$.Expect.equals("an", m.get(0));
    expect$.Expect.equals(3, m.start);
    expect$.Expect.isNull(pattern[dartx.matchAsPrefix](str, 4));
    expect$.Expect.isNull(pattern[dartx.matchAsPrefix](str, 5));
    expect$.Expect.isNull(pattern[dartx.matchAsPrefix](str, 6));
    expect$.Expect.throws(dart.fn(() => pattern[dartx.matchAsPrefix](str, -1), VoidToMatch()));
    expect$.Expect.throws(dart.fn(() => pattern[dartx.matchAsPrefix](str, 7), VoidToMatch()));
  };
  dart.fn(string_pattern_test.testMatchAsPrefix, VoidTodynamic());
  string_pattern_test.testAllMatchesStart = function() {
    let p = "ass";
    let s = "assassin";
    expect$.Expect.equals(2, p[dartx.allMatches](s)[dartx.length]);
    expect$.Expect.equals(2, p[dartx.allMatches](s, 0)[dartx.length]);
    expect$.Expect.equals(1, p[dartx.allMatches](s, 1)[dartx.length]);
    expect$.Expect.equals(0, p[dartx.allMatches](s, 4)[dartx.length]);
    expect$.Expect.equals(0, p[dartx.allMatches](s, s[dartx.length])[dartx.length]);
    expect$.Expect.throws(dart.fn(() => p[dartx.allMatches](s, -1), VoidToIterableOfMatch()));
    expect$.Expect.throws(dart.fn(() => p[dartx.allMatches](s, dart.notNull(s[dartx.length]) + 1), VoidToIterableOfMatch()));
  };
  dart.fn(string_pattern_test.testAllMatchesStart, VoidTodynamic());
  // Exports:
  exports.string_pattern_test = string_pattern_test;
});
