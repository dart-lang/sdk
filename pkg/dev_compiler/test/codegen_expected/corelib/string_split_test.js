dart_library.library('corelib/string_split_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__string_split_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const string_split_test = Object.create(null);
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let IterableOfMatch = () => (IterableOfMatch = dart.constFn(core.Iterable$(core.Match)))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let ListAndStringAndPatternTodynamic = () => (ListAndStringAndPatternTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [core.List, core.String, core.Pattern])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicToRegExp = () => (dynamicToRegExp = dart.constFn(dart.definiteFunctionType(core.RegExp, [dart.dynamic])))();
  let dynamicToRegExpWrap = () => (dynamicToRegExpWrap = dart.constFn(dart.definiteFunctionType(string_split_test.RegExpWrap, [dart.dynamic])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  string_split_test.main = function() {
    string_split_test.testSplitString();
    string_split_test.testSplitRegExp();
    string_split_test.testSplitPattern();
  };
  dart.fn(string_split_test.main, VoidTodynamic());
  string_split_test.testSplit = function(expect, string, pattern) {
    let patternString = null;
    if (typeof pattern == 'string') {
      patternString = dart.str`"${pattern}"`;
    } else if (core.RegExp.is(pattern)) {
      patternString = dart.str`/${pattern.pattern}/`;
    } else {
      patternString = dart.toString(pattern);
    }
    expect$.Expect.listEquals(expect, string[dartx.split](pattern), dart.str`"${string}".split(${patternString})`);
  };
  dart.fn(string_split_test.testSplit, ListAndStringAndPatternTodynamic());
  string_split_test.testSplitString = function() {
    string_split_test.testSplit(JSArrayOfString().of(["a", "b", "c"]), "a b c", " ");
    string_split_test.testSplit(JSArrayOfString().of(["a", "b", "c"]), "adbdc", "d");
    string_split_test.testSplit(JSArrayOfString().of(["a", "b", "c"]), "addbddc", "dd");
    string_split_test.testSplit(JSArrayOfString().of(["abc"]), "abc", " ");
    string_split_test.testSplit(JSArrayOfString().of(["a"]), "a", "b");
    string_split_test.testSplit(JSArrayOfString().of([""]), "", "b");
    string_split_test.testSplit(JSArrayOfString().of(["a", "b", "c"]), "abc", "");
    string_split_test.testSplit(JSArrayOfString().of(["", "", "", "", ""]), "aaaa", "a");
    string_split_test.testSplit(JSArrayOfString().of(["", "", "", "", ""]), "    ", " ");
    string_split_test.testSplit(JSArrayOfString().of(["", ""]), "a", "a");
    string_split_test.testSplit(JSArrayOfString().of(["", "", "", "a"]), "aaaaaaa", "aa");
    string_split_test.testSplit([], "", "");
    string_split_test.testSplit(JSArrayOfString().of([""]), "", "a");
  };
  dart.fn(string_split_test.testSplitString, VoidTovoid());
  string_split_test.testSplitRegExp = function() {
    string_split_test.testSplitWithRegExp(dart.fn(s => core.RegExp.new(core.String._check(s)), dynamicToRegExp()));
  };
  dart.fn(string_split_test.testSplitRegExp, VoidTovoid());
  string_split_test.testSplitPattern = function() {
    string_split_test.testSplitWithRegExp(dart.fn(s => new string_split_test.RegExpWrap(core.String._check(s)), dynamicToRegExpWrap()));
  };
  dart.fn(string_split_test.testSplitPattern, VoidTovoid());
  string_split_test.testSplitWithRegExp = function(makePattern) {
    string_split_test.testSplit(JSArrayOfString().of(["a", "b", "c"]), "a b c", core.Pattern._check(dart.dcall(makePattern, " ")));
    string_split_test.testSplit(JSArrayOfString().of(["a", "b", "c"]), "adbdc", core.Pattern._check(dart.dcall(makePattern, "[dz]")));
    string_split_test.testSplit(JSArrayOfString().of(["a", "b", "c"]), "addbddc", core.Pattern._check(dart.dcall(makePattern, "dd")));
    string_split_test.testSplit(JSArrayOfString().of(["abc"]), "abc", core.Pattern._check(dart.dcall(makePattern, "b$")));
    string_split_test.testSplit(JSArrayOfString().of(["a", "b", "c"]), "abc", core.Pattern._check(dart.dcall(makePattern, "")));
    string_split_test.testSplit(JSArrayOfString().of(["", "", "", ""]), "   ", core.Pattern._check(dart.dcall(makePattern, "[ ]")));
    string_split_test.testSplit(JSArrayOfString().of(["aa", ""]), "aaa", core.Pattern._check(dart.dcall(makePattern, "a$")));
    string_split_test.testSplit(JSArrayOfString().of(["aaa"]), "aaa", core.Pattern._check(dart.dcall(makePattern, "$")));
    string_split_test.testSplit(JSArrayOfString().of(["", "aa"]), "aaa", core.Pattern._check(dart.dcall(makePattern, "^a")));
    string_split_test.testSplit(JSArrayOfString().of(["aaa"]), "aaa", core.Pattern._check(dart.dcall(makePattern, "^")));
    string_split_test.testSplit(JSArrayOfString().of(["", "", "", "a"]), "aaaaaaa", core.Pattern._check(dart.dcall(makePattern, "aa|aaa")));
    string_split_test.testSplit(JSArrayOfString().of(["", "", "", "a"]), "aaaaaaa", core.Pattern._check(dart.dcall(makePattern, "aa|")));
    string_split_test.testSplit(JSArrayOfString().of(["", "", "a"]), "aaaaaaa", core.Pattern._check(dart.dcall(makePattern, "aaa|aa")));
    string_split_test.testSplit(JSArrayOfString().of(["a", "bc"]), "abc", core.Pattern._check(dart.dcall(makePattern, "(?=[ab])")));
    string_split_test.testSplit(JSArrayOfString().of(["a", "b", "c"]), "abc", core.Pattern._check(dart.dcall(makePattern, "(?!^)")));
    string_split_test.testSplit([], "", core.Pattern._check(dart.dcall(makePattern, "")));
    string_split_test.testSplit([], "", core.Pattern._check(dart.dcall(makePattern, "(?:)")));
    string_split_test.testSplit([], "", core.Pattern._check(dart.dcall(makePattern, "$|(?=.)")));
    string_split_test.testSplit(JSArrayOfString().of([""]), "", core.Pattern._check(dart.dcall(makePattern, "a")));
    string_split_test.testSplit(JSArrayOfString().of(["", ""]), "a", core.Pattern._check(dart.dcall(makePattern, "a")));
    string_split_test.testSplit(JSArrayOfString().of(["a"]), "a", core.Pattern._check(dart.dcall(makePattern, "b")));
    string_split_test.testSplit(JSArrayOfString().of(["a", "", "a"]), "abba", core.Pattern._check(dart.dcall(makePattern, "(b)")));
    string_split_test.testSplit(JSArrayOfString().of(["a", "a"]), "abba", core.Pattern._check(dart.dcall(makePattern, "(bb)")));
    string_split_test.testSplit(JSArrayOfString().of(["a", "a"]), "abba", core.Pattern._check(dart.dcall(makePattern, "(b*)")));
    string_split_test.testSplit(JSArrayOfString().of(["a", "a"]), "aa", core.Pattern._check(dart.dcall(makePattern, "(b*)")));
    string_split_test.testSplit(JSArrayOfString().of(["a", "cba"]), "abcba", core.Pattern._check(dart.dcall(makePattern, "([bc])(?=.*\\1)")));
  };
  dart.fn(string_split_test.testSplitWithRegExp, dynamicTovoid());
  string_split_test.RegExpWrap = class RegExpWrap extends core.Object {
    new(source) {
      this.regexp = core.RegExp.new(source);
    }
    allMatches(string, start) {
      if (start === void 0) start = 0;
      return IterableOfMatch()._check(dart.dsend(this.regexp, 'allMatches', string, start));
    }
    matchAsPrefix(string, start) {
      if (start === void 0) start = 0;
      return core.Match._check(dart.dsend(this.regexp, 'matchAsPrefix', string, start));
    }
    toString() {
      return dart.str`Wrap(/${dart.dload(this.regexp, 'pattern')}/)`;
    }
  };
  string_split_test.RegExpWrap[dart.implements] = () => [core.Pattern];
  dart.setSignature(string_split_test.RegExpWrap, {
    constructors: () => ({new: dart.definiteFunctionType(string_split_test.RegExpWrap, [core.String])}),
    methods: () => ({
      allMatches: dart.definiteFunctionType(core.Iterable$(core.Match), [core.String], [core.int]),
      matchAsPrefix: dart.definiteFunctionType(core.Match, [core.String], [core.int])
    })
  });
  dart.defineExtensionMembers(string_split_test.RegExpWrap, ['allMatches', 'matchAsPrefix']);
  // Exports:
  exports.string_split_test = string_split_test;
});
