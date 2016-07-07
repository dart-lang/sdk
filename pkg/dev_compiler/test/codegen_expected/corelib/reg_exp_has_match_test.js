dart_library.library('corelib/reg_exp_has_match_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__reg_exp_has_match_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const reg_exp_has_match_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  reg_exp_has_match_test.RegExpHasMatchTest = class RegExpHasMatchTest extends core.Object {
    static testMain() {
      expect$.Expect.equals(false, core.RegExp.new("bar").hasMatch("foo"));
      expect$.Expect.equals(true, core.RegExp.new("bar|foo").hasMatch("foo"));
      expect$.Expect.equals(true, core.RegExp.new("o+").hasMatch("foo"));
    }
  };
  dart.setSignature(reg_exp_has_match_test.RegExpHasMatchTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  reg_exp_has_match_test.main = function() {
    reg_exp_has_match_test.RegExpHasMatchTest.testMain();
  };
  dart.fn(reg_exp_has_match_test.main, VoidTodynamic());
  // Exports:
  exports.reg_exp_has_match_test = reg_exp_has_match_test;
});
