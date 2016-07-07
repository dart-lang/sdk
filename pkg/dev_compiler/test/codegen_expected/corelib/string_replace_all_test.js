dart_library.library('corelib/string_replace_all_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__string_replace_all_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const string_replace_all_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let MatchToString = () => (MatchToString = dart.constFn(dart.definiteFunctionType(core.String, [core.Match])))();
  let StringToString = () => (StringToString = dart.constFn(dart.definiteFunctionType(core.String, [core.String])))();
  string_replace_all_test.testReplaceAll = function() {
    expect$.Expect.equals("aXXcaXXdae", "abcabdae"[dartx.replaceAll]("b", "XX"));
    expect$.Expect.equals("XXbcXXbdXXe", "abcabdae"[dartx.replaceAll]("a", "XX"));
    expect$.Expect.equals("abcabdaXX", "abcabdae"[dartx.replaceAll]("e", "XX"));
    expect$.Expect.equals("abcabdae", "abcabdae"[dartx.replaceAll]("f", "XX"));
    expect$.Expect.equals("", ""[dartx.replaceAll]("from", "to"));
    expect$.Expect.equals("fro", "fro"[dartx.replaceAll]("from", "to"));
    expect$.Expect.equals("to", "from"[dartx.replaceAll]("from", "to"));
    expect$.Expect.equals("toto", "fromfrom"[dartx.replaceAll]("from", "to"));
    expect$.Expect.equals("to", "to"[dartx.replaceAll]("from", "to"));
    expect$.Expect.equals("bcbde", "abcabdae"[dartx.replaceAll]("a", ""));
    expect$.Expect.equals("AB", "AfromB"[dartx.replaceAll]("from", ""));
    expect$.Expect.equals("to", ""[dartx.replaceAll]("", "to"));
    expect$.Expect.equals("toAtoBtoCto", "ABC"[dartx.replaceAll]("", "to"));
    expect$.Expect.equals("$$", "||"[dartx.replaceAll]("|", "$"));
    expect$.Expect.equals("$$$$", "||"[dartx.replaceAll]("|", "$$"));
    expect$.Expect.equals("x$|x", "x|.|x"[dartx.replaceAll]("|.", "$"));
    expect$.Expect.equals("$$", ".."[dartx.replaceAll](".", "$"));
    expect$.Expect.equals("[$$$$]", "[..]"[dartx.replaceAll](".", "$$"));
    expect$.Expect.equals("[$]", "[..]"[dartx.replaceAll]("..", "$"));
    expect$.Expect.equals("$$", "\\\\"[dartx.replaceAll]("\\", "$"));
  };
  dart.fn(string_replace_all_test.testReplaceAll, VoidTodynamic());
  string_replace_all_test.testReplaceAllMapped = function() {
    function mark(m) {
      return dart.str`[${m.get(0)}]`;
    }
    dart.fn(mark, MatchToString());
    expect$.Expect.equals("a[b]ca[b]dae", "abcabdae"[dartx.replaceAllMapped]("b", mark));
    expect$.Expect.equals("[a]bc[a]bd[a]e", "abcabdae"[dartx.replaceAllMapped]("a", mark));
    expect$.Expect.equals("abcabda[e]", "abcabdae"[dartx.replaceAllMapped]("e", mark));
    expect$.Expect.equals("abcabdae", "abcabdae"[dartx.replaceAllMapped]("f", mark));
    expect$.Expect.equals("", ""[dartx.replaceAllMapped]("from", mark));
    expect$.Expect.equals("fro", "fro"[dartx.replaceAllMapped]("from", mark));
    expect$.Expect.equals("[from][from]", "fromfrom"[dartx.replaceAllMapped]("from", mark));
    expect$.Expect.equals("bcbde", "abcabdae"[dartx.replaceAllMapped]("a", dart.fn(m => "", MatchToString())));
    expect$.Expect.equals("AB", "AfromB"[dartx.replaceAllMapped]("from", dart.fn(m => "", MatchToString())));
    expect$.Expect.equals("[]", ""[dartx.replaceAllMapped]("", mark));
    expect$.Expect.equals("[]A[]B[]C[]", "ABC"[dartx.replaceAllMapped]("", mark));
  };
  dart.fn(string_replace_all_test.testReplaceAllMapped, VoidTodynamic());
  string_replace_all_test.testSplitMapJoin = function() {
    function mark(m) {
      return dart.str`[${m.get(0)}]`;
    }
    dart.fn(mark, MatchToString());
    function wrap(s) {
      return dart.str`<${s}>`;
    }
    dart.fn(wrap, StringToString());
    expect$.Expect.equals("<a>[b]<ca>[b]<dae>", "abcabdae"[dartx.splitMapJoin]("b", {onMatch: mark, onNonMatch: wrap}));
    expect$.Expect.equals("<>[a]<bc>[a]<bd>[a]<e>", "abcabdae"[dartx.splitMapJoin]("a", {onMatch: mark, onNonMatch: wrap}));
    expect$.Expect.equals("<abcabda>[e]<>", "abcabdae"[dartx.splitMapJoin]("e", {onMatch: mark, onNonMatch: wrap}));
    expect$.Expect.equals("<abcabdae>", "abcabdae"[dartx.splitMapJoin]("f", {onMatch: mark, onNonMatch: wrap}));
    expect$.Expect.equals("<>", ""[dartx.splitMapJoin]("from", {onMatch: mark, onNonMatch: wrap}));
    expect$.Expect.equals("<fro>", "fro"[dartx.splitMapJoin]("from", {onMatch: mark, onNonMatch: wrap}));
    expect$.Expect.equals("<>[from]<>[from]<>", "fromfrom"[dartx.splitMapJoin]("from", {onMatch: mark, onNonMatch: wrap}));
    expect$.Expect.equals("<>[]<>", ""[dartx.splitMapJoin]("", {onMatch: mark, onNonMatch: wrap}));
    expect$.Expect.equals("<>[]<A>[]<B>[]<C>[]<>", "ABC"[dartx.splitMapJoin]("", {onMatch: mark, onNonMatch: wrap}));
    expect$.Expect.equals("[a]bc[a]bd[a]e", "abcabdae"[dartx.splitMapJoin]("a", {onMatch: mark}));
    expect$.Expect.equals("<>a<bc>a<bd>a<e>", "abcabdae"[dartx.splitMapJoin]("a", {onNonMatch: wrap}));
  };
  dart.fn(string_replace_all_test.testSplitMapJoin, VoidTodynamic());
  string_replace_all_test.main = function() {
    string_replace_all_test.testReplaceAll();
    string_replace_all_test.testReplaceAllMapped();
    string_replace_all_test.testSplitMapJoin();
  };
  dart.fn(string_replace_all_test.main, VoidTodynamic());
  // Exports:
  exports.string_replace_all_test = string_replace_all_test;
});
