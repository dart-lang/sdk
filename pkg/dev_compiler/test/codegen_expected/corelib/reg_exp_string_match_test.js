dart_library.library('corelib/reg_exp_string_match_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__reg_exp_string_match_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const reg_exp_string_match_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  reg_exp_string_match_test.RegExpStringMatchTest = class RegExpStringMatchTest extends core.Object {
    static testMain() {
      expect$.Expect.equals('cat', core.RegExp.new("(\\w+)").stringMatch("cat dog"));
      expect$.Expect.equals(null, core.RegExp.new("foo").stringMatch("bar"));
    }
  };
  dart.setSignature(reg_exp_string_match_test.RegExpStringMatchTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  reg_exp_string_match_test.main = function() {
    reg_exp_string_match_test.RegExpStringMatchTest.testMain();
  };
  dart.fn(reg_exp_string_match_test.main, VoidTodynamic());
  // Exports:
  exports.reg_exp_string_match_test = reg_exp_string_match_test;
});
