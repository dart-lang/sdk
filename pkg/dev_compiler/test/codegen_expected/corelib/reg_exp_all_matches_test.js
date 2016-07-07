dart_library.library('corelib/reg_exp_all_matches_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__reg_exp_all_matches_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const reg_exp_all_matches_test = Object.create(null);
  let MatchTovoid = () => (MatchTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [core.Match])))();
  let MatchToString = () => (MatchToString = dart.constFn(dart.definiteFunctionType(core.String, [core.Match])))();
  let MatchTobool = () => (MatchTobool = dart.constFn(dart.definiteFunctionType(core.bool, [core.Match])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  reg_exp_all_matches_test.RegExpAllMatchesTest = class RegExpAllMatchesTest extends core.Object {
    static testIterator() {
      let matches = core.RegExp.new("foo").allMatches("foo foo");
      let it = matches[dartx.iterator];
      expect$.Expect.isTrue(it.moveNext());
      expect$.Expect.equals('foo', dart.dsend(it.current, 'group', 0));
      expect$.Expect.isTrue(it.moveNext());
      expect$.Expect.equals('foo', dart.dsend(it.current, 'group', 0));
      expect$.Expect.isFalse(it.moveNext());
      it = matches[dartx.iterator];
      let it2 = matches[dartx.iterator];
      expect$.Expect.isTrue(it.moveNext());
      expect$.Expect.isTrue(it2.moveNext());
      expect$.Expect.equals('foo', dart.dsend(it.current, 'group', 0));
      expect$.Expect.equals('foo', dart.dsend(it2.current, 'group', 0));
      expect$.Expect.isTrue(it.moveNext());
      expect$.Expect.isTrue(it2.moveNext());
      expect$.Expect.equals('foo', dart.dsend(it.current, 'group', 0));
      expect$.Expect.equals('foo', dart.dsend(it2.current, 'group', 0));
      expect$.Expect.equals(false, it.moveNext());
      expect$.Expect.equals(false, it2.moveNext());
    }
    static testForEach() {
      let matches = core.RegExp.new("foo").allMatches("foo foo");
      let strbuf = new core.StringBuffer();
      matches[dartx.forEach](dart.fn(m => {
        strbuf.write(m.group(0));
      }, MatchTovoid()));
      expect$.Expect.equals("foofoo", strbuf.toString());
    }
    static testMap() {
      let matches = core.RegExp.new("foo?").allMatches("foo fo foo fo");
      let mapped = matches[dartx.map](core.String)(dart.fn(m => dart.str`${m.group(0)}bar`, MatchToString()));
      expect$.Expect.equals(4, mapped[dartx.length]);
      let strbuf = new core.StringBuffer();
      for (let s of mapped) {
        strbuf.write(s);
      }
      expect$.Expect.equals("foobarfobarfoobarfobar", strbuf.toString());
    }
    static testFilter() {
      let matches = core.RegExp.new("foo?").allMatches("foo fo foo fo");
      let filtered = matches[dartx.where](dart.fn(m => m.group(0) == 'foo', MatchTobool()));
      expect$.Expect.equals(2, filtered[dartx.length]);
      let strbuf = new core.StringBuffer();
      for (let m of filtered) {
        strbuf.write(m.group(0));
      }
      expect$.Expect.equals("foofoo", strbuf.toString());
    }
    static testEvery() {
      let matches = core.RegExp.new("foo?").allMatches("foo fo foo fo");
      expect$.Expect.equals(true, matches[dartx.every](dart.fn(m => m.group(0)[dartx.startsWith]("fo"), MatchTobool())));
      expect$.Expect.equals(false, matches[dartx.every](dart.fn(m => m.group(0)[dartx.startsWith]("foo"), MatchTobool())));
    }
    static testSome() {
      let matches = core.RegExp.new("foo?").allMatches("foo fo foo fo");
      expect$.Expect.equals(true, matches[dartx.any](dart.fn(m => m.group(0)[dartx.startsWith]("fo"), MatchTobool())));
      expect$.Expect.equals(true, matches[dartx.any](dart.fn(m => m.group(0)[dartx.startsWith]("foo"), MatchTobool())));
      expect$.Expect.equals(false, matches[dartx.any](dart.fn(m => m.group(0)[dartx.startsWith]("fooo"), MatchTobool())));
    }
    static testIsEmpty() {
      let matches = core.RegExp.new("foo?").allMatches("foo fo foo fo");
      expect$.Expect.equals(false, matches[dartx.isEmpty]);
      matches = core.RegExp.new("fooo").allMatches("foo fo foo fo");
      expect$.Expect.equals(true, matches[dartx.isEmpty]);
    }
    static testGetCount() {
      let matches = core.RegExp.new("foo?").allMatches("foo fo foo fo");
      expect$.Expect.equals(4, matches[dartx.length]);
      matches = core.RegExp.new("fooo").allMatches("foo fo foo fo");
      expect$.Expect.equals(0, matches[dartx.length]);
    }
    static testMain() {
      reg_exp_all_matches_test.RegExpAllMatchesTest.testIterator();
      reg_exp_all_matches_test.RegExpAllMatchesTest.testForEach();
      reg_exp_all_matches_test.RegExpAllMatchesTest.testMap();
      reg_exp_all_matches_test.RegExpAllMatchesTest.testFilter();
      reg_exp_all_matches_test.RegExpAllMatchesTest.testEvery();
      reg_exp_all_matches_test.RegExpAllMatchesTest.testSome();
      reg_exp_all_matches_test.RegExpAllMatchesTest.testIsEmpty();
      reg_exp_all_matches_test.RegExpAllMatchesTest.testGetCount();
    }
  };
  dart.setSignature(reg_exp_all_matches_test.RegExpAllMatchesTest, {
    statics: () => ({
      testIterator: dart.definiteFunctionType(dart.dynamic, []),
      testForEach: dart.definiteFunctionType(dart.dynamic, []),
      testMap: dart.definiteFunctionType(dart.dynamic, []),
      testFilter: dart.definiteFunctionType(dart.dynamic, []),
      testEvery: dart.definiteFunctionType(dart.dynamic, []),
      testSome: dart.definiteFunctionType(dart.dynamic, []),
      testIsEmpty: dart.definiteFunctionType(dart.dynamic, []),
      testGetCount: dart.definiteFunctionType(dart.dynamic, []),
      testMain: dart.definiteFunctionType(dart.dynamic, [])
    }),
    names: ['testIterator', 'testForEach', 'testMap', 'testFilter', 'testEvery', 'testSome', 'testIsEmpty', 'testGetCount', 'testMain']
  });
  reg_exp_all_matches_test.main = function() {
    reg_exp_all_matches_test.RegExpAllMatchesTest.testMain();
  };
  dart.fn(reg_exp_all_matches_test.main, VoidTodynamic());
  // Exports:
  exports.reg_exp_all_matches_test = reg_exp_all_matches_test;
});
